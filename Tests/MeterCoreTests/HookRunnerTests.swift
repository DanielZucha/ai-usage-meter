import Foundation
import Testing
@testable import MeterCore

@Suite struct HookRunnerTests {
    func temporaryStore() -> SnapshotStore {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ai-usage-meter-hook-tests-\(UUID().uuidString)")
        return SnapshotStore(fileURL: dir.appendingPathComponent("snapshot.json"))
    }

    @Test func writesSnapshotAndReturnsLine() throws {
        let store = temporaryStore()
        let line = HookRunner.run(input: Fixtures.samplePayloadJSON, store: store, now: Fixtures.captured)
        #expect(line == "Fable 5.1 · ctx 12% · 5h 21% · 7d 4%")
        let snapshot = try #require(store.read())
        #expect(snapshot.claude?.fiveHour == UsageWindow(usedPercentage: 21, resetsAt: Fixtures.fiveReset))
        #expect(snapshot.claude?.sevenDay == UsageWindow(usedPercentage: 4, resetsAt: Fixtures.sevenReset))
        #expect(snapshot.claude?.capturedAt == Fixtures.captured)
    }

    @Test func staleSessionDoesNotLowerTheSnapshot() throws {
        let store = temporaryStore()
        _ = HookRunner.run(input: Fixtures.samplePayloadJSON, store: store, now: Fixtures.captured)
        let stale = Data("""
        {"rate_limits":{"five_hour":{"used_percentage":12,"resets_at":1788617400},
                        "seven_day":{"used_percentage":2,"resets_at":1789160400}}}
        """.utf8)
        _ = HookRunner.run(input: stale, store: store, now: Fixtures.captured.addingTimeInterval(5))
        let snapshot = try #require(store.read())
        #expect(snapshot.claude?.fiveHour?.usedPercentage == 21)
        #expect(snapshot.claude?.sevenDay?.usedPercentage == 4)
    }

    @Test func payloadWithoutRateLimitsLeavesSnapshotUntouched() throws {
        let store = temporaryStore()
        _ = HookRunner.run(input: Fixtures.samplePayloadJSON, store: store, now: Fixtures.captured)
        let before = store.read()
        let line = HookRunner.run(input: Fixtures.noRateLimitsJSON, store: store, now: Fixtures.captured.addingTimeInterval(5))
        #expect(line == "Fable 5.1 · ctx 3% · 5h -- · 7d --")
        #expect(store.read() == before)
    }

    @Test func garbageInputStillReturnsALineAndWritesNothing() {
        let store = temporaryStore()
        let line = HookRunner.run(input: Data("garbage".utf8), store: store, now: Fixtures.captured)
        #expect(line == "Claude · ctx -- · 5h -- · 7d --")
        #expect(store.read() == nil)
    }

    @Test func emptyInputStillReturnsALine() {
        let store = temporaryStore()
        #expect(HookRunner.run(input: Data(), store: store, now: Fixtures.captured) == "Claude · ctx -- · 5h -- · 7d --")
    }

    @Test func unwritableStoreDoesNotThrowOrChangeTheLine() {
        let store = SnapshotStore(fileURL: URL(fileURLWithPath: "/System/ai-usage-meter-cannot-write/snapshot.json"))
        let line = HookRunner.run(input: Fixtures.samplePayloadJSON, store: store, now: Fixtures.captured)
        #expect(line == "Fable 5.1 · ctx 12% · 5h 21% · 7d 4%")
    }
}
