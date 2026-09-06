import Foundation
import Testing
import MeterCore
@testable import AIUsageMeter

@Suite @MainActor struct MeterModelTests {
    @Test func launchAndTimerFetchFreshUsageWithoutWaitingThirtySeconds() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SnapshotStore(fileURL: directory.appendingPathComponent("snapshot.json"))
        let recorder = PollRecorder(store: store)
        let timer = ManualTimer()
        let model = MeterModel(store: store, poll: { await recorder.poll() }, schedule: timer.schedule)
        for _ in 0..<10_000 {
            if model.codexDisplay.sevenDay.percent == 18 { break }
            await Task.yield()
        }
        #expect(model.codexDisplay.sevenDay.percent == 18)
        #expect(timer.interval == 30)
        timer.tick?()
        for _ in 0..<10_000 {
            if model.codexDisplay.sevenDay.percent == 19 { break }
            await Task.yield()
        }
        #expect(model.codexDisplay.sevenDay.percent == 19)
        #expect(await recorder.count == 2)
    }

    @Test func failedRefreshShowsUnavailableAndRetainsSnapshot() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SnapshotStore(fileURL: directory.appendingPathComponent("snapshot.json"))
        let recorder = PollRecorder(store: store)
        _ = await recorder.poll()
        let original = try Data(contentsOf: store.fileURL)
        let model = MeterModel(store: store, poll: { .unavailable }, schedule: { _, _ in nil })
        await model.refresh()
        #expect(model.codexRefreshUnavailable)
        #expect(model.codexDisplay.sevenDay.percent == 18)
        #expect(try Data(contentsOf: store.fileURL) == original)
    }
}

@MainActor private final class ManualTimer {
    var interval: TimeInterval?
    var tick: (@MainActor @Sendable () -> Void)?
    func schedule(interval: TimeInterval, tick: @escaping @MainActor @Sendable () -> Void) -> Timer? {
        self.interval = interval
        self.tick = tick
        return nil
    }
}

private actor PollRecorder {
    let store: SnapshotStore
    var count = 0
    init(store: SnapshotStore) { self.store = store }
    func poll() -> CodexPollOutcome {
        count += 1
        let usage = ProviderUsage(fiveHour: nil,
            sevenDay: UsageWindow(usedPercentage: 17 + count, resetsAt: Date().addingTimeInterval(86_400)),
            capturedAt: Date(), source: "codex-app-server")
        do {
            try store.write(Snapshot(schemaVersion: 1, providers: [Snapshot.codexProviderID: usage]))
            return .updated
        } catch { return .unavailable }
    }
}
