import CoreGraphics
import XCTest
@testable import CursorMovingCore

final class RecordingBuilderTests: XCTestCase {
    func testEmptyBuilderProducesEmptyRecording() {
        let recording = RecordingBuilder(includesMoves: false).build(name: "empty")

        XCTAssertTrue(recording.events.isEmpty)
        XCTAssertEqual(recording.duration, 0)
        XCTAssertEqual(recording.clickCount, 0)
    }

    func testFirstEventHasZeroDelayAndLaterEventsUseGap() {
        var builder = RecordingBuilder(includesMoves: false)
        builder.append(.leftDown, at: CGPoint(x: 1, y: 2), timestamp: 100)
        builder.append(.leftUp, at: CGPoint(x: 1, y: 2), timestamp: 100.25)

        let events = builder.build(name: "r").events

        XCTAssertEqual(events.map(\.delay), [0, 0.25])
        XCTAssertEqual(events.map(\.action), [.leftDown, .leftUp])
    }

    func testDelayNeverNegativeWhenTimestampsGoBackwards() {
        var builder = RecordingBuilder(includesMoves: false)
        builder.append(.leftDown, at: .zero, timestamp: 10)
        builder.append(.leftUp, at: .zero, timestamp: 9)

        XCTAssertEqual(builder.build(name: "r").events.last?.delay, 0)
    }

    func testSkipsMovementWhenMovesExcluded() {
        var builder = RecordingBuilder(includesMoves: false)
        builder.append(.move, at: .zero, timestamp: 0)
        builder.append(.leftDrag, at: .zero, timestamp: 0.1)
        builder.append(.rightDown, at: .zero, timestamp: 0.2)

        XCTAssertEqual(builder.build(name: "r").events.map(\.action), [.rightDown])
    }

    func testDelayOfClickIncludesTimeOfSkippedMoves() {
        var builder = RecordingBuilder(includesMoves: false)
        builder.append(.leftDown, at: .zero, timestamp: 0)
        builder.append(.move, at: .zero, timestamp: 1)
        builder.append(.leftUp, at: .zero, timestamp: 2)

        XCTAssertEqual(builder.build(name: "r").events.last?.delay, 2)
    }

    func testKeepsMovementWhenMovesIncluded() {
        var builder = RecordingBuilder(includesMoves: true)
        builder.append(.move, at: CGPoint(x: 5, y: 5), timestamp: 0)
        builder.append(.leftDown, at: CGPoint(x: 5, y: 5), timestamp: 0.5)

        XCTAssertEqual(builder.build(name: "r").events.map(\.action), [.move, .leftDown])
    }

    func testThrottlesMovementFasterThanMinimumInterval() {
        var builder = RecordingBuilder(includesMoves: true)
        builder.append(.move, at: .zero, timestamp: 0)
        builder.append(.move, at: .zero, timestamp: 0.001)
        builder.append(.move, at: .zero, timestamp: RecordingBuilder.minimumMoveInterval + 0.001)

        XCTAssertEqual(builder.build(name: "r").events.count, 2)
    }

    func testNeverThrottlesButtonEvents() {
        var builder = RecordingBuilder(includesMoves: true)
        builder.append(.move, at: .zero, timestamp: 0)
        builder.append(.leftDown, at: .zero, timestamp: 0.001)
        builder.append(.leftUp, at: .zero, timestamp: 0.002)

        XCTAssertEqual(builder.build(name: "r").events.count, 3)
    }

    func testKeepsClickCountForDoubleClick() {
        var builder = RecordingBuilder(includesMoves: false)
        builder.append(.leftDown, at: .zero, clickCount: 2, timestamp: 0)

        XCTAssertEqual(builder.build(name: "r").events.first?.clickCount, 2)
    }

    func testClickCountClampsToAtLeastOne() {
        var builder = RecordingBuilder(includesMoves: false)
        builder.append(.leftDown, at: .zero, clickCount: 0, timestamp: 0)

        XCTAssertEqual(builder.build(name: "r").events.first?.clickCount, 1)
    }

    // MARK: - 메뉴바 클릭 제거

    func testMenuMarkTrimsEventsRecordedAfterMenuOpened() {
        var builder = RecordingBuilder(includesMoves: false)
        builder.append(.leftDown, at: .zero, timestamp: 0)
        builder.append(.leftUp, at: .zero, timestamp: 0.1)
        builder.markMenuOpened()
        builder.append(.leftDown, at: CGPoint(x: 900, y: 0), timestamp: 1)
        builder.append(.leftUp, at: CGPoint(x: 900, y: 0), timestamp: 1.1)

        XCTAssertEqual(builder.build(name: "r").events.map(\.action), [.leftDown, .leftUp])
    }

    func testMenuMarkDropsDanglingButtonDownThatOpenedMenu() {
        var builder = RecordingBuilder(includesMoves: false)
        builder.append(.rightDown, at: .zero, timestamp: 0)
        builder.append(.rightUp, at: .zero, timestamp: 0.1)
        builder.append(.leftDown, at: CGPoint(x: 900, y: 0), timestamp: 1)
        builder.markMenuOpened()
        builder.append(.leftUp, at: CGPoint(x: 900, y: 0), timestamp: 1.1)

        XCTAssertEqual(builder.build(name: "r").events.map(\.action), [.rightDown, .rightUp])
    }

    func testClearedMenuMarkKeepsAllEvents() {
        var builder = RecordingBuilder(includesMoves: false)
        builder.append(.leftDown, at: .zero, timestamp: 0)
        builder.markMenuOpened()
        builder.append(.leftUp, at: .zero, timestamp: 0.1)
        builder.clearMenuMark()

        XCTAssertEqual(builder.build(name: "r").events.count, 2)
    }

    // MARK: - Recording 요약

    func testRecordingSummarizesDurationAndClicks() {
        var builder = RecordingBuilder(includesMoves: false)
        builder.append(.leftDown, at: .zero, timestamp: 0)
        builder.append(.leftUp, at: .zero, timestamp: 0.5)
        builder.append(.rightDown, at: .zero, timestamp: 1.5)
        builder.append(.rightUp, at: .zero, timestamp: 2)

        let recording = builder.build(name: "r")

        XCTAssertEqual(recording.duration, 2, accuracy: 0.0001)
        XCTAssertEqual(recording.clickCount, 2)
    }
}
