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
        #expect(line == "Fable 5.1 · high · ⛁ 12%")
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
        #expect(line == "Fable 5.1 · ⛁ 3%")
        #expect(store.read() == before)
    }

    @Test func rateLimitsWithNoUsableWindowLeavesSnapshotUntouched() throws {
        let store = temporaryStore()
        _ = HookRunner.run(input: Fixtures.samplePayloadJSON, store: store, now: Fixtures.captured)
        let before = store.read()
        let hollow = Data(#"{"model":{"display_name":"Fable 5.1"},"rate_limits":{"five_hour":{"used_percentage":50},"seven_day":{"resets_at":1789160400}}}"#.utf8)
        let line = HookRunner.run(input: hollow, store: store, now: Fixtures.captured.addingTimeInterval(5))
        #expect(line == "Fable 5.1 · ⛁ --")
        #expect(store.read() == before)
    }

    @Test func garbageInputStillReturnsALineAndWritesNothing() {
        let store = temporaryStore()
        let line = HookRunner.run(input: Data("garbage".utf8), store: store, now: Fixtures.captured)
        #expect(line == "Claude · ⛁ --")
        #expect(store.read() == nil)
    }

    @Test func emptyInputStillReturnsALine() {
        let store = temporaryStore()
        #expect(HookRunner.run(input: Data(), store: store, now: Fixtures.captured) == "Claude · ⛁ --")
    }

    @Test func unwritableStoreDoesNotThrowOrChangeTheLine() {
        let store = SnapshotStore(fileURL: URL(fileURLWithPath: "/System/ai-usage-meter-cannot-write/snapshot.json"))
        let line = HookRunner.run(input: Fixtures.samplePayloadJSON, store: store, now: Fixtures.captured)
        #expect(line == "Fable 5.1 · high · ⛁ 12%")
    }

    @Test func hugeContextPercentageReturnsALineWithoutCrashing() {
        let store = temporaryStore()
        let line = HookRunner.run(
            input: Data(#"{"context_window":{"used_percentage":1e300}}"#.utf8),
            store: store,
            now: Fixtures.captured
        )
        #expect(line == "Claude · ⛁ 1000%")
    }

    @Test func numericEffortLevelStillWritesTheSnapshot() throws {
        let store = temporaryStore()
        let input = Data("""
        {"effort":{"level":3},
         "rate_limits":{"five_hour":{"used_percentage":21,"resets_at":1788617400},
                        "seven_day":{"used_percentage":4,"resets_at":1789160400}}}
        """.utf8)
        let line = HookRunner.run(input: input, store: store, now: Fixtures.captured)
        #expect(line == "Claude · ⛁ --")
        let snapshot = try #require(store.read())
        #expect(snapshot.claude?.fiveHour == UsageWindow(usedPercentage: 21, resetsAt: Fixtures.fiveReset))
    }
}
