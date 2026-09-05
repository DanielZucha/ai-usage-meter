import Foundation
import Testing
@testable import MeterCore

@Suite struct SnapshotStoreTests {
    func temporaryStore() throws -> SnapshotStore {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ai-usage-meter-tests-\(UUID().uuidString)")
        return SnapshotStore(fileURL: dir.appendingPathComponent("nested/snapshot.json"))
    }

    func sample() -> Snapshot {
        Snapshot(schemaVersion: 1, providers: [
            "claude": ProviderUsage(
                fiveHour: UsageWindow(usedPercentage: 21, resetsAt: Fixtures.fiveReset),
                sevenDay: nil, capturedAt: Fixtures.captured, source: "statusline")
        ])
    }

    @Test func readReturnsNilWhenMissing() throws {
        #expect(try temporaryStore().read() == nil)
    }

    @Test func writeCreatesDirectoriesAndReadsBack() throws {
        let store = try temporaryStore()
        try store.write(sample())
        #expect(store.read() == sample())
    }

    @Test func writeLeavesNoTemporaryFileBehind() throws {
        let store = try temporaryStore()
        try store.write(sample())
        let siblings = try FileManager.default.contentsOfDirectory(atPath: store.fileURL.deletingLastPathComponent().path)
        #expect(siblings == ["snapshot.json"])
    }

    @Test func overwriteReplacesContent() throws {
        let store = try temporaryStore()
        try store.write(sample())
        var second = sample()
        second.claude?.fiveHour?.usedPercentage = 99
        try store.write(second)
        #expect(store.read()?.claude?.fiveHour?.usedPercentage == 99)
    }

    @Test func readReturnsNilOnGarbage() throws {
        let store = try temporaryStore()
        try FileManager.default.createDirectory(at: store.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{not json".utf8).write(to: store.fileURL)
        #expect(store.read() == nil)
    }

    @Test func defaultURLLivesInApplicationSupport() {
        let url = SnapshotStore.defaultURL()
        #expect(url.path.hasSuffix("/Library/Application Support/ai-usage-meter/snapshot.json"))
    }

    @Test func exclusiveLockRunsTheBodyAndReturnsItsValue() throws {
        let store = try temporaryStore()
        let value = try store.withExclusiveLock { 42 }
        #expect(value == 42)
        let lockPath = store.fileURL.deletingLastPathComponent().appendingPathComponent("snapshot.lock").path
        #expect(FileManager.default.fileExists(atPath: lockPath))
    }

    @Test func exclusiveLockSerializesWriters() throws {
        let store = try temporaryStore()
        let group = DispatchGroup()
        let counter = LockedCounter()
        for index in 0..<20 {
            group.enter()
            DispatchQueue.global().async {
                try? store.withExclusiveLock {
                    let current = store.read()?.claude?.fiveHour?.usedPercentage ?? 0
                    var next = Snapshot(schemaVersion: 1, providers: [:])
                    next.claude = ProviderUsage(
                        fiveHour: UsageWindow(usedPercentage: current + 1, resetsAt: Fixtures.fiveReset),
                        sevenDay: nil, capturedAt: Fixtures.captured, source: "test-\(index)")
                    try store.write(next)
                    counter.increment()
                }
                group.leave()
            }
        }
        group.wait()
        #expect(counter.value == 20)
        #expect(store.read()?.claude?.fiveHour?.usedPercentage == 20)
    }
}

/// Test helper: a counter safe to bump from several queues.
final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    var value: Int { lock.withLock { count } }
    func increment() { lock.withLock { count += 1 } }
}
