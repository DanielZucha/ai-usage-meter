import Foundation

/// Reads and writes the snapshot file. Writes go to a temporary file in the
/// same directory followed by `rename(2)`, so a reader never sees a partial
/// document.
public struct SnapshotStore: Sendable {
    public static let directoryName = "ai-usage-meter"
    public static let fileName = "snapshot.json"
    public static let lockFileName = "snapshot.lock"

    /// Sleep between non-blocking lock attempts.
    public static let lockRetryInterval: TimeInterval = 0.005
    /// Total time to keep retrying before giving up on the lock.
    public static let lockTimeout: TimeInterval = 0.25

    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    private var directory: URL {
        fileURL.deletingLastPathComponent()
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
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let temporary = directory.appendingPathComponent(
            ".\(Self.fileName).\(ProcessInfo.processInfo.processIdentifier).\(UUID().uuidString).tmp"
        )
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
    ///
    /// Acquisition is bounded, not blocking: it polls a non-blocking
    /// `flock` up to `lockTimeout`, sleeping `lockRetryInterval` between
    /// attempts. The hook runs inside Claude Code's render loop and must
    /// never stall indefinitely, so if the lock is still held when the
    /// bound expires, `body` runs anyway without it (best effort, no
    /// throw, no output). That is safe: `write(_:)` is still atomic via
    /// `rename(2)`, and the merge this guards is monotone, so a lost
    /// update is repaired by the next hook invocation.
    public func withExclusiveLock<T>(_ body: () throws -> T) throws -> T {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let lockPath = directory.appendingPathComponent(Self.lockFileName).path
        let descriptor = open(lockPath, O_CREAT | O_RDWR | O_CLOEXEC, 0o644)
        guard descriptor >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { close(descriptor) }

        var acquired = false
        let deadline = Date().addingTimeInterval(Self.lockTimeout)
        repeat {
            if flock(descriptor, LOCK_EX | LOCK_NB) == 0 {
                acquired = true
                break
            }
            guard errno == EWOULDBLOCK else {
                throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            }
            usleep(useconds_t(Self.lockRetryInterval * 1_000_000))
        } while Date() < deadline

        defer { if acquired { flock(descriptor, LOCK_UN) } }
        return try body()
    }
}
