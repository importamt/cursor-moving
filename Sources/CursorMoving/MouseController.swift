import AppKit

/// CGEvent 로 마우스 이동을 시스템에 주입한다. (손쉬운 사용 권한 필요)
enum MouseController {
    private static let source = CGEventSource(stateID: .hidSystemState)

    static var currentLocation: CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }

    /// 지정한 좌표가 속한 디스플레이의 영역(Quartz 좌표계)
    static func displayBounds(containing point: CGPoint) -> CGRect {
        var displayID: CGDirectDisplayID = 0
        var count: UInt32 = 0
        guard CGGetDisplaysWithPoint(point, 1, &displayID, &count) == .success, count > 0 else {
            return CGDisplayBounds(CGMainDisplayID())
        }
        return CGDisplayBounds(displayID)
    }

    static func move(to point: CGPoint) {
        CGEvent(
            mouseEventSource: source,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
    }
}
