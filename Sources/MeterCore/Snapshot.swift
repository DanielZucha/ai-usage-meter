import Foundation

/// One rate-limit window as reported by a provider.
public struct UsageWindow: Codable, Equatable, Sendable {
    public var usedPercentage: Int
    public var resetsAt: Date

    public init(usedPercentage: Int, resetsAt: Date) {
        self.usedPercentage = usedPercentage
        self.resetsAt = resetsAt
    }

    enum CodingKeys: String, CodingKey {
        case usedPercentage = "used_percentage"
        case resetsAt = "resets_at"
    }
}

/// Everything the snapshot knows about one provider.
public struct ProviderUsage: Codable, Equatable, Sendable {
    public var fiveHour: UsageWindow?
    public var sevenDay: UsageWindow?
    public var capturedAt: Date
    public var source: String

    public init(fiveHour: UsageWindow?, sevenDay: UsageWindow?, capturedAt: Date, source: String) {
        self.fiveHour = fiveHour
        self.sevenDay = sevenDay
        self.capturedAt = capturedAt
        self.source = source
    }

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case capturedAt = "captured_at"
        case source
    }
}

/// The on-disk document. Provider-keyed so a second provider is an added key.
public struct Snapshot: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public static let claudeProviderID = "claude"

    public var schemaVersion: Int
    public var providers: [String: ProviderUsage]

    public init(schemaVersion: Int, providers: [String: ProviderUsage]) {
        self.schemaVersion = schemaVersion
        self.providers = providers
    }

    public var claude: ProviderUsage? {
        get { providers[Self.claudeProviderID] }
        set { providers[Self.claudeProviderID] = newValue }
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case providers
    }
}

/// The single JSON configuration for the snapshot file.
public enum SnapshotCoding {
    public static func encode(_ snapshot: Snapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(snapshot)
    }

    public static func decode(_ data: Data) throws -> Snapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Snapshot.self, from: data)
    }
}
