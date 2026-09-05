import AppKit
import MeterCore

/// Template images so the glyph follows the menu bar's light or dark tint.
@MainActor
enum GlyphImage {
    static let pointSize: CGFloat = 16

    static let filled = make(ClaudeGlyph.svg(filled: true))
    static let outline = make(ClaudeGlyph.svg(filled: false))

    static func make(_ svg: String) -> NSImage {
        let image = NSImage(data: Data(svg.utf8)) ?? NSImage(size: NSSize(width: pointSize, height: pointSize))
        image.isTemplate = true
        image.size = NSSize(width: pointSize, height: pointSize)
        return image
    }
}
