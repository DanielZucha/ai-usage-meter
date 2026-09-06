import AppKit
import Foundation
import Observation
import MeterCore

/// Fetches Codex usage and rereads both providers on a 30-second timer.
@MainActor
@Observable
final class MeterModel {
    static let refreshInterval: TimeInterval = 30

    private(set) var claudeDisplay: MeterDisplay
    private(set) var codexDisplay: MeterDisplay
    private(set) var claudeLabelImage: NSImage
    private(set) var codexLabelImage: NSImage
    private(set) var codexRefreshUnavailable = false
    private let store: SnapshotStore
    private let poll: @Sendable () async -> CodexPollOutcome
    private var timer: Timer?

    init(
        store: SnapshotStore = .default,
        poll: (@Sendable () async -> CodexPollOutcome)? = nil,
        schedule: @MainActor (TimeInterval, @escaping @MainActor @Sendable () -> Void) -> Timer? = MeterModel.schedule
    ) {
        self.store = store
        let poller = CodexUsagePoller(store: store, executableResolver: { try CodexLauncher.load() })
        self.poll = poll ?? { await poller.poll() }
        let snapshot = store.read()
        let now = Date()
        let claudeDisplay = MeterDisplay.make(
            snapshot: snapshot,
            providerID: Snapshot.claudeProviderID,
            now: now
        )
        let codexDisplay = MeterDisplay.make(
            snapshot: snapshot,
            providerID: Snapshot.codexProviderID,
            now: now
        )
        self.claudeDisplay = claudeDisplay
        self.codexDisplay = codexDisplay
        self.claudeLabelImage = LabelImage.make(claudeDisplay, glyph: LabelImage.claudeGlyph)
        self.codexLabelImage = LabelImage.make(codexDisplay, glyph: LabelImage.codexGlyph)
        self.timer = schedule(Self.refreshInterval) { [weak self] in
            Task { await self?.refresh() }
        }
        Task { [weak self] in await self?.refresh() }
    }

    func refresh() async {
        readSnapshot()
        let outcome = await poll()
        switch outcome {
        case .updated: codexRefreshUnavailable = false
        case .unavailable: codexRefreshUnavailable = true
        case .busy: break
        }
        readSnapshot()
    }

    private static func schedule(
        interval: TimeInterval, tick: @escaping @MainActor @Sendable () -> Void
    ) -> Timer? {
        let timer = Timer(timeInterval: interval, repeats: true) { _ in
            Task { @MainActor in tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }

    private func readSnapshot() {
        let snapshot = store.read()
        let now = Date()
        claudeDisplay = MeterDisplay.make(
            snapshot: snapshot,
            providerID: Snapshot.claudeProviderID,
            now: now
        )
        codexDisplay = MeterDisplay.make(
            snapshot: snapshot,
            providerID: Snapshot.codexProviderID,
            now: now
        )
        claudeLabelImage = LabelImage.make(claudeDisplay, glyph: LabelImage.claudeGlyph)
        codexLabelImage = LabelImage.make(codexDisplay, glyph: LabelImage.codexGlyph)
    }
}
