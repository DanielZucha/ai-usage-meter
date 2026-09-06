import AppKit
import Foundation
import Observation
import MeterCore

/// Re-reads the snapshot on a 30-second timer and exposes the display
/// state plus the rendered menu-bar label.
@MainActor
@Observable
final class MeterModel {
    static let refreshInterval: TimeInterval = 30

    private(set) var claudeDisplay: MeterDisplay
    private(set) var codexDisplay: MeterDisplay
    private(set) var claudeLabelImage: NSImage
    private(set) var codexLabelImage: NSImage
    private let store: SnapshotStore
    private var timer: Timer?

    init(store: SnapshotStore = .default) {
        self.store = store
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
        self.timer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
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
