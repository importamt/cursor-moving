import CoreGraphics
import XCTest
@testable import CursorMovingCore

final class RecordingStoreTests: XCTestCase {
    private var directory: URL!
    private var store: RecordingStore!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RecordingStoreTests-\(UUID().uuidString)", isDirectory: true)
        store = RecordingStore(directory: directory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeRecording(name: String, createdAt: Date) -> Recording {
        var builder = RecordingBuilder(includesMoves: false)
        builder.append(.leftDown, at: CGPoint(x: 10, y: 20), clickCount: 2, timestamp: 0)
        builder.append(.leftUp, at: CGPoint(x: 10, y: 20), timestamp: 0.1)
        return builder.build(name: name, createdAt: createdAt)
    }

    func testLoadAllReturnsEmptyWhenDirectoryMissing() {
        XCTAssertEqual(store.loadAll(), [])
    }

    func testSaveCreatesDirectoryAndRoundTrips() throws {
        let recording = makeRecording(name: "a", createdAt: Date(timeIntervalSince1970: 1000.123))

        try store.save(recording)

        XCTAssertEqual(store.loadAll(), [recording])
    }

    func testLoadAllSortsNewestFirst() throws {
        let old = makeRecording(name: "old", createdAt: Date(timeIntervalSince1970: 1))
        let new = makeRecording(name: "new", createdAt: Date(timeIntervalSince1970: 2))
        try store.save(old)
        try store.save(new)

        XCTAssertEqual(store.loadAll().map(\.name), ["new", "old"])
    }

    func testSaveOverwritesSameRecording() throws {
        var recording = makeRecording(name: "before", createdAt: Date(timeIntervalSince1970: 1))
        try store.save(recording)
        recording.name = "after"
        try store.save(recording)

        XCTAssertEqual(store.loadAll().map(\.name), ["after"])
    }

    func testLoadAllSkipsCorruptedAndForeignFiles() throws {
        let recording = makeRecording(name: "ok", createdAt: Date(timeIntervalSince1970: 1))
        try store.save(recording)
        try Data("not json".utf8).write(to: directory.appendingPathComponent("broken.json"))
        try Data("memo".utf8).write(to: directory.appendingPathComponent("notes.txt"))

        XCTAssertEqual(store.loadAll(), [recording])
    }

    func testDeleteRemovesRecording() throws {
        let recording = makeRecording(name: "a", createdAt: Date(timeIntervalSince1970: 1))
        try store.save(recording)

        try store.delete(recording)

        XCTAssertEqual(store.loadAll(), [])
    }

    func testDeleteMissingRecordingDoesNotThrow() {
        let recording = makeRecording(name: "ghost", createdAt: Date(timeIntervalSince1970: 1))

        XCTAssertNoThrow(try store.delete(recording))
    }
}
