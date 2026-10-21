import Foundation

/// 녹화를 JSON 파일(녹화 1개당 1파일)로 저장한다.
public struct RecordingStore {
    public let directory: URL

    public static var defaultDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CursorMoving/Recordings", isDirectory: true)
    }

    public init(directory: URL = RecordingStore.defaultDirectory) {
        self.directory = directory
    }

    /// 최신순으로 정렬해 반환한다. 읽을 수 없는 파일은 건너뛴다.
    public func loadAll() -> [Recording] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else { return [] }

        let decoder = JSONDecoder()
        return urls
            .filter { $0.pathExtension == "json" }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(Recording.self, from: data)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    public func save(_ recording: Recording) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(recording).write(to: fileURL(for: recording), options: .atomic)
    }

    public func delete(_ recording: Recording) throws {
        let url = fileURL(for: recording)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private func fileURL(for recording: Recording) -> URL {
        directory.appendingPathComponent("\(recording.id.uuidString).json")
    }
}
