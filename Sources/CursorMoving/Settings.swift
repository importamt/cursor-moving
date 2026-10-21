import Foundation
import CursorMovingCore

/// UserDefaults 에 저장되는 사용자 설정
struct Settings {
    static let idleThresholdOptions: [TimeInterval] = [5, 10, 15, 30, 60, 300]

    private let defaults = UserDefaults.standard

    var idleThreshold: TimeInterval {
        get {
            let value = defaults.double(forKey: "idleThreshold")
            return Self.idleThresholdOptions.contains(value) ? value : 30
        }
        nonmutating set { defaults.set(newValue, forKey: "idleThreshold") }
    }

    var shape: JiggleShape {
        get { defaults.string(forKey: "shape").flatMap(JiggleShape.init(rawValue:)) ?? .circle }
        nonmutating set { defaults.set(newValue.rawValue, forKey: "shape") }
    }

    static func durationTitle(_ seconds: TimeInterval) -> String {
        seconds < 60 ? "\(Int(seconds))초" : "\(Int(seconds / 60))분"
    }
}
