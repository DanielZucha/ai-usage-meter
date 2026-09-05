import Foundation

/// The one line the hook prints back to Claude Code's status bar.
public enum StatuslineLine {
    public static let separator = " · "
    public static let unknown = "--"
    public static let fallbackModel = "Claude"

    /// U+26C1, the stacked-cylinder symbol Claude Code's /context grid uses.
    public static let contextGlyph = "\u{26C1}"

    public static func render(_ payload: StatuslinePayload?) -> String {
        let model = payload?.model?.displayName ?? fallbackModel
        let effort = payload?.effort?.level
        let context = percent(payload?.contextWindow?.usedPercentage)
        return ([model] + (effort.map { [$0] } ?? []) + ["\(contextGlyph) \(context)"])
            .joined(separator: separator)
    }

    static func percent(_ value: Double?) -> String {
        guard let value else { return unknown }
        return "\(max(0, Int(value.rounded())))%"
    }
}
