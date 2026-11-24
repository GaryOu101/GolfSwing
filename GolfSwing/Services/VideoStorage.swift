import Foundation

/// Stores swing videos in the app's Documents/Swings folder.
enum VideoStorage {
    static var directory: URL {
        let dir = URL.documentsDirectory.appending(path: "Swings")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Copies a (temporary) picker video into permanent storage and returns its file name.
    static func save(_ source: URL) throws -> String {
        let ext = source.pathExtension.isEmpty ? "mov" : source.pathExtension
        let name = "\(UUID().uuidString).\(ext)"
        try FileManager.default.copyItem(at: source, to: directory.appending(path: name))
        return name
    }

    static func url(for fileName: String) -> URL {
        directory.appending(path: fileName)
    }

    static func delete(_ fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }
}
