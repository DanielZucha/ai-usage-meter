import Foundation

/// The subset of Claude Code's statusline stdin JSON this project reads.
/// Every field is optional: the contract says windows come and go, and the
/// hook must survive anything on stdin.
public struct StatuslinePayload: Decodable, Sendable {
    public struct Model: Decodable, Sendable {
        public var displayName: String?
        enum CodingKeys: String, CodingKey { case displayName = "display_name" }
    }

    public struct Effort: Decodable, Sendable {
        public var level: String?
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
    public var effort: Effort?
    public var contextWindow: ContextWindow?
    public var rateLimits: RateLimits?

    enum CodingKeys: String, CodingKey {
        case model
        case effort
        case contextWindow = "context_window"
        case rateLimits = "rate_limits"
    }

    /// Hand-written so one field's type change (upstream) cannot fail the
    /// whole payload: each top-level key decodes independently, and a
    /// throw on one leaves the rest intact instead of degrading the line.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        model = try? container.decodeIfPresent(Model.self, forKey: .model)
        effort = try? container.decodeIfPresent(Effort.self, forKey: .effort)
        contextWindow = try? container.decodeIfPresent(ContextWindow.self, forKey: .contextWindow)
        rateLimits = try? container.decodeIfPresent(RateLimits.self, forKey: .rateLimits)
    }

    public static let source = "statusline"

    public static func decode(_ data: Data) throws -> StatuslinePayload {
        try JSONDecoder().decode(StatuslinePayload.self, from: data)
    }

    /// Nil when the payload carries no `rate_limits` block, or one with no
    /// usable window: either way nothing arrived, so the stored snapshot and
    /// its `captured_at` must stand rather than read as freshly updated.
    public func providerUsage(capturedAt: Date) -> ProviderUsage? {
        guard let rateLimits else { return nil }
        let fiveHour = Self.window(from: rateLimits.fiveHour)
        let sevenDay = Self.window(from: rateLimits.sevenDay)
        guard fiveHour != nil || sevenDay != nil else { return nil }
        return ProviderUsage(
            fiveHour: fiveHour,
            sevenDay: sevenDay,
            capturedAt: capturedAt,
            source: Self.source
        )
    }

    private static func window(from raw: RateWindow?) -> UsageWindow? {
        guard let raw, let used = raw.usedPercentage, let reset = raw.resetsAt,
              let percentage = clampedInt(used) else { return nil }
        return UsageWindow(
            usedPercentage: percentage,
            resetsAt: Date(timeIntervalSince1970: reset)
        )
    }
}
