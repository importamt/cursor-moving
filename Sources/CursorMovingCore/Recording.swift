import CoreGraphics
import Foundation

public enum MouseAction: String, Codable, Sendable {
    case move
    case leftDown
    case leftUp
    case rightDown
    case rightUp
    case leftDrag
    case rightDrag

    public var isMovement: Bool {
        self == .move || self == .leftDrag || self == .rightDrag
    }

    public var isButtonDown: Bool {
        self == .leftDown || self == .rightDown
    }
}

public struct RecordedEvent: Codable, Equatable, Sendable {
    public var action: MouseAction
    public var x: Double
    public var y: Double
    /// 직전 이벤트로부터의 대기 시간(초)
    public var delay: TimeInterval
    /// 더블클릭 인식을 위한 클릭 횟수 (mouseEventClickState)
    public var clickCount: Int

    public var point: CGPoint {
        CGPoint(x: x, y: y)
    }
}

public struct Recording: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var createdAt: Date
    public var events: [RecordedEvent]

    public var duration: TimeInterval {
        events.reduce(0) { $0 + $1.delay }
    }

    public var clickCount: Int {
        events.filter(\.action.isButtonDown).count
    }
}

public struct RecordingBuilder {
    public static let minimumMoveInterval: TimeInterval = 1.0 / 60

    public let includesMoves: Bool
    public private(set) var events: [RecordedEvent] = []
    private var lastTimestamp: TimeInterval?
    private var lastMovementTimestamp: TimeInterval?
    private var menuMark: Int?

    public init(includesMoves: Bool) {
        self.includesMoves = includesMoves
    }

    public mutating func append(
        _ action: MouseAction,
        at point: CGPoint,
        clickCount: Int = 1,
        timestamp: TimeInterval
    ) {
        if action.isMovement {
            guard includesMoves else { return }
            if let last = lastMovementTimestamp, timestamp - last < Self.minimumMoveInterval { return }
            lastMovementTimestamp = timestamp
        }

        let delay = lastTimestamp.map { max(0, timestamp - $0) } ?? 0
        lastTimestamp = timestamp
        events.append(RecordedEvent(
            action: action,
            x: Double(point.x),
            y: Double(point.y),
            delay: delay,
            clickCount: max(1, clickCount)
        ))
    }

    /// 메뉴바 메뉴가 열린 시점을 기록한다. 메뉴에서 녹화를 중지하면 이후 이벤트(메뉴 조작)는 버린다.
    public mutating func markMenuOpened() {
        menuMark = events.count
    }

    public mutating func clearMenuMark() {
        menuMark = nil
    }

    public func build(name: String, createdAt: Date = Date(), id: UUID = UUID()) -> Recording {
        var kept = events
        if let menuMark {
            kept = Array(kept.prefix(menuMark))
            // 메뉴를 연 클릭의 down 이벤트가 마크 전에 들어온 경우, 짝 없는 down 을 제거
            while let last = kept.last, last.action.isButtonDown {
                kept.removeLast()
            }
        }
        return Recording(id: id, name: name, createdAt: createdAt, events: kept)
    }
}
