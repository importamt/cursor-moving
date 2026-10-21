import AppKit
import Carbon
import CursorMovingCore

/// Carbon RegisterEventHotKey 기반 전역 단축키 (별도 권한 불필요)
final class HotKeyManager {
    static let shared = HotKeyManager()

    private static let signature: OSType = 0x434D_5648 // "CMVH"

    private var handlers: [UInt32: () -> Void] = [:]
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]

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

    /// 같은 id 로 등록된 단축키는 교체한다. 다른 앱이 이미 같은 조합을 쓰고 있으면 false
    @discardableResult
    func register(id: UInt32, combo: KeyCombo, handler: @escaping () -> Void) -> Bool {
        unregister(id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            combo.keyCode,
            combo.carbonModifiers,
            EventHotKeyID(signature: Self.signature, id: id),
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard status == noErr, let ref else { return false }
        hotKeyRefs[id] = ref
        handlers[id] = handler
        return true
    }

    func unregister(id: UInt32) {
        if let ref = hotKeyRefs.removeValue(forKey: id) {
            UnregisterEventHotKey(ref)
        }
        handlers[id] = nil
    }

    private func handle(id: UInt32) {
        DispatchQueue.main.async { [handlers] in
            handlers[id]?()
        }
    }
}

extension KeyCombo {
    init(event: NSEvent) {
        let keyCode = UInt32(event.keyCode)
        self.init(
            keyCode: keyCode,
            modifiers: KeyModifiers(event.modifierFlags),
            keyName: Self.keyName(keyCode: keyCode, characters: event.characters(byApplyingModifiers: []))
        )
    }

    var carbonModifiers: UInt32 {
        UInt32(modifiers.mappings.reduce(0) { $0 | $1.carbon })
    }

    var menuModifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(modifiers.mappings.map(\.flag))
    }

    /// 메뉴에 표시할 키. 한 글자 키만 표시하고 특수키는 생략한다.
    var menuKeyEquivalent: String {
        keyName.count == 1 ? keyName.lowercased() : ""
    }
}

extension KeyModifiers {
    private static let all: [(modifier: KeyModifiers, flag: NSEvent.ModifierFlags, carbon: Int)] = [
        (.control, .control, controlKey),
        (.option, .option, optionKey),
        (.shift, .shift, shiftKey),
        (.command, .command, cmdKey),
    ]

    init(_ flags: NSEvent.ModifierFlags) {
        self.init(Self.all.filter { flags.contains($0.flag) }.map(\.modifier))
    }

    fileprivate var mappings: [(modifier: KeyModifiers, flag: NSEvent.ModifierFlags, carbon: Int)] {
        Self.all.filter { contains($0.modifier) }
    }
}
