import AppKit
import CursorMovingCore

/// CGEvent 로 마우스 이동/클릭을 시스템에 주입한다. (손쉬운 사용 권한 필요)
enum MouseController {
    /// 앱이 만든 이벤트 표식. 녹화기가 자기 이벤트를 다시 기록하지 않도록 거른다.
    static let syntheticMarker: Int64 = 0x434D_5643 // "CMVC"

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

    static func perform(_ event: RecordedEvent) {
        if event.action.isButtonDown {
            post(.move, at: event.point)
        }
        post(event.action, at: event.point, clickCount: event.clickCount)
    }

    static func post(_ action: MouseAction, at point: CGPoint, clickCount: Int = 1) {
        let (type, button) = action.eventSpec
        guard let event = CGEvent(
            mouseEventSource: source,
            mouseType: type,
            mouseCursorPosition: point,
            mouseButton: button
        ) else { return }

        event.setIntegerValueField(.eventSourceUserData, value: syntheticMarker)
        if !action.isMovement {
            event.setIntegerValueField(.mouseEventClickState, value: Int64(max(1, clickCount)))
        }
        event.post(tap: .cghidEventTap)
    }
}

extension MouseAction {
    var eventSpec: (CGEventType, CGMouseButton) {
        switch self {
        case .move: return (.mouseMoved, .left)
        case .leftDown: return (.leftMouseDown, .left)
        case .leftUp: return (.leftMouseUp, .left)
        case .rightDown: return (.rightMouseDown, .right)
        case .rightUp: return (.rightMouseUp, .right)
        case .leftDrag: return (.leftMouseDragged, .left)
        case .rightDrag: return (.rightMouseDragged, .right)
        }
    }

    init?(eventType: CGEventType) {
        switch eventType {
        case .mouseMoved: self = .move
        case .leftMouseDown: self = .leftDown
        case .leftMouseUp: self = .leftUp
        case .rightMouseDown: self = .rightDown
        case .rightMouseUp: self = .rightUp
        case .leftMouseDragged: self = .leftDrag
        case .rightMouseDragged: self = .rightDrag
        default: return nil
        }
    }
}
