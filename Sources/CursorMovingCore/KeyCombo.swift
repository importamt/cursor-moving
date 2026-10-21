import Foundation

public struct KeyModifiers: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let control = KeyModifiers(rawValue: 1 << 0)
    public static let option = KeyModifiers(rawValue: 1 << 1)
    public static let shift = KeyModifiers(rawValue: 1 << 2)
    public static let command = KeyModifiers(rawValue: 1 << 3)

    /// macOS 표준 순서(⌃⌥⇧⌘)로 표기
    public var displayString: String {
        let symbols: [(KeyModifiers, String)] = [(.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
        return symbols.filter { contains($0.0) }.map(\.1).joined()
    }
}

/// 전역 단축키 조합. `keyCode` 는 하드웨어 가상 키 코드(kVK_*), `keyName` 은 표시용 이름.
public struct KeyCombo: Codable, Equatable, Sendable {
    public var keyCode: UInt32
    public var modifiers: KeyModifiers
    public var keyName: String

    public init(keyCode: UInt32, modifiers: KeyModifiers, keyName: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.keyName = keyName
    }

    /// ⌃⌥⌘M (kVK_ANSI_M)
    public static let defaultToggle = KeyCombo(keyCode: 46, modifiers: [.control, .option, .command], keyName: "M")

    public var displayString: String {
        modifiers.displayString + keyName
    }

    /// 일반 타이핑과 겹치지 않도록 ⌘, ⌥, ⌃ 중 하나는 있어야 한다
    public var isValid: Bool {
        !modifiers.isDisjoint(with: [.control, .option, .command])
    }

    private static let specialKeyNames: [UInt32: String] = [
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋", 117: "⌦",
        115: "↖", 119: "↘", 116: "⇞", 121: "⇟",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
    ]

    /// 수식키를 뺀 입력 문자로 표시용 키 이름을 만든다
    public static func keyName(keyCode: UInt32, characters: String?) -> String {
        if let special = specialKeyNames[keyCode] {
            return special
        }
        guard let characters, !characters.isEmpty else { return "Key \(keyCode)" }
        return characters.uppercased()
    }
}
