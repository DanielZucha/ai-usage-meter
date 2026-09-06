import Foundation

/// Supplies a narrow Codex usage snapshot without exposing account metadata
/// or authentication material to the meter.
public protocol CodexUsageFetching: Sendable {
    func fetchUsage(executableURL: URL, capturedAt: Date) throws -> ProviderUsage?
}

/// Serializes Codex fetches separately from the short shared snapshot lock.
public enum CodexSnapshotUpdater {
    public static let pollLockFileName = "codex-poll.lock"

    public static func run(
        executableURL: URL,
        store: SnapshotStore,
        now: @Sendable () -> Date = { Date() },
        fetcher: any CodexUsageFetching
    ) -> CodexPollOutcome {
        do {
            try Task.checkCancellation()
            let directory = store.fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let descriptor = open(directory.appendingPathComponent(pollLockFileName).path,
                                  O_CREAT | O_RDWR | O_CLOEXEC | O_NOFOLLOW, 0o600)
            guard descriptor >= 0 else { return .unavailable }
            defer { close(descriptor) }
            guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
                return errno == EWOULDBLOCK ? .busy : .unavailable
            }
            defer { flock(descriptor, LOCK_UN) }
            guard var incoming = try fetcher.fetchUsage(executableURL: executableURL, capturedAt: now()),
                  incoming.sevenDay != nil else { return .unavailable }
            try Task.checkCancellation()
            incoming.capturedAt = now()
            try store.withExclusiveLock {
                try Task.checkCancellation()
                var merged = store.read() ?? Snapshot(schemaVersion: Snapshot.currentSchemaVersion, providers: [:])
                merged.schemaVersion = Snapshot.currentSchemaVersion
                // Serialized live account reads are authoritative, including
                // provider corrections to usage or the reset timestamp.
                incoming.fiveHour = nil
                merged.providers[Snapshot.codexProviderID] = incoming
                try store.write(merged)
            }
            return .updated
        } catch {
            return .unavailable
        }
    }
}
