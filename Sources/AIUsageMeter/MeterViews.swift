import AppKit
import SwiftUI
import MeterCore

/// What sits in the menu bar: the pre-rendered label image.
struct MeterLabel: View {
    let image: NSImage

    var body: some View {
        Image(nsImage: image)
    }
}

/// The dropdown panel: one row per window with a pill bar, the snapshot
/// age, Quit.
struct MeterMenu: View {
    static let width: CGFloat = 260

    let display: MeterDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(display.visibleWindows.indices, id: \.self) { index in
                WindowRow(window: display.visibleWindows[index])
            }
            Divider()
            Text(display.ageText)
                .foregroundStyle(.secondary)
            Divider()
            Button("Quit AI Usage Meter") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: Self.width)
    }
}

struct WindowRow: View {
    let window: WindowDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(window.rowText)
                .fontWeight(window.isBold ? .bold : .regular)
            PillBar(fraction: window.fraction)
        }
    }
}

/// A capsule track with a filled capsule on top. `.primary` is white in
/// the dark appearance and black in the light one, so the bar always
/// contrasts with the panel.
struct PillBar: View {
    static let height: CGFloat = 6
    static let trackOpacity = 0.2

    let fraction: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.primary.opacity(Self.trackOpacity))
                Capsule().fill(.primary)
                    .frame(width: geometry.size.width * fraction)
            }
        }
        .frame(height: Self.height)
    }
}
