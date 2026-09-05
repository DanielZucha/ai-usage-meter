import Foundation
import Testing
@testable import MeterCore

@Suite struct SnapshotCodingTests {
    let fiveReset = Date(timeIntervalSince1970: 1_788_617_400)
    let sevenReset = Date(timeIntervalSince1970: 1_789_160_400)
    let captured = Date(timeIntervalSince1970: 1_788_608_892)

    func sample() -> Snapshot {
        Snapshot(
            schemaVersion: Snapshot.currentSchemaVersion,
            providers: [
                Snapshot.claudeProviderID: ProviderUsage(
                    fiveHour: UsageWindow(usedPercentage: 21, resetsAt: fiveReset),
                    sevenDay: UsageWindow(usedPercentage: 4, resetsAt: sevenReset),
                    capturedAt: captured,
                    source: "statusline"
                )
            ]
        )
    }

    @Test func roundTripsThroughJSON() throws {
        let data = try SnapshotCoding.encode(sample())
        let decoded = try SnapshotCoding.decode(data)
        #expect(decoded == sample())
    }

    @Test func usesSnakeCaseKeysAndISO8601Dates() throws {
        let json = String(decoding: try SnapshotCoding.encode(sample()), as: UTF8.self)
        for key in ["schema_version", "providers", "five_hour", "seven_day", "used_percentage", "resets_at", "captured_at", "source"] {
            #expect(json.contains("\"\(key)\""), "missing key \(key)")
        }
        #expect(!json.contains("schemaVersion"))
        #expect(json.contains("2026-09-05T14:10:00Z"))
        #expect(json.contains("2026-09-05T11:48:12Z"))
        #expect(!json.contains("1788617400"))
    }

    @Test func absentWindowIsAbsentNotZero() throws {
        var snapshot = sample()
        snapshot.claude?.sevenDay = nil
        let json = String(decoding: try SnapshotCoding.encode(snapshot), as: UTF8.self)
        #expect(!json.contains("seven_day"))
        let decoded = try SnapshotCoding.decode(Data(json.utf8))
        #expect(decoded.claude?.sevenDay == nil)
        #expect(decoded.claude?.fiveHour?.usedPercentage == 21)
    }

    @Test func claudeAccessorReadsAndWritesTheProviderMap() {
        var snapshot = Snapshot(schemaVersion: 1, providers: [:])
        #expect(snapshot.claude == nil)
        snapshot.claude = sample().claude
        #expect(snapshot.providers.keys.sorted() == ["claude"])
    }
}
