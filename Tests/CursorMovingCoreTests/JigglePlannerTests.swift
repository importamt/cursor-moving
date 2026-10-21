import CoreGraphics
import XCTest
@testable import CursorMovingCore

final class JigglePlannerTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 1512, height: 982)
    private let steps = 120

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    // MARK: - path

    func testEveryShapeReturnsRequestedNumberOfSteps() {
        for shape in JiggleShape.allCases {
            let path = JigglePlanner.path(shape: shape, from: CGPoint(x: 500, y: 300), in: screen, steps: steps)
            XCTAssertEqual(path.count, steps, "\(shape)")
        }
    }

    func testEveryShapeEndsWhereItStarted() {
        let current = CGPoint(x: 500, y: 300)
        for shape in JiggleShape.allCases {
            let path = JigglePlanner.path(shape: shape, from: current, in: screen, steps: steps)
            XCTAssertEqual(path.last, current, "\(shape)")
        }
    }

    func testEveryShapeMovesSmoothlyWithoutJumps() {
        let current = CGPoint(x: 500, y: 300)
        for shape in JiggleShape.allCases {
            let path = JigglePlanner.path(shape: shape, from: current, in: screen, steps: steps)
            var previous = current
            for point in path {
                XCTAssertLessThan(distance(previous, point), 12, "\(shape) jumped \(previous) → \(point)")
                previous = point
            }
        }
    }

    func testEveryShapeActuallyMovesAwayFromStart() {
        let current = CGPoint(x: 500, y: 300)
        for shape in JiggleShape.allCases {
            let path = JigglePlanner.path(shape: shape, from: current, in: screen, steps: steps)
            let farthest = path.map { distance(current, $0) }.max() ?? 0
            XCTAssertGreaterThanOrEqual(farthest, JigglePlanner.shapeSize / 2, "\(shape)")
        }
    }

    func testCircleIsDrawnLargerThanOtherShapes() {
        let current = CGPoint(x: 500, y: 300)
        let path = JigglePlanner.path(shape: .circle, from: current, in: screen, steps: steps)
        let diameter = path.map { distance(current, $0) }.max() ?? 0

        XCTAssertEqual(diameter, JigglePlanner.circleSize, accuracy: 1)
        XCTAssertGreaterThan(JigglePlanner.circleSize, JigglePlanner.shapeSize)
    }

    func testShapeIsMirroredInsideWhenStartingAtBottomRightCorner() {
        let current = CGPoint(x: screen.maxX - 1, y: screen.maxY - 1)
        for shape in JiggleShape.allCases {
            let path = JigglePlanner.path(shape: shape, from: current, in: screen, steps: steps)
            for point in path {
                XCTAssertTrue(screen.contains(point), "\(shape) \(point) is outside \(screen)")
            }
            XCTAssertEqual(path.last, current, "\(shape)")
        }
    }

    func testShapeStaysInsideSecondaryDisplayWithNegativeOrigin() {
        let secondary = CGRect(x: -1920, y: -200, width: 1920, height: 1080)
        let current = CGPoint(x: secondary.minX, y: secondary.minY)
        for shape in JiggleShape.allCases {
            let path = JigglePlanner.path(shape: shape, from: current, in: secondary, steps: steps)
            for point in path {
                XCTAssertTrue(secondary.contains(point), "\(shape) \(point) is outside \(secondary)")
            }
        }
    }

    func testShapeIsClampedOnDisplaySmallerThanShape() {
        let tiny = CGRect(x: 10, y: 10, width: 20, height: 20)
        let current = CGPoint(x: 15, y: 15)
        for shape in JiggleShape.allCases {
            let path = JigglePlanner.path(shape: shape, from: current, in: tiny, steps: steps)
            for point in path {
                XCTAssertTrue(tiny.contains(point), "\(shape) \(point) is outside \(tiny)")
            }
        }
    }

    func testReturnsCurrentPointWhenBoundsAreNull() {
        let current = CGPoint(x: 3, y: 4)

        let path = JigglePlanner.path(shape: .circle, from: current, in: .null, steps: steps)

        XCTAssertEqual(path, [current])
    }

    func testReturnsCurrentPointWhenStepsIsZero() {
        let current = CGPoint(x: 3, y: 4)

        let path = JigglePlanner.path(shape: .star, from: current, in: screen, steps: 0)

        XCTAssertEqual(path, [current])
    }

    // MARK: - idle gate

    func testShouldJiggleWhenIdleLongerThanThreshold() {
        XCTAssertTrue(JigglePlanner.shouldJiggle(idleSeconds: 31, secondsSinceLastJiggle: 100, threshold: 30))
    }

    func testShouldNotJiggleWhenUserIsActive() {
        XCTAssertFalse(JigglePlanner.shouldJiggle(idleSeconds: 3, secondsSinceLastJiggle: 100, threshold: 30))
    }

    func testShouldNotJiggleAgainBeforeThresholdPassesSinceLastJiggle() {
        XCTAssertFalse(JigglePlanner.shouldJiggle(idleSeconds: 100, secondsSinceLastJiggle: 10, threshold: 30))
    }
}
