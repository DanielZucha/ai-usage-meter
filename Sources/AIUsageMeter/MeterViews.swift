import SwiftUI
import MeterCore

/// What sits in the menu bar: glyph, then the two percentages.
struct MeterLabel: View {
    let display: MeterDisplay

    var body: some View {
        HStack(spacing: 4) {
            Image(nsImage: display.glyphFilled ? GlyphImage.filled : GlyphImage.outline)
            number(display.fiveHour) + Text(" · ") + number(display.sevenDay)
        }
    }

    private func number(_ window: WindowDisplay) -> Text {
        Text(window.percentText).fontWeight(window.isBold ? .bold : .regular)
    }
}

/// The dropdown: one row per window, the snapshot age, Quit.
struct MeterMenu: View {
    let display: MeterDisplay

    var body: some View {
        Text(display.fiveHour.rowText)
        Text(display.sevenDay.rowText)
        Divider()
        Text(display.ageText)
        Divider()
        Button("Quit AI Usage Meter") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
