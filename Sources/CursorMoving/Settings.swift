import Foundation
import CursorMovingCore

/// UserDefaults 에 저장되는 사용자 설정. 메뉴와 환경설정 창이 함께 구독한다.
@MainActor
final class Settings: ObservableObject {
    static let idleThresholdOptions: [TimeInterval] = [5, 10, 15, 30, 60, 300]

    private let defaults = UserDefaults.standard

    @Published var idleThreshold: TimeInterval {
        didSet { defaults.set(idleThreshold, forKey: "idleThreshold") }
    }

    @Published var shape: JiggleShape {
        didSet { defaults.set(shape.rawValue, forKey: "shape") }
    }

    @Published var language: Language {
        didSet { defaults.set(language.rawValue, forKey: "language") }
    }

    @Published var startMovingOnLaunch: Bool {
        didSet { defaults.set(startMovingOnLaunch, forKey: "startMovingOnLaunch") }
    }

    @Published var toggleHotKey: KeyCombo {
        didSet { defaults.set(try? JSONEncoder().encode(toggleHotKey), forKey: "toggleHotKey") }
    }

    var strings: Strings {
        Strings(language: language)
    }

    init() {
        let threshold = defaults.double(forKey: "idleThreshold")
        idleThreshold = Self.idleThresholdOptions.contains(threshold) ? threshold : 30
        shape = defaults.string(forKey: "shape").flatMap(JiggleShape.init(rawValue:)) ?? .circle
        language = defaults.string(forKey: "language").flatMap(Language.init(rawValue:)) ?? .defaultLanguage
        startMovingOnLaunch = defaults.bool(forKey: "startMovingOnLaunch")
        toggleHotKey = defaults.data(forKey: "toggleHotKey")
            .flatMap { try? JSONDecoder().decode(KeyCombo.self, from: $0) } ?? .defaultToggle
    }
}
