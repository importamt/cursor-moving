import Foundation
import CursorMovingCore

/// UserDefaults 에 저장되는 사용자 설정
struct Settings {
    static let intervalOptions: [TimeInterval] = [10, 30, 60, 120, 300]

    private let defaults = UserDefaults.standard

    var interval: TimeInterval {
        get {
            let value = defaults.double(forKey: "interval")
            return value > 0 ? value : 60
        }
        nonmutating set { defaults.set(newValue, forKey: "interval") }
    }

    var mode: JiggleMode {
        get { defaults.string(forKey: "mode").flatMap(JiggleMode.init(rawValue:)) ?? .subtle }
        nonmutating set { defaults.set(newValue.rawValue, forKey: "mode") }
    }

    var onlyWhenIdle: Bool {
        get { defaults.object(forKey: "onlyWhenIdle") as? Bool ?? true }
        nonmutating set { defaults.set(newValue, forKey: "onlyWhenIdle") }
    }

    var recordMoves: Bool {
        get { defaults.bool(forKey: "recordMoves") }
        nonmutating set { defaults.set(newValue, forKey: "recordMoves") }
    }

    var loopPlayback: Bool {
        get { defaults.bool(forKey: "loopPlayback") }
        nonmutating set { defaults.set(newValue, forKey: "loopPlayback") }
    }

    static func intervalTitle(_ seconds: TimeInterval) -> String {
        seconds < 60 ? "\(Int(seconds))초" : "\(Int(seconds / 60))분"
    }
}
