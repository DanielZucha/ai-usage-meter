import Foundation

/// The one line the hook prints back to Claude Code's status bar.
public enum StatuslineLine {
    public static let separator = " · "
    public static let unknown = "--"
    public static let fallbackModel = "Claude"

    public static func render(_ payload: StatuslinePayload?) -> String {
        let model = payload?.model?.displayName ?? fallbackModel
        let context = percent(payload?.contextWindow?.usedPercentage)
        let fiveHour = percent(payload?.rateLimits?.fiveHour?.usedPercentage)
        let sevenDay = percent(payload?.rateLimits?.sevenDay?.usedPercentage)
        return [model, "ctx \(context)", "5h \(fiveHour)", "7d \(sevenDay)"].joined(separator: separator)
    }

    static func percent(_ value: Double?) -> String {
        guard let value else { return unknown }
        return "\(max(0, Int(value.rounded())))%"
    }
}
