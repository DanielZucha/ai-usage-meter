import Foundation

/// The one line the hook prints back to Claude Code's status bar.
public enum StatuslineLine {
    public static let separator = MeterDisplay.separator
    public static let unknown = "--"
    public static let fallbackModel = "Claude"

    /// U+26C1, the stacked-cylinder symbol Claude Code's /context grid uses.
    public static let contextGlyph = "\u{26C1}"

    public static func render(_ payload: StatuslinePayload?) -> String {
        let model = payload?.model?.displayName.flatMap { $0.isEmpty ? nil : $0 } ?? fallbackModel
        let effort = payload?.effort?.level
        let context = percent(payload?.contextWindow?.usedPercentage)
        let line = ([model] + (effort.map { [$0] } ?? []) + ["\(contextGlyph) \(context)"])
            .joined(separator: separator)
        return line.replacingOccurrences(of: "\r", with: " ").replacingOccurrences(of: "\n", with: " ")
    }

    static func percent(_ value: Double?) -> String {
        guard let value, let clamped = clampedInt(value) else { return unknown }
        return "\(clamped)%"
    }
}
