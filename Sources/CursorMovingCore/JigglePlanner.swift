import CoreGraphics
import Foundation

public enum JiggleMode: String, CaseIterable, Codable, Sendable {
    /// 1px 움직였다가 원래 자리로 복귀
    case subtle
    /// 현재 화면 안의 임의 위치로 이동
    case random

    public var title: String {
        switch self {
        case .subtle: return "미세 이동 (1px 후 복귀)"
        case .random: return "랜덤 위치로 이동"
        }
    }
}

public enum JigglePlanner {
    public static let subtleOffset: CGFloat = 1
    /// 랜덤 이동 시 화면 가장자리(핫코너, Dock, 메뉴바)를 피하기 위한 여백
    public static let randomInset: CGFloat = 20
    /// 직전 흔들기 이벤트가 유휴 시간을 초기화하더라도 다음 주기를 막지 않도록 두는 오차
    public static let idleTolerance: TimeInterval = 1

    /// 커서가 순서대로 이동할 좌표 목록을 반환한다. 좌표계는 Quartz(좌상단 원점) 기준.
    public static func targets<G: RandomNumberGenerator>(
        from current: CGPoint,
        in bounds: CGRect,
        mode: JiggleMode,
        using generator: inout G
    ) -> [CGPoint] {
        guard !bounds.isNull else { return [current] }

        switch mode {
        case .subtle:
            let canMoveRight = current.x + subtleOffset <= bounds.maxX - 1
            let dx = canMoveRight ? subtleOffset : -subtleOffset
            return [CGPoint(x: current.x + dx, y: current.y), current]
        case .random:
            let inset = bounds.insetBy(dx: randomInset, dy: randomInset)
            let area = inset.isEmpty ? bounds : inset
            let x = CGFloat.random(in: area.minX...max(area.minX, area.maxX - 1), using: &generator)
            let y = CGFloat.random(in: area.minY...max(area.minY, area.maxY - 1), using: &generator)
            return [CGPoint(x: x.rounded(), y: y.rounded())]
        }
    }

    public static func shouldJiggle(idleSeconds: TimeInterval, interval: TimeInterval) -> Bool {
        idleSeconds >= interval - idleTolerance
    }
}
