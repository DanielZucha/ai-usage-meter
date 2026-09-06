import Foundation
import Testing
@testable import MeterCore

@Suite struct CodexSnapshotUpdaterTests {
    let executableURL = URL(fileURLWithPath: "/usr/local/bin/codex")
    let now = Date(timeIntervalSince1970: 1_788_608_892)

    func temporaryStore() -> SnapshotStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ai-usage-meter-codex-hook-tests-\(UUID().uuidString)")
        return SnapshotStore(fileURL: directory.appendingPathComponent("snapshot.json"))
    }

    func claudeUsage() -> ProviderUsage {
        ProviderUsage(
            fiveHour: UsageWindow(usedPercentage: 21, resetsAt: Fixtures.fiveReset),
            sevenDay: UsageWindow(usedPercentage: 4, resetsAt: Fixtures.sevenReset),
            capturedAt: Fixtures.captured,
            source: "statusline"
        )
    }

    func oldCodexUsage() -> ProviderUsage {
        ProviderUsage(
            fiveHour: UsageWindow(usedPercentage: 8, resetsAt: Fixtures.fiveReset),
            sevenDay: UsageWindow(usedPercentage: 2, resetsAt: Fixtures.sevenReset),
            capturedAt: Fixtures.captured,
            source: "old-codex-source"
        )
    }

    func seededStore() throws -> SnapshotStore {
        let store = temporaryStore()
        try store.write(Snapshot(schemaVersion: 1, providers: [
            Snapshot.claudeProviderID: claudeUsage(),
            Snapshot.codexProviderID: oldCodexUsage(),
        ]))
        return store
    }

    @Test func successfulFetchPreservesClaudeAndReplacesOnlyCodex() throws {
       let store = try seededStore()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        let incoming = ProviderUsage(
            fiveHour: nil,
            sevenDay: UsageWindow(
                usedPercentage: 11,
                resetsAt: Fixtures.sevenReset.addingTimeInterval(3_600)
            ),
            capturedAt: now,
            source: "codex-app-server"
        )
        let fetcher = FakeCodexUsageFetcher(response: .usage(incoming))

        _ = CodexSnapshotUpdater.run(executableURL: executableURL, store: store, now: { now }, fetcher: fetcher)

        let snapshot = try #require(store.read())
        #expect(snapshot.providers.count == 2)
        #expect(snapshot.providers[Snapshot.claudeProviderID] == claudeUsage())
        #expect(snapshot.providers[Snapshot.codexProviderID] == incoming)
    }

    @Test func authoritativeFetchCorrectsEarlierResetAndLowerUsage() throws {
        let store = try seededStore()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        var initial = oldCodexUsage()
        initial.sevenDay = UsageWindow(usedPercentage: 12, resetsAt: Fixtures.sevenReset.addingTimeInterval(1))
        try store.withExclusiveLock {
            var snapshot = try #require(store.read())
            snapshot.providers[Snapshot.codexProviderID] = initial
            try store.write(snapshot)
        }
        var incoming = ProviderUsage(fiveHour: nil,
            sevenDay: UsageWindow(usedPercentage: 23, resetsAt: Fixtures.sevenReset),
            capturedAt: now, source: "codex-app-server")
        let first = FakeCodexUsageFetcher(response: .usage(incoming))
        #expect(CodexSnapshotUpdater.run(executableURL: executableURL, store: store,
                                        now: { now }, fetcher: first) == .updated)
        #expect(store.read()?.providers[Snapshot.codexProviderID] == incoming)
        incoming.sevenDay?.usedPercentage = 18
        let correction = FakeCodexUsageFetcher(response: .usage(incoming))
        #expect(CodexSnapshotUpdater.run(executableURL: executableURL, store: store,
                                        now: { now }, fetcher: correction) == .updated)
        #expect(store.read()?.providers[Snapshot.codexProviderID] == incoming)
        #expect(store.read()?.providers[Snapshot.claudeProviderID] == claudeUsage())
    }

    @Test func nilFetchLeavesSnapshotBytesUnchanged() throws {
       let store = try seededStore()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        let before = try Data(contentsOf: store.fileURL)
        let fetcher = FakeCodexUsageFetcher(response: .usage(nil))

        _ = CodexSnapshotUpdater.run(executableURL: executableURL, store: store, now: { now }, fetcher: fetcher)

        #expect(try Data(contentsOf: store.fileURL) == before)
    }

    @Test func throwingFetchLeavesSnapshotBytesUnchanged() throws {
       let store = try seededStore()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        let before = try Data(contentsOf: store.fileURL)
        let fetcher = FakeCodexUsageFetcher(response: .failure)

        _ = CodexSnapshotUpdater.run(executableURL: executableURL, store: store, now: { now }, fetcher: fetcher)

        #expect(try Data(contentsOf: store.fileURL) == before)
    }

    @Test func fiveHourOnlyFetchLeavesSnapshotBytesUnchanged() throws {
       let store = try seededStore()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        let before = try Data(contentsOf: store.fileURL)
        let incomingFiveHour = UsageWindow(
            usedPercentage: 31,
            resetsAt: Fixtures.fiveReset.addingTimeInterval(3_600)
        )
        let incoming = ProviderUsage(
            fiveHour: incomingFiveHour,
            sevenDay: nil,
            capturedAt: now,
            source: "codex-app-server"
        )
        let fetcher = FakeCodexUsageFetcher(response: .usage(incoming))

        _ = CodexSnapshotUpdater.run(executableURL: executableURL, store: store, now: { now }, fetcher: fetcher)

        #expect(try Data(contentsOf: store.fileURL) == before)
    }

    @Test func lockTimeoutLeavesSnapshotUnchangedAfterFetching() throws {
       let store = try seededStore()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        let before = try Data(contentsOf: store.fileURL)
        let lockPath = store.fileURL.deletingLastPathComponent()
            .appendingPathComponent(SnapshotStore.lockFileName).path
        let externalDescriptor = open(lockPath, O_CREAT | O_RDWR, 0o644)
        #expect(externalDescriptor >= 0)
        #expect(flock(externalDescriptor, LOCK_EX) == 0)
        defer {
            flock(externalDescriptor, LOCK_UN)
            close(externalDescriptor)
        }
        let fetcher = FakeCodexUsageFetcher(response: .usage(oldCodexUsage()))

        _ = CodexSnapshotUpdater.run(executableURL: executableURL, store: store, now: { now }, fetcher: fetcher)

        // Fetch outside the file lock: the App Server exchange can take
        // seconds and must not block Claude's independent snapshot writer.
        #expect(fetcher.callCount == 1)
        #expect(try Data(contentsOf: store.fileURL) == before)
    }
}

private final class FakeCodexUsageFetcher: CodexUsageFetching, @unchecked Sendable {
    enum Response: Sendable {
        case usage(ProviderUsage?)
        case failure
    }

    private let response: Response
    private let lock = NSLock()
    private var calls = 0

    init(response: Response) {
        self.response = response
    }

    var callCount: Int {
        lock.withLock { calls }
    }

    func fetchUsage(executableURL: URL, capturedAt: Date) throws -> ProviderUsage? {
        lock.withLock { calls += 1 }
        switch response {
        case .usage(let usage): return usage
        case .failure: throw FakeCodexUsageError.unavailable
        }
    }
}

private enum FakeCodexUsageError: Error {
    case unavailable
}
