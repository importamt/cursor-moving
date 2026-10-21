import AppKit
import CursorMovingCore

/// 사용자 입력이 일정 시간 없으면 커서로 도형을 부드럽게 그린다.
@MainActor
final class Jiggler {
    private static let pollInterval: TimeInterval = 1
    private static let drawDuration: TimeInterval = 2
    private static let framesPerSecond: Double = 60
    /// 그리는 도중 커서가 예상 위치에서 이만큼 벗어나면 사용자가 마우스를 잡은 것으로 본다
    private static let userTakeoverDistance: CGFloat = 5

    var idleThreshold: TimeInterval = 30
    var shape: JiggleShape = .circle

    private var timer: Timer?
    private var drawTask: Task<Void, Never>?
    private var lastDrawEnd: Date = .distantPast

    var isRunning: Bool {
        timer != nil
    }

    func start() {
        timer?.invalidate()
        let timer = Timer(timeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        drawTask?.cancel()
        drawTask = nil
    }

    private func tick() {
        guard drawTask == nil, let anyInput = CGEventType(rawValue: ~0) else { return }
        let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
        guard JigglePlanner.shouldJiggle(
            idleSeconds: idle,
            secondsSinceLastJiggle: Date().timeIntervalSince(lastDrawEnd),
            threshold: idleThreshold
        ) else { return }
        draw()
    }

    private func draw() {
        let current = MouseController.currentLocation
        let path = JigglePlanner.path(
            shape: shape,
            from: current,
            in: MouseController.displayBounds(containing: current),
            steps: Int(Self.drawDuration * Self.framesPerSecond)
        )
        let frameNanoseconds = UInt64(1_000_000_000 / Self.framesPerSecond)
        let startedAt = Date()

        drawTask = Task { @MainActor [weak self] in
            var expected = current
            for point in path {
                try? await Task.sleep(nanoseconds: frameNanoseconds)
                guard self != nil, !Task.isCancelled, !Self.userTookOver(expected: expected, since: startedAt) else { break }
                MouseController.move(to: point)
                expected = point
            }

            // 취소된 경우 stop() 호출 측에서 상태를 정리한다
            guard !Task.isCancelled else { return }
            self?.lastDrawEnd = Date()
            self?.drawTask = nil
        }
    }

    private static func userTookOver(expected: CGPoint, since startedAt: Date) -> Bool {
        let location = MouseController.currentLocation
        if hypot(location.x - expected.x, location.y - expected.y) > userTakeoverDistance {
            return true
        }
        let keyIdle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        return keyIdle < Date().timeIntervalSince(startedAt)
    }
}
