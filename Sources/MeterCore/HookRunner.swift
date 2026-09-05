import Foundation

/// Everything the hook executable does, minus stdin and stdout, so it can be
/// tested. Never throws: the hook runs inside Claude Code's render loop and
/// a failure must cost nothing but a missing update. The read-merge-write
/// runs under the store's file lock because several sessions fire at once.
public enum HookRunner {
    public static func run(input: Data, store: SnapshotStore, now: Date = Date()) -> String {
        let payload = try? StatuslinePayload.decode(input)
        if let payload, let incoming = payload.providerUsage(capturedAt: now) {
            try? store.withExclusiveLock {
                let merged = SnapshotMerge.merge(
                    snapshot: store.read(),
                    providerID: Snapshot.claudeProviderID,
                    incoming: incoming
                )
                try store.write(merged)
            }
        }
        return StatuslineLine.render(payload)
    }
}
