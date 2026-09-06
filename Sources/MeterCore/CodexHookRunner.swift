import Foundation

/// Supplies a narrow Codex usage snapshot without exposing account metadata
/// or authentication material to the meter.
public protocol CodexUsageFetching: Sendable {
    func fetchUsage(executableURL: URL, capturedAt: Date) throws -> ProviderUsage?
}

/// Best-effort Codex hook coordination. Failures are intentionally silent:
/// a missed refresh must never affect the Codex session that invoked it.
public enum CodexHookRunner {
    public static func run(
        executableURL: URL,
        store: SnapshotStore,
        now: Date = Date(),
        fetcher: any CodexUsageFetching
    ) {
        guard let incoming = try? fetcher.fetchUsage(
            executableURL: executableURL,
            capturedAt: now
        ), incoming.sevenDay != nil else { return }

        try? store.withExclusiveLock {
            var merged = SnapshotMerge.merge(
                snapshot: store.read(),
                providerID: Snapshot.codexProviderID,
                incoming: incoming
            )
            merged.providers[Snapshot.codexProviderID]?.fiveHour = nil
            try store.write(merged)
        }
    }
}
