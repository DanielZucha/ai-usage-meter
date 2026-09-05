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

    private(set) var display: MeterDisplay
    private(set) var labelImage: NSImage
    private let store: SnapshotStore
    private var timer: Timer?

    init(store: SnapshotStore = .default) {
        self.store = store
        let display = MeterDisplay.make(snapshot: store.read(), now: Date())
        self.display = display
        self.labelImage = LabelImage.make(display)
        self.timer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        display = MeterDisplay.make(snapshot: store.read(), now: Date())
        labelImage = LabelImage.make(display)
    }
}
