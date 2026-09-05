import Foundation

/// The subset of Claude Code's statusline stdin JSON this project reads.
/// Every field is optional: the contract says windows come and go, and the
/// hook must survive anything on stdin.
public struct StatuslinePayload: Decodable, Sendable {
    public struct Model: Decodable, Sendable {
        public var displayName: String?
        enum CodingKeys: String, CodingKey { case displayName = "display_name" }
    }

    public struct ContextWindow: Decodable, Sendable {
        public var usedPercentage: Double?
        enum CodingKeys: String, CodingKey { case usedPercentage = "used_percentage" }
    }

    public struct RateWindow: Decodable, Sendable {
        public var usedPercentage: Double?
        /// Unix epoch seconds, as Claude Code sends it.
        public var resetsAt: Double?
        enum CodingKeys: String, CodingKey {
            case usedPercentage = "used_percentage"
            case resetsAt = "resets_at"
        }
    }

    public struct RateLimits: Decodable, Sendable {
        public var fiveHour: RateWindow?
        public var sevenDay: RateWindow?
        enum CodingKeys: String, CodingKey {
            case fiveHour = "five_hour"
            case sevenDay = "seven_day"
        }
    }

    public var model: Model?
    public var contextWindow: ContextWindow?
    public var rateLimits: RateLimits?

    enum CodingKeys: String, CodingKey {
        case model
        case contextWindow = "context_window"
        case rateLimits = "rate_limits"
    }

    public static let source = "statusline"

    public static func decode(_ data: Data) throws -> StatuslinePayload {
        try JSONDecoder().decode(StatuslinePayload.self, from: data)
    }

    /// Nil when the payload carries no `rate_limits` block at all.
    public func providerUsage(capturedAt: Date) -> ProviderUsage? {
        guard let rateLimits else { return nil }
        return ProviderUsage(
            fiveHour: Self.window(from: rateLimits.fiveHour),
            sevenDay: Self.window(from: rateLimits.sevenDay),
            capturedAt: capturedAt,
            source: Self.source
        )
    }

    private static func window(from raw: RateWindow?) -> UsageWindow? {
        guard let raw, let used = raw.usedPercentage, let reset = raw.resetsAt else { return nil }
        return UsageWindow(
            usedPercentage: max(0, Int(used.rounded())),
            resetsAt: Date(timeIntervalSince1970: reset)
        )
    }
}
