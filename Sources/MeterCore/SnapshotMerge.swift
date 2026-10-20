import Foundation

/// Every running Claude Code session invokes the hook with its own, possibly
/// stale, view of the rate limits. Within one window (same `resetsAt`) the
/// used percentage only rises, so the maximum is the truth; a later
/// `resetsAt` is a new window and replaces the old one outright.
public enum SnapshotMerge {
    public static func mergeWindow(existing: UsageWindow?, incoming: UsageWindow?) -> UsageWindow? {
        guard let incoming else { return existing }
        guard let existing else { return incoming }
        if incoming.resetsAt > existing.resetsAt { return incoming }
        if incoming.resetsAt < existing.resetsAt { return existing }
        return incoming.usedPercentage >= existing.usedPercentage ? incoming : existing
    }

    public static func merge(existing: ProviderUsage?, incoming: ProviderUsage) -> ProviderUsage {
        ProviderUsage(
            fiveHour: mergeWindow(existing: existing?.fiveHour, incoming: incoming.fiveHour),
            sevenDay: mergeWindow(existing: existing?.sevenDay, incoming: incoming.sevenDay),
            capturedAt: incoming.capturedAt,
            source: incoming.source
        )
    }

    public static func merge(snapshot: Snapshot?, providerID: String, incoming: ProviderUsage) -> Snapshot {
        var result = snapshot ?? Snapshot(schemaVersion: Snapshot.currentSchemaVersion, providers: [:])
        result.schemaVersion = Snapshot.currentSchemaVersion
        result.providers[providerID] = merge(existing: result.providers[providerID], incoming: incoming)
        return result
    }
}
