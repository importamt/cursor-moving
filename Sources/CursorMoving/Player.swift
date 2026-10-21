import Foundation
import CursorMovingCore

/// 녹화된 이벤트를 원래 타이밍대로 재생한다.
@MainActor
final class Player {
    /// 반복 재생 시 회차 사이 간격 (나노초)
    private static let loopGap: UInt64 = 300_000_000

    private var task: Task<Void, Never>?

    var isPlaying: Bool {
        task != nil
    }

    func play(_ recording: Recording, loop: Bool, onFinish: @escaping @MainActor () -> Void) {
        stop()
        guard !recording.events.isEmpty else {
            onFinish()
            return
        }

        task = Task { @MainActor [weak self] in
            repeat {
                for event in recording.events {
                    if event.delay > 0 {
                        try? await Task.sleep(nanoseconds: UInt64(event.delay * 1_000_000_000))
                    }
                    if Task.isCancelled { break }
                    MouseController.perform(event)
                }
                if loop, !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: Self.loopGap)
                }
            } while loop && !Task.isCancelled

            // 취소된 경우 stop() 호출 측에서 상태를 갱신한다
            guard !Task.isCancelled else { return }
            self?.task = nil
            onFinish()
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
