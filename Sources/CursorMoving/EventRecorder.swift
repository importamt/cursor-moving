import AppKit
import CursorMovingCore

/// CGEventTap(listenOnly)으로 사용자의 마우스 이벤트를 수신한다. (입력 모니터링 권한 필요)
final class EventRecorder {
    var onEvent: ((MouseAction, CGPoint, Int, TimeInterval) -> Void)?

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private static let eventTypes: [CGEventType] = [
        .mouseMoved,
        .leftMouseDown, .leftMouseUp, .leftMouseDragged,
        .rightMouseDown, .rightMouseUp, .rightMouseDragged,
    ]

    /// 권한이 없으면 false
    func start() -> Bool {
        guard tap == nil else { return true }

        let mask = Self.eventTypes.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        // 메뉴 트래킹 중에도 이벤트를 받도록 commonModes 에 등록
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        runLoopSource = source
        return true
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        tap = nil
        runLoopSource = nil
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        }
        guard event.getIntegerValueField(.eventSourceUserData) != MouseController.syntheticMarker,
              let action = MouseAction(eventType: type)
        else { return }

        onEvent?(
            action,
            event.location,
            Int(event.getIntegerValueField(.mouseEventClickState)),
            ProcessInfo.processInfo.systemUptime
        )
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if let userInfo {
        Unmanaged<EventRecorder>.fromOpaque(userInfo).takeUnretainedValue().handle(type: type, event: event)
    }
    return Unmanaged.passUnretained(event)
}
