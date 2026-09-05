import Foundation

/// Reads and writes the snapshot file. Writes go to a temporary file in the
/// same directory followed by `rename(2)`, so a reader never sees a partial
/// document.
public struct SnapshotStore: Sendable {
    public static let directoryName = "ai-usage-meter"
    public static let fileName = "snapshot.json"
    public static let lockFileName = "snapshot.lock"

    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static func defaultURL(fileManager: FileManager = .default) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent(directoryName).appendingPathComponent(fileName)
    }

    public static var `default`: SnapshotStore {
        SnapshotStore(fileURL: defaultURL())
    }

    /// Nil when the file is missing or unreadable as a snapshot.
    public func read() -> Snapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? SnapshotCoding.decode(data)
    }

    public func write(_ snapshot: Snapshot) throws {
        let data = try SnapshotCoding.encode(snapshot)
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let temporary = directory.appendingPathComponent(".\(Self.fileName).\(ProcessInfo.processInfo.processIdentifier).tmp")
        try data.write(to: temporary)
        guard rename(temporary.path, fileURL.path) == 0 else {
            let code = errno
            try? FileManager.default.removeItem(at: temporary)
            throw POSIXError(POSIXErrorCode(rawValue: code) ?? .EIO)
        }
    }

    /// Serializes read-merge-write cycles across processes. Every running
    /// Claude Code session invokes the hook, often in the same second, and
    /// without this an interleaved pair can drop the higher value.
    public func withExclusiveLock<T>(_ body: () throws -> T) throws -> T {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let lockPath = directory.appendingPathComponent(Self.lockFileName).path
        let descriptor = open(lockPath, O_CREAT | O_RDWR | O_CLOEXEC, 0o644)
        guard descriptor >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX) == 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { flock(descriptor, LOCK_UN) }
        return try body()
    }
}
