import XCTest
@testable import CursorMovingCore

final class KeyComboTests: XCTestCase {
    func testDefaultIsControlOptionCommandM() {
        XCTAssertEqual(KeyCombo.defaultToggle.displayString, "⌃⌥⌘M")
        XCTAssertEqual(KeyCombo.defaultToggle.keyCode, 46)
    }

    func testDisplayStringUsesStandardModifierOrder() {
        let combo = KeyCombo(keyCode: 31, modifiers: [.command, .shift, .option, .control], keyName: "O")

        XCTAssertEqual(combo.displayString, "⌃⌥⇧⌘O")
    }

    func testRequiresCommandOptionOrControl() {
        XCTAssertFalse(KeyCombo(keyCode: 31, modifiers: [], keyName: "O").isValid)
        XCTAssertFalse(KeyCombo(keyCode: 31, modifiers: [.shift], keyName: "O").isValid)
        XCTAssertTrue(KeyCombo(keyCode: 31, modifiers: [.command, .option], keyName: "O").isValid)
        XCTAssertTrue(KeyCombo(keyCode: 31, modifiers: [.control, .shift], keyName: "O").isValid)
    }

    func testKeyNameForSpecialKeys() {
        XCTAssertEqual(KeyCombo.keyName(keyCode: 49, characters: " "), "Space")
        XCTAssertEqual(KeyCombo.keyName(keyCode: 96, characters: "\u{F708}"), "F5")
        XCTAssertEqual(KeyCombo.keyName(keyCode: 126, characters: "\u{F700}"), "↑")
        XCTAssertEqual(KeyCombo.keyName(keyCode: 36, characters: "\r"), "↩")
    }

    func testKeyNameUppercasesCharacters() {
        XCTAssertEqual(KeyCombo.keyName(keyCode: 31, characters: "o"), "O")
        XCTAssertEqual(KeyCombo.keyName(keyCode: 18, characters: "1"), "1")
    }

    func testKeyNameFallsBackToKeyCodeWhenNoCharacters() {
        XCTAssertEqual(KeyCombo.keyName(keyCode: 999, characters: nil), "Key 999")
        XCTAssertEqual(KeyCombo.keyName(keyCode: 999, characters: ""), "Key 999")
    }

    func testRoundTripsThroughJSON() throws {
        let combo = KeyCombo(keyCode: 31, modifiers: [.command, .option], keyName: "O")

        let decoded = try JSONDecoder().decode(KeyCombo.self, from: JSONEncoder().encode(combo))

        XCTAssertEqual(decoded, combo)
    }
}
