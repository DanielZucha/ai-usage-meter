import Foundation
import Testing
@testable import MeterCore

@Suite struct CodexUsagePollerTests {
    func store() -> SnapshotStore {
        SnapshotStore(fileURL: FileManager.default.temporaryDirectory
            .appendingPathComponent("codex-poller-\(UUID().uuidString)/snapshot.json"))
    }

    func usage(_ percentage: Int, reset: Date = Fixtures.sevenReset) -> ProviderUsage {
        ProviderUsage(fiveHour: nil,
                      sevenDay: UsageWindow(usedPercentage: percentage, resetsAt: reset),
                      capturedAt: Fixtures.captured, source: "codex-app-server")
    }

    @Test func refreshesTwelveToEighteenAndRecoversAfterFailure() async throws {
       let store = store()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        let claude = usage(43)
        try store.write(Snapshot(schemaVersion: 1, providers: ["claude": claude, "codex": usage(12)]))
        let fetcher = PollFetcher([nil, usage(18), usage(1, reset: Fixtures.sevenReset.addingTimeInterval(604800))])
        let receipt = Fixtures.captured.addingTimeInterval(60)
        let poller = CodexUsagePoller(store: store, executableResolver: { URL(fileURLWithPath: "/codex") },
                                     fetcher: fetcher, now: { receipt })
        let original = try Data(contentsOf: store.fileURL)
        #expect(await poller.poll() == .unavailable)
        #expect(try Data(contentsOf: store.fileURL) == original)
        #expect(await poller.poll() == .updated)
        #expect(store.read()?.providers["codex"]?.sevenDay?.usedPercentage == 18)
        #expect(store.read()?.providers["codex"]?.capturedAt == receipt)
        #expect(store.read()?.providers["claude"] == claude)
        #expect(await poller.poll() == .updated)
        #expect(store.read()?.providers["codex"]?.sevenDay?.usedPercentage == 1)
    }

    @Test @MainActor func overlappingPollsSkipWithoutBlockingMainActorOrClaudeWriter() async throws {
       let store = store()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        let fetcher = PollFetcher([usage(18)], blocked: true)
        let poller = CodexUsagePoller(store: store, executableResolver: { URL(fileURLWithPath: "/codex") }, fetcher: fetcher)
        let first = Task { await poller.poll() }
        defer { fetcher.release.signal() }
        for _ in 0..<200 where !fetcher.started {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(fetcher.started)
        #expect(!fetcher.ranOnMain)
        #expect(await poller.poll() == .busy)
        let other = CodexUsagePoller(store: store, executableResolver: { URL(fileURLWithPath: "/codex") }, fetcher: fetcher)
        #expect(await other.poll() == .busy)
        try store.withExclusiveLock {
            try store.write(Snapshot(schemaVersion: 1, providers: ["claude": usage(43)]))
        }
        fetcher.release.signal()
        #expect(await first.value == .updated)
        #expect(fetcher.calls == 1)
        #expect(store.read()?.providers["claude"] == usage(43))
    }

    @Test func missingLauncherDoesNotFetchOrAlterSnapshot() async throws {
       let store = store()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        let fetcher = PollFetcher([usage(18)])
        let poller = CodexUsagePoller(store: store, executableResolver: { throw CocoaError(.fileNoSuchFile) }, fetcher: fetcher)
        #expect(await poller.poll() == .unavailable)
        #expect(fetcher.calls == 0)
        #expect(store.read() == nil)
    }

    @Test func timestampsAtReceiptInsteadOfFetchStart() async {
       let store = store()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        let clock = PollClock()
        let fetcher = PollFetcher([usage(18)])
        let poller = CodexUsagePoller(store: store, executableResolver: { URL(fileURLWithPath: "/codex") },
                                     fetcher: fetcher, now: { clock.next() })
        #expect(await poller.poll() == .updated)
        #expect(store.read()?.providers["codex"]?.capturedAt == Fixtures.captured.addingTimeInterval(60))
    }

    @Test func cancellationDuringFetchPreservesSnapshot() async throws {
       let store = store()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        try store.write(Snapshot(schemaVersion: 1, providers: ["codex": usage(12)]))
        let original = try Data(contentsOf: store.fileURL)
        let fetcher = PollFetcher([usage(18)], blocked: true)
        let poller = CodexUsagePoller(store: store, executableResolver: { URL(fileURLWithPath: "/codex") }, fetcher: fetcher)
        let task = Task { await poller.poll() }
        for _ in 0..<200 where !fetcher.started {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(fetcher.started)
        task.cancel()
        fetcher.release.signal()
        #expect(await task.value == .unavailable)
        #expect(try Data(contentsOf: store.fileURL) == original)
    }

    @Test func separateProcessLockSkipsFetch() async throws {
       let store = store()
        defer { try? FileManager.default.removeItem(at: store.fileURL.deletingLastPathComponent()) }
        let directory = store.fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let child = Process()
        let ready = Pipe()
        child.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        child.arguments = ["-e", "open(my $f, '>', $ARGV[0]) or die; flock($f, 2) or die; $|=1; print 'R'; sleep 3;",
                           directory.appendingPathComponent(CodexSnapshotUpdater.pollLockFileName).path]
        child.standardOutput = ready
        child.standardError = FileHandle.nullDevice
        try child.run()
        defer {
            if child.isRunning { child.terminate() }
            child.waitUntilExit()
        }
        #expect(try ready.fileHandleForReading.read(upToCount: 1) == Data("R".utf8))
        let fetcher = PollFetcher([usage(18)])
        let poller = CodexUsagePoller(store: store, executableResolver: { URL(fileURLWithPath: "/codex") }, fetcher: fetcher)
        #expect(await poller.poll() == .busy)
        #expect(fetcher.calls == 0)
    }
}

private final class PollClock: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    func next() -> Date {
        lock.withLock {
            defer { count += 1 }
            return Fixtures.captured.addingTimeInterval(Double(count) * 60)
        }
    }
}

private final class PollFetcher: CodexUsageFetching, @unchecked Sendable {
    private let lock = NSLock()
    private var responses: [ProviderUsage?]
    private var count = 0
    private var main = false
    private let blocked: Bool
    let release = DispatchSemaphore(value: 0)
    var calls: Int { lock.withLock { count } }
    var started: Bool { calls > 0 }
    var ranOnMain: Bool { lock.withLock { main } }

    init(_ responses: [ProviderUsage?], blocked: Bool = false) {
        self.responses = responses
        self.blocked = blocked
    }

    func fetchUsage(executableURL: URL, capturedAt: Date) throws -> ProviderUsage? {
        let response = lock.withLock {
            count += 1
            main = Thread.isMainThread
            return responses.removeFirst()
        }
        if blocked { _ = release.wait(timeout: .now() + 3) }
        return response
    }
}
