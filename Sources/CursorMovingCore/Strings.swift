import Foundation

public enum Language: String, CaseIterable, Codable, Sendable {
    case english
    case korean

    public static let defaultLanguage: Language = .english

    /// 언어 이름은 현재 언어와 상관없이 각 언어로 표기한다
    public var displayName: String {
        switch self {
        case .english: return "English"
        case .korean: return "한국어"
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

    // MARK: - 환경설정

    public var settingsMenu: String { pick("설정…", "Settings…") }
    public var settingsTitle: String { pick("CursorMoving 설정", "CursorMoving Settings") }
    public var general: String { pick("일반", "General") }
    public var launchAtLogin: String { pick("로그인 시 자동 실행", "Launch at login") }
    public var startMovingOnLaunch: String { pick("앱 시작 시 커서 이동 켜기", "Start moving when app launches") }
    public var loginItemNeedsApproval: String {
        pick(
            "시스템 설정 → 일반 → 로그인 항목에서 CursorMoving 을 허용해 주세요.",
            "Allow CursorMoving in System Settings → General → Login Items."
        )
    }

    public func loginItemFailed(_ reason: String) -> String {
        pick("로그인 항목 변경 실패: \(reason)", "Couldn't change login item: \(reason)")
    }

    public var languageLabel: String { pick("언어", "Language") }
    public var shortcut: String { pick("단축키", "Shortcut") }
    public var toggleShortcut: String { pick("커서 이동 켜기/끄기", "Toggle cursor moving") }
    public var change: String { pick("변경…", "Change…") }
    public var resetToDefault: String { pick("기본값", "Default") }

    // MARK: - 단축키 입력 창

    public var recorderTitle: String { pick("새 단축키를 누르세요", "Press a new shortcut") }
    public var recorderHint: String {
        pick("⌘, ⌥, ⌃ 중 하나 이상과 함께 누르세요. Esc 로 취소합니다.", "Include ⌘, ⌥ or ⌃. Press Esc to cancel.")
    }
    public var recorderWaiting: String { pick("입력 대기 중…", "Waiting for keys…") }
    public var recorderNeedsModifier: String { pick("⌘, ⌥, ⌃ 중 하나가 필요합니다", "Add ⌘, ⌥ or ⌃") }
    public var recorderConflict: String { pick("다른 앱에서 사용 중인 단축키입니다", "Already used by another app") }
    public var cancel: String { pick("취소", "Cancel") }
    public var confirm: String { pick("확인", "OK") }
}
