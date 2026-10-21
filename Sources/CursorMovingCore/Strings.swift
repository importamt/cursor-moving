import Foundation

public enum Language: String, Sendable {
    case korean
    case english
}

public enum LanguagePreference: String, CaseIterable, Codable, Sendable {
    case system
    case korean
    case english

    /// 시스템 설정을 따를 때는 첫 번째 선호 언어가 한국어면 한국어, 그 외에는 영어
    public func resolved(preferredLanguages: [String] = Locale.preferredLanguages) -> Language {
        switch self {
        case .korean: return .korean
        case .english: return .english
        case .system: return preferredLanguages.first?.hasPrefix("ko") == true ? .korean : .english
        }
    }
}

/// 화면에 표시되는 문구
public struct Strings: Sendable {
    public let language: Language

    public init(language: Language) {
        self.language = language
    }

    private func pick(_ korean: String, _ english: String) -> String {
        language == .korean ? korean : english
    }

    public func duration(_ seconds: TimeInterval) -> String {
        if seconds < 60 {
            return pick("\(Int(seconds))초", "\(Int(seconds)) sec")
        }
        return pick("\(Int(seconds / 60))분", "\(Int(seconds / 60)) min")
    }

    public func shape(_ shape: JiggleShape) -> String {
        switch shape {
        case .zigzag: return pick("지그재그", "Zigzag")
        case .circle: return pick("동그라미", "Circle")
        case .square: return pick("네모", "Square")
        case .star: return pick("별", "Star")
        }
    }

    /// 언어 이름은 현재 언어와 상관없이 각 언어로 표기한다
    public func languagePreference(_ preference: LanguagePreference) -> String {
        switch preference {
        case .system: return pick("시스템 설정 따름", "System Default")
        case .korean: return "한국어"
        case .english: return "English"
        }
    }

    public func statusOn(threshold: TimeInterval, shape: JiggleShape) -> String {
        pick(
            "커서 이동 켜짐 · \(duration(threshold)) 유휴 시 \(self.shape(shape))",
            "On · \(self.shape(shape)) after \(duration(threshold)) idle"
        )
    }

    public var statusOff: String { pick("커서 이동 꺼짐", "Off") }
    public var tooltipOn: String { pick("커서 이동 켜짐", "Cursor moving on") }
    public var tooltipOff: String { pick("커서 이동 꺼짐", "Cursor moving off") }
    public var turnOn: String { pick("커서 이동 켜기", "Start Moving") }
    public var turnOff: String { pick("커서 이동 끄기", "Stop Moving") }
    public var quit: String { pick("종료", "Quit") }
    public var grantAccessibility: String { pick("⚠️ 손쉬운 사용 권한 허용하기…", "⚠️ Grant Accessibility Access…") }

    public func idleMenu(_ threshold: TimeInterval) -> String {
        pick("유휴 감지: \(duration(threshold))", "Idle Time: \(duration(threshold))")
    }

    public func shapeMenu(_ shape: JiggleShape) -> String {
        pick("모양: \(self.shape(shape))", "Shape: \(self.shape(shape))")
    }

    public func languageMenu(_ preference: LanguagePreference) -> String {
        pick("언어: \(languagePreference(preference))", "Language: \(languagePreference(preference))")
    }

    public func hotKeyConflict(_ label: String) -> String {
        pick("⚠️ 단축키 충돌: \(label)", "⚠️ Shortcut conflict: \(label)")
    }

    public var accessibilityAlertTitle: String {
        pick("손쉬운 사용 권한이 필요합니다", "Accessibility access required")
    }

    public var accessibilityAlertMessage: String {
        pick(
            "시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용에서 CursorMoving 을 허용해 주세요.",
            "Allow CursorMoving in System Settings → Privacy & Security → Accessibility."
        )
    }

    public var openSettings: String { pick("설정 열기", "Open Settings") }
    public var close: String { pick("닫기", "Close") }
}
