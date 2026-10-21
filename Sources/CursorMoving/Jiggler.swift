import AppKit
import CursorMovingCore

/// 주기적으로 커서를 움직인다.
@MainActor
final class Jiggler {
    private static let subtleStepDelay: TimeInterval = 0.05

    var interval: TimeInterval = 60 {
        didSet { if isRunning { start() } }
    }
    var mode: JiggleMode = .subtle
    var onlyWhenIdle = true
    /// true 를 반환하면 이번 주기를 건너뛴다 (녹화/재생 중 등)
    var shouldSkip: () -> Bool = { false }

    private var timer: Timer?

    var isRunning: Bool {
        timer != nil
    }

    func start() {
        timer?.invalidate()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard !shouldSkip() else { return }
        if onlyWhenIdle, let anyInput = CGEventType(rawValue: ~0) {
            let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
            guard JigglePlanner.shouldJiggle(idleSeconds: idle, interval: interval) else { return }
        }

        let current = MouseController.currentLocation
        var generator = SystemRandomNumberGenerator()
        let targets = JigglePlanner.targets(
            from: current,
            in: MouseController.displayBounds(containing: current),
            mode: mode,
            using: &generator
        )

        for (index, target) in targets.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.subtleStepDelay * Double(index)) {
                MouseController.post(.move, at: target)
            }
        }
    }
}
