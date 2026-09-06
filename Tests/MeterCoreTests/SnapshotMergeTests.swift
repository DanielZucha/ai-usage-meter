import Foundation
import Testing
@testable import MeterCore

@Suite struct SnapshotMergeTests {
    let reset = Fixtures.fiveReset
    let laterReset = Fixtures.fiveReset.addingTimeInterval(5 * 3600)

    @Test func laterResetReplacesOutright() {
        let existing = UsageWindow(usedPercentage: 80, resetsAt: reset)
        let incoming = UsageWindow(usedPercentage: 3, resetsAt: laterReset)
        #expect(SnapshotMerge.mergeWindow(existing: existing, incoming: incoming) == incoming)
    }

    @Test func sameResetKeepsTheMaximum() {
        let high = UsageWindow(usedPercentage: 21, resetsAt: reset)
        let low = UsageWindow(usedPercentage: 12, resetsAt: reset)
        #expect(SnapshotMerge.mergeWindow(existing: high, incoming: low) == high)
        #expect(SnapshotMerge.mergeWindow(existing: low, incoming: high) == high)
    }

    @Test func earlierResetIsDiscardedAsStale() {
        let existing = UsageWindow(usedPercentage: 3, resetsAt: laterReset)
        let stale = UsageWindow(usedPercentage: 90, resetsAt: reset)
        #expect(SnapshotMerge.mergeWindow(existing: existing, incoming: stale) == existing)
    }

    @Test func absentIncomingKeepsExisting() {
        let existing = UsageWindow(usedPercentage: 40, resetsAt: reset)
        #expect(SnapshotMerge.mergeWindow(existing: existing, incoming: nil) == existing)
    }

    @Test func absentExistingTakesIncoming() {
        let incoming = UsageWindow(usedPercentage: 40, resetsAt: reset)
        #expect(SnapshotMerge.mergeWindow(existing: nil, incoming: incoming) == incoming)
        #expect(SnapshotMerge.mergeWindow(existing: nil, incoming: nil) == nil)
    }

    @Test func providerMergeStampsIncomingCaptureTime() {
        let existing = ProviderUsage(
            fiveHour: UsageWindow(usedPercentage: 21, resetsAt: reset),
            sevenDay: UsageWindow(usedPercentage: 4, resetsAt: Fixtures.sevenReset),
            capturedAt: Fixtures.captured, source: "statusline")
        let later = Fixtures.captured.addingTimeInterval(60)
        let incoming = ProviderUsage(
            fiveHour: UsageWindow(usedPercentage: 12, resetsAt: reset),
            sevenDay: nil,
            capturedAt: later, source: "statusline")
        let merged = SnapshotMerge.merge(existing: existing, incoming: incoming)
        #expect(merged.fiveHour?.usedPercentage == 21)
        #expect(merged.sevenDay?.usedPercentage == 4)
        #expect(merged.capturedAt == later)
    }

    @Test func providerMergeDoesNotRegressCaptureMetadata() {
        let later = Fixtures.captured.addingTimeInterval(60)
        let existing = ProviderUsage(
            fiveHour: UsageWindow(usedPercentage: 21, resetsAt: reset),
            sevenDay: nil,
            capturedAt: later,
            source: "newer-source"
        )
        let stale = ProviderUsage(
            fiveHour: UsageWindow(usedPercentage: 12, resetsAt: reset),
            sevenDay: UsageWindow(usedPercentage: 4, resetsAt: Fixtures.sevenReset),
            capturedAt: Fixtures.captured,
            source: "stale-source"
        )

        let merged = SnapshotMerge.merge(existing: existing, incoming: stale)

        #expect(merged.fiveHour?.usedPercentage == 21)
        #expect(merged.sevenDay?.usedPercentage == 4)
        #expect(merged.capturedAt == later)
        #expect(merged.source == "newer-source")
    }

    @Test func snapshotMergeCreatesTheDocumentWhenMissing() {
        let incoming = ProviderUsage(
            fiveHour: UsageWindow(usedPercentage: 21, resetsAt: reset),
            sevenDay: nil, capturedAt: Fixtures.captured, source: "statusline")
        let merged = SnapshotMerge.merge(snapshot: nil, providerID: "claude", incoming: incoming)
        #expect(merged.schemaVersion == Snapshot.currentSchemaVersion)
        #expect(merged.claude == incoming)
    }

    @Test func snapshotMergeLeavesOtherProvidersAlone() {
        let codex = ProviderUsage(fiveHour: nil, sevenDay: nil, capturedAt: Fixtures.captured, source: "other")
        let snapshot = Snapshot(schemaVersion: 1, providers: ["codex": codex])
        let incoming = ProviderUsage(
            fiveHour: UsageWindow(usedPercentage: 1, resetsAt: reset),
            sevenDay: nil, capturedAt: Fixtures.captured, source: "statusline")
        let merged = SnapshotMerge.merge(snapshot: snapshot, providerID: "claude", incoming: incoming)
        #expect(merged.providers["codex"] == codex)
        #expect(merged.claude == incoming)
    }
}
