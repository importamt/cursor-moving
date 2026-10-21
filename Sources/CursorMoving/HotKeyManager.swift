import Carbon
import Foundation

/// Carbon RegisterEventHotKey 기반 전역 단축키 (별도 권한 불필요)
final class HotKeyManager {
    static let shared = HotKeyManager()

    private static let signature: OSType = 0x434D_5648 // "CMVH"

    private var handlers: [UInt32: () -> Void] = [:]
    private var hotKeyRefs: [EventHotKeyRef] = []

    private init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            guard status == noErr else { return status }
            HotKeyManager.shared.handle(id: hotKeyID.id)
            return noErr
        }, 1, &spec, nil, nil)
    }

    /// 다른 앱이 이미 같은 조합을 쓰고 있으면 false
    @discardableResult
    func register(id: UInt32, keyCode: Int, modifiers: Int, handler: @escaping () -> Void) -> Bool {
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            EventHotKeyID(signature: Self.signature, id: id),
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard status == noErr, let ref else { return false }
        hotKeyRefs.append(ref)
        handlers[id] = handler
        return true
    }

    private func handle(id: UInt32) {
        DispatchQueue.main.async { [handlers] in
            handlers[id]?()
        }
    }
}
