import CoreGraphics
import Foundation

public enum JiggleShape: String, CaseIterable, Codable, Sendable {
    case zigzag
    case circle
    case square
    case star

    public var title: String {
        switch self {
        case .zigzag: return "지그재그"
        case .circle: return "동그라미"
        case .square: return "네모"
        case .star: return "별"
        }
    }
}

public enum JigglePlanner {
    /// 도형의 가로/세로 크기 (pt)
    public static let shapeSize: CGFloat = 60
    /// 원은 다른 도형보다 크게 그린다 (지름, pt)
    public static let circleSize: CGFloat = 150

    /// 현재 위치에서 출발해 도형을 그리고 제자리로 돌아오는 `steps` 개의 좌표를 반환한다.
    /// 좌표계는 Quartz(좌상단 원점) 기준이며, 화면 밖으로 나가면 반대 방향으로 뒤집거나 가장자리에 맞춘다.
    public static func path(shape: JiggleShape, from current: CGPoint, in bounds: CGRect, steps: Int) -> [CGPoint] {
        guard !bounds.isNull, steps > 0 else { return [current] }

        let sampled = sample(vertices(of: shape), steps: steps)
        return place(sampled, at: current, in: bounds)
    }

    /// 사용자 입력이 `threshold` 이상 없고, 직전 그리기 후에도 그만큼 지났을 때만 그린다.
    /// (합성 이벤트가 유휴 시간을 초기화하지 않는 환경에서도 연달아 그리지 않도록)
    public static func shouldJiggle(
        idleSeconds: TimeInterval,
        secondsSinceLastJiggle: TimeInterval,
        threshold: TimeInterval
    ) -> Bool {
        idleSeconds >= threshold && secondsSinceLastJiggle >= threshold
    }

    // MARK: - 도형

    /// 원점에서 시작해 원점으로 끝나는 꼭짓점 목록
    private static func vertices(of shape: JiggleShape) -> [CGPoint] {
        let size = shapeSize
        let radius = size / 2

        var points: [CGPoint]
        switch shape {
        case .zigzag:
            let teeth = 6
            let outward = (0...teeth).map { index -> CGPoint in
                let isEdge = index == 0 || index == teeth
                let y = isEdge ? 0 : (index.isMultiple(of: 2) ? radius / 2 : -radius / 2)
                return CGPoint(x: size * CGFloat(index) / CGFloat(teeth), y: y)
            }
            points = outward + outward.reversed().dropFirst()
        case .circle:
            let segments = 120
            let circleRadius = circleSize / 2
            points = (0..<segments).map { index in
                let angle = CGFloat.pi + 2 * .pi * CGFloat(index) / CGFloat(segments)
                return CGPoint(x: circleRadius + circleRadius * cos(angle), y: circleRadius * sin(angle))
            }
        case .square:
            points = [
                .zero,
                CGPoint(x: size, y: 0),
                CGPoint(x: size, y: size),
                CGPoint(x: 0, y: size),
            ]
        case .star:
            // 꼭짓점을 하나씩 건너뛰며 연결하는 한붓그리기 별. 맨 위 꼭짓점에서 출발한다.
            points = (0..<5).map { index in
                let angle = -CGFloat.pi / 2 + 4 * .pi * CGFloat(index) / 5
                return CGPoint(x: radius * cos(angle), y: radius + radius * sin(angle))
            }
        }

        points[0] = .zero
        points.append(.zero)
        return points
    }

    /// 경로 길이를 기준으로 ease-in-out 속도로 `steps` 개의 좌표를 고른다. 마지막 좌표는 항상 끝점이다.
    private static func sample(_ vertices: [CGPoint], steps: Int) -> [CGPoint] {
        var cumulative: [CGFloat] = [0]
        for index in 1..<vertices.count {
            cumulative.append(cumulative[index - 1] + distance(vertices[index - 1], vertices[index]))
        }
        let total = cumulative[cumulative.count - 1]

        var segment = 1
        return (1...steps).map { step in
            let t = CGFloat(step) / CGFloat(steps)
            let target = total * t * t * (3 - 2 * t)
            while segment < vertices.count - 1, cumulative[segment] < target {
                segment += 1
            }
            let start = cumulative[segment - 1]
            let length = cumulative[segment] - start
            let ratio = length > 0 ? min(1, (target - start) / length) : 1
            let from = vertices[segment - 1]
            let to = vertices[segment]
            return CGPoint(x: from.x + (to.x - from.x) * ratio, y: from.y + (to.y - from.y) * ratio)
        }
    }

    /// 상대 좌표를 현재 위치로 옮긴다. 화면을 덜 벗어나는 방향으로 축별 반전 후, 남는 부분은 가장자리에 맞춘다.
    private static func place(_ offsets: [CGPoint], at current: CGPoint, in bounds: CGRect) -> [CGPoint] {
        let flipX = shouldFlip(offsets.map(\.x), origin: current.x, min: bounds.minX, max: bounds.maxX - 1)
        let flipY = shouldFlip(offsets.map(\.y), origin: current.y, min: bounds.minY, max: bounds.maxY - 1)

        return offsets.map { offset in
            CGPoint(
                x: clamp(current.x + (flipX ? -offset.x : offset.x), bounds.minX, bounds.maxX - 1),
                y: clamp(current.y + (flipY ? -offset.y : offset.y), bounds.minY, bounds.maxY - 1)
            )
        }
    }

    private static func shouldFlip(_ values: [CGFloat], origin: CGFloat, min lower: CGFloat, max upper: CGFloat) -> Bool {
        let low = values.min() ?? 0
        let high = values.max() ?? 0
        func overflow(_ low: CGFloat, _ high: CGFloat) -> CGFloat {
            max(0, origin + high - upper) + max(0, lower - (origin + low))
        }
        return overflow(-high, -low) < overflow(low, high)
    }

    private static func clamp(_ value: CGFloat, _ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        min(max(value, lower), max(lower, upper))
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(b.x - a.x, b.y - a.y)
    }
}
