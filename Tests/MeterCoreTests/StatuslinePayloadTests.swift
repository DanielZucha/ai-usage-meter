import Foundation
import Testing
@testable import MeterCore

@Suite struct StatuslinePayloadTests {
    @Test func decodesTheRealCapture() throws {
        let payload = try StatuslinePayload.decode(Fixtures.samplePayloadJSON)
        #expect(payload.model?.displayName == "Fable 5.1")
        #expect(payload.effort?.level == "high")
        #expect(payload.contextWindow?.usedPercentage == 12)
        #expect(payload.rateLimits?.fiveHour?.usedPercentage == 21)
        #expect(payload.rateLimits?.fiveHour?.resetsAt == 1_788_617_400)
        #expect(payload.rateLimits?.sevenDay?.usedPercentage == 4)
    }

    @Test func toleratesMissingRateLimits() throws {
        let payload = try StatuslinePayload.decode(Fixtures.noRateLimitsJSON)
        #expect(payload.rateLimits == nil)
        #expect(payload.providerUsage(capturedAt: Fixtures.captured) == nil)
    }

    @Test func toleratesAnEmptyObject() throws {
        let payload = try StatuslinePayload.decode(Data("{}".utf8))
        #expect(payload.model == nil)
        #expect(payload.contextWindow == nil)
        #expect(payload.rateLimits == nil)
    }

    @Test func rejectsNonJSON() {
        #expect(throws: (any Error).self) {
            try StatuslinePayload.decode(Data("not json".utf8))
        }
    }

    @Test func convertsToProviderUsageWithEpochDatesAndRounding() throws {
        let payload = try StatuslinePayload.decode(Fixtures.onlyFiveHourJSON)
        let usage = try #require(payload.providerUsage(capturedAt: Fixtures.captured))
        #expect(usage.fiveHour == UsageWindow(usedPercentage: 55, resetsAt: Fixtures.fiveReset))
        #expect(usage.sevenDay == nil)
        #expect(usage.capturedAt == Fixtures.captured)
        #expect(usage.source == "statusline")
    }

    @Test func dropsAWindowMissingEitherField() throws {
        let json = Data("""
        {"rate_limits":{"five_hour":{"used_percentage":10},"seven_day":{"used_percentage":4,"resets_at":1789160400}}}
        """.utf8)
        let usage = try #require(try StatuslinePayload.decode(json).providerUsage(capturedAt: Fixtures.captured))
        #expect(usage.fiveHour == nil)
        #expect(usage.sevenDay?.usedPercentage == 4)
    }

    @Test func rateLimitsWithNoUsableWindowIsNoUsage() throws {
        let json = Data("""
        {"rate_limits":{"five_hour":{"used_percentage":10},"seven_day":{"resets_at":1789160400}}}
        """.utf8)
        #expect(try StatuslinePayload.decode(json).providerUsage(capturedAt: Fixtures.captured) == nil)
    }

    @Test func hugePercentageIsClampedNotTrapped() throws {
        let json = Data("""
        {"rate_limits":{"five_hour":{"used_percentage":1e300,"resets_at":1788617400}}}
        """.utf8)
        let payload = try StatuslinePayload.decode(json)
        let usage = payload.providerUsage(capturedAt: Fixtures.captured)
        #expect(usage?.fiveHour?.usedPercentage == 1_000)
    }

    @Test func numericEffortLevelDoesNotBlockRateLimitsDecoding() throws {
        let json = Data("""
        {"effort":{"level":3},
         "rate_limits":{"five_hour":{"used_percentage":21,"resets_at":1788617400}}}
        """.utf8)
        let payload = try StatuslinePayload.decode(json)
        #expect(payload.effort?.level == nil)
        #expect(payload.rateLimits?.fiveHour?.usedPercentage == 21)
    }
}
