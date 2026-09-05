import AppKit
import MeterCore

/// Draws the whole menu-bar label (glyph, gap, two numbers) as one image.
/// Normal state: black content marked as a template, so the bar tints it.
/// Flipped state: a white rounded background at half alpha with black
/// glyph and text, not a template, so the colors survive.
@MainActor
enum LabelImage {
    static let height: CGFloat = 22
    static let glyphSize: CGFloat = 15
    static let gap: CGFloat = 6
    static let horizontalPadding: CGFloat = 5
    static let cornerRadius: CGFloat = 6
    static let flippedBackgroundAlpha: CGFloat = 0.5

    static let glyph: NSImage = {
        let image = NSImage(data: Data(ClaudeGlyph.svg.utf8)) ?? NSImage(size: .zero)
        image.size = NSSize(width: glyphSize, height: glyphSize)
        return image
    }()

    static func make(_ display: MeterDisplay) -> NSImage {
        let text = attributedText(display)
        let textSize = text.size()
        let width = horizontalPadding + glyphSize + gap + ceil(textSize.width) + horizontalPadding
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { bounds in
            if display.isFlipped {
                NSColor.white.withAlphaComponent(flippedBackgroundAlpha).setFill()
                NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius).fill()
            }
            let glyphRect = NSRect(x: horizontalPadding, y: (height - glyphSize) / 2,
                                   width: glyphSize, height: glyphSize)
            glyph.draw(in: glyphRect, from: .zero, operation: .sourceOver, fraction: 1)
            let textOrigin = NSPoint(x: horizontalPadding + glyphSize + gap,
                                     y: (height - textSize.height) / 2)
            text.draw(at: textOrigin)
            return true
        }
        image.isTemplate = !display.isFlipped
        return image
    }

    static func attributedText(_ display: MeterDisplay) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(number(display.fiveHour))
        result.append(NSAttributedString(string: " · ", attributes: attributes(bold: false)))
        result.append(number(display.sevenDay))
        return result
    }

    static func number(_ window: WindowDisplay) -> NSAttributedString {
        NSAttributedString(string: window.percentText, attributes: attributes(bold: window.isBold))
    }

    static func attributes(bold: Bool) -> [NSAttributedString.Key: Any] {
        let base = NSFont.menuBarFont(ofSize: 0)
        let font = bold ? NSFontManager.shared.convert(base, toHaveTrait: .boldFontMask) : base
        return [.font: font, .foregroundColor: NSColor.black]
    }
}
