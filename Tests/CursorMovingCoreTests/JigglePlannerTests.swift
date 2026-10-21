import CoreGraphics
import XCTest
@testable import CursorMovingCore

/// 테스트용 결정적 난수 생성기 (SplitMix64)
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

final class JigglePlannerTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)

    // MARK: - subtle

    func testSubtleMovesOnePixelRightThenReturns() {
        var rng = SeededGenerator(seed: 1)
        let current = CGPoint(x: 500, y: 300)

        let targets = JigglePlanner.targets(from: current, in: screen, mode: .subtle, using: &rng)

        XCTAssertEqual(targets, [CGPoint(x: 501, y: 300), current])
    }

    func testSubtleMovesLeftWhenAtRightEdge() {
        var rng = SeededGenerator(seed: 1)
        let current = CGPoint(x: screen.maxX - 1, y: 300)

        let targets = JigglePlanner.targets(from: current, in: screen, mode: .subtle, using: &rng)

        XCTAssertEqual(targets, [CGPoint(x: screen.maxX - 2, y: 300), current])
    }

    func testSubtleWorksOnSecondaryDisplayWithNegativeOrigin() {
        var rng = SeededGenerator(seed: 1)
        let secondary = CGRect(x: -1920, y: -200, width: 1920, height: 1080)
        let current = CGPoint(x: -1, y: 0)

        let targets = JigglePlanner.targets(from: current, in: secondary, mode: .subtle, using: &rng)

        XCTAssertEqual(targets, [CGPoint(x: -2, y: 0), current])
    }

    // MARK: - random

    func testRandomTargetStaysInsideInsetBounds() {
        var rng = SeededGenerator(seed: 42)
        let area = screen.insetBy(dx: JigglePlanner.randomInset, dy: JigglePlanner.randomInset)

        for _ in 0..<500 {
            let targets = JigglePlanner.targets(from: .zero, in: screen, mode: .random, using: &rng)
            XCTAssertEqual(targets.count, 1)
            XCTAssertTrue(area.contains(targets[0]), "\(targets[0]) is outside \(area)")
        }
    }

    func testRandomFallsBackToFullBoundsWhenTooSmallForInset() {
        var rng = SeededGenerator(seed: 7)
        let tiny = CGRect(x: 10, y: 10, width: 5, height: 5)

        let targets = JigglePlanner.targets(from: .zero, in: tiny, mode: .random, using: &rng)

        XCTAssertEqual(targets.count, 1)
        XCTAssertTrue(tiny.contains(targets[0]))
    }

    func testReturnsCurrentPointWhenBoundsAreNull() {
        var rng = SeededGenerator(seed: 7)
        let current = CGPoint(x: 3, y: 4)

        let targets = JigglePlanner.targets(from: current, in: .null, mode: .random, using: &rng)

        XCTAssertEqual(targets, [current])
    }

    // MARK: - idle gate

    func testShouldJiggleWhenIdleLongerThanInterval() {
        XCTAssertTrue(JigglePlanner.shouldJiggle(idleSeconds: 61, interval: 60))
    }

    func testShouldJiggleWithinToleranceOfInterval() {
        XCTAssertTrue(JigglePlanner.shouldJiggle(idleSeconds: 59.5, interval: 60))
    }

    func testShouldNotJiggleWhenUserIsActive() {
        XCTAssertFalse(JigglePlanner.shouldJiggle(idleSeconds: 3, interval: 60))
    }
}
