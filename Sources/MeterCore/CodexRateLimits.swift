import Foundation

/// Decodes the narrow subset of Codex App Server responses needed by the
/// meter. Account metadata and all conversation data stay outside this type.
public enum CodexRateLimitsDecoder {
    public static let source = "codex-app-server"

    public static func providerUsage(
        from data: Data,
        responseID: Int64,
        capturedAt: Date
    ) -> ProviderUsage? {
        for line in data.split(separator: 0x0A) {
            guard let envelope = try? JSONDecoder().decode(ResponseEnvelope.self, from: Data(line)),
                  envelope.id == responseID,
                  let result = envelope.result else { continue }
            let limits: RateLimits?
            if let namedLimits = result.rateLimitsByLimitID {
                limits = namedLimits[Snapshot.codexProviderID]
            } else if result.rateLimits?.limitID == Snapshot.codexProviderID {
                limits = result.rateLimits
            } else {
                limits = nil
            }
            guard let limits else { return nil }
            return makeUsage(from: limits, capturedAt: capturedAt)
        }
        return nil
    }

    private static func makeUsage(from limits: RateLimits, capturedAt: Date) -> ProviderUsage? {
        var sevenDay: UsageWindow?
        for window in [limits.primary, limits.secondary].compactMap({ $0 }) {
            guard let usage = window.usageWindow else { continue }
            switch (window.windowDurationMins, sevenDay) {
            case (10_080, nil): sevenDay = usage
            case (10_080, .some): return nil
            default: continue
            }
        }
        guard sevenDay != nil else { return nil }
        return ProviderUsage(
            fiveHour: nil,
            sevenDay: sevenDay,
            capturedAt: capturedAt,
            source: source
        )
    }
}

private struct ResponseEnvelope: Decodable {
    let id: Int64?
    let result: RateLimitsResult?
}

private struct RateLimitsResult: Decodable {
    let rateLimits: RateLimits?
    let rateLimitsByLimitID: [String: RateLimits]?

    enum CodingKeys: String, CodingKey {
        case rateLimits
        case rateLimitsByLimitID = "rateLimitsByLimitId"
    }
}

private struct RateLimits: Decodable {
    let limitID: String?
    let primary: RateLimitWindow?
    let secondary: RateLimitWindow?

    enum CodingKeys: String, CodingKey {
        case limitID = "limitId"
        case primary
        case secondary
    }
}

private struct RateLimitWindow: Decodable {
    let usedPercent: Int?
    let windowDurationMins: Int?
    let resetsAt: Int64?

    var usageWindow: UsageWindow? {
        guard let usedPercent,
              (0...100).contains(usedPercent),
              let resetsAt,
              resetsAt > 0 else { return nil }
        return UsageWindow(
            usedPercentage: usedPercent,
            resetsAt: Date(timeIntervalSince1970: TimeInterval(resetsAt))
        )
    }
}
