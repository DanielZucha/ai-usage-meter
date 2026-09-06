import Foundation

public enum CodexPollOutcome: Equatable, Sendable {
    case updated
    case unavailable
    case busy
}

/// Keeps process work off the UI actor and drops overlapping refresh requests.
public actor CodexUsagePoller {
    private let store: SnapshotStore
    private let executableResolver: @Sendable () throws -> URL
    private let fetcher: any CodexUsageFetching
    private let now: @Sendable () -> Date
    private var busy = false

    public init(
        store: SnapshotStore = .default,
        executableResolver: @escaping @Sendable () throws -> URL,
        fetcher: any CodexUsageFetching = CodexRateLimitsClient(),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.store = store
        self.executableResolver = executableResolver
        self.fetcher = fetcher
        self.now = now
    }

    public func poll() async -> CodexPollOutcome {
        guard !busy else { return .busy }
        busy = true
        defer { busy = false }
        let task = Task.detached(priority: .utility) { [store, executableResolver, fetcher, now] in
            guard !Task.isCancelled, let executable = try? executableResolver() else {
                return CodexPollOutcome.unavailable
            }
            return CodexSnapshotUpdater.run(executableURL: executable, store: store, now: now, fetcher: fetcher)
        }
        return await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }
}
