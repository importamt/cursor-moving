import XCTest
@testable import CursorMovingCore

final class StringsTests: XCTestCase {
    private let korean = Strings(language: .korean)
    private let english = Strings(language: .english)

    // MARK: - 언어 결정

    func testSystemPreferenceUsesKoreanWhenFirstPreferredLanguageIsKorean() {
        XCTAssertEqual(LanguagePreference.system.resolved(preferredLanguages: ["ko-KR", "en-US"]), .korean)
    }

    func testSystemPreferenceFallsBackToEnglishForOtherLanguages() {
        XCTAssertEqual(LanguagePreference.system.resolved(preferredLanguages: ["ja-JP", "ko-KR"]), .english)
    }

    func testSystemPreferenceFallsBackToEnglishWhenNoPreferredLanguage() {
        XCTAssertEqual(LanguagePreference.system.resolved(preferredLanguages: []), .english)
    }

    func testExplicitPreferenceIgnoresSystemLanguage() {
        XCTAssertEqual(LanguagePreference.english.resolved(preferredLanguages: ["ko-KR"]), .english)
        XCTAssertEqual(LanguagePreference.korean.resolved(preferredLanguages: ["en-US"]), .korean)
    }

    // MARK: - 문구

    func testDurationTitle() {
        XCTAssertEqual(korean.duration(5), "5초")
        XCTAssertEqual(korean.duration(300), "5분")
        XCTAssertEqual(english.duration(5), "5 sec")
        XCTAssertEqual(english.duration(60), "1 min")
    }

    func testShapeTitles() {
        XCTAssertEqual(JiggleShape.allCases.map(korean.shape), ["지그재그", "동그라미", "네모", "별"])
        XCTAssertEqual(JiggleShape.allCases.map(english.shape), ["Zigzag", "Circle", "Square", "Star"])
    }

    func testStatusWhenRunningIncludesThresholdAndShape() {
        XCTAssertEqual(korean.statusOn(threshold: 30, shape: .circle), "커서 이동 켜짐 · 30초 유휴 시 동그라미")
        XCTAssertEqual(english.statusOn(threshold: 30, shape: .circle), "On · Circle after 30 sec idle")
    }

    func testLanguageNamesAreAlwaysWrittenInTheirOwnLanguage() {
        XCTAssertEqual(english.languagePreference(.korean), "한국어")
        XCTAssertEqual(korean.languagePreference(.english), "English")
        XCTAssertEqual(korean.languagePreference(.system), "시스템 설정 따름")
        XCTAssertEqual(english.languagePreference(.system), "System Default")
    }
}
