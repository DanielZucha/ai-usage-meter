import Foundation
import Testing
@testable import MeterCore

@Suite struct CodexRateLimitsTests {
    let capturedAt = Date(timeIntervalSince1970: 1_788_608_892)

    func decode(_ jsonl: String, responseID: Int64 = 42) -> ProviderUsage? {
        CodexRateLimitsDecoder.providerUsage(
            from: Data(jsonl.utf8),
            responseID: responseID,
            capturedAt: capturedAt
        )
    }

    @Test func namedCodexBucketWinsAndOnlyWeeklyWindowMaps() throws {
        let response = Data("""
        {"id":1,"result":{"userAgent":"ai-usage-meter-tests"}}
        {"id":42,"result":{"rateLimits":{"primary":{"usedPercent":98,"windowDurationMins":300,"resetsAt":1788617460},"secondary":{"usedPercent":97,"windowDurationMins":10080,"resetsAt":1789160460}},"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":4,"windowDurationMins":10080,"resetsAt":1789160400},"secondary":{"usedPercent":21,"windowDurationMins":300,"resetsAt":1788617400}}}}}
        """.utf8)

        let usage = try #require(CodexRateLimitsDecoder.providerUsage(
            from: response,
            responseID: 42,
            capturedAt: capturedAt
        ))

        #expect(usage.fiveHour == nil)
        #expect(usage.sevenDay?.usedPercentage == 4)
        #expect(usage.sevenDay?.resetsAt == Date(timeIntervalSince1970: 1_789_160_400))
        #expect(usage.capturedAt == capturedAt)
        #expect(usage.source == "codex-app-server")
    }

    @Test func aggregateFallbackRequiresCodexLimitID() {
        let cases: [(name: String, rateLimits: String, expectedSevenDay: Int?)] = [
            (
                "codex",
                #"{"limitId":"codex","primary":{"usedPercent":18,"windowDurationMins":10080,"resetsAt":1789160400}}"#,
                18
            ),
            (
                "different limit",
                #"{"limitId":"other","primary":{"usedPercent":19,"windowDurationMins":10080,"resetsAt":1789160400}}"#,
                nil
            ),
            (
                "missing limit",
                #"{"primary":{"usedPercent":20,"windowDurationMins":10080,"resetsAt":1789160400}}"#,
                nil
            ),
        ]

        for testCase in cases {
            let usage = decode(#"{"id":42,"result":{"rateLimits":\#(testCase.rateLimits)}}"#)
            #expect(
                usage?.sevenDay?.usedPercentage == testCase.expectedSevenDay,
                "aggregate case: \(testCase.name)"
            )
            #expect(
                (usage != nil) == (testCase.expectedSevenDay != nil),
                "aggregate case: \(testCase.name)"
            )
        }
    }

    @Test func fiveHourOnlyResponseIsIgnored() {
        let usage = decode("""
        {"id":42,"result":{"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":33,"windowDurationMins":300,"resetsAt":1788617400}}}}}
        """)

        #expect(usage == nil)
    }

    @Test func partialWeeklyResponseKeepsTheAvailableWindow() throws {
        let usage = try #require(decode("""
        {"id":42,"result":{"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":33,"windowDurationMins":10080,"resetsAt":1789160400}}}}}
        """))

        #expect(usage.fiveHour == nil)
        #expect(usage.sevenDay == UsageWindow(
            usedPercentage: 33,
            resetsAt: Date(timeIntervalSince1970: 1_789_160_400)
        ))
        #expect(usage.capturedAt == capturedAt)
        #expect(usage.source == "codex-app-server")
    }

    @Test func unmatchedResponseAndJSONRPCErrorYieldNil() {
        let cases: [(name: String, jsonl: String)] = [
            (
                "unmatched id",
                #"{"id":41,"result":{"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":21,"windowDurationMins":300,"resetsAt":1788617400}}}}}"#
            ),
            (
                "matching error",
                #"{"id":42,"error":{"code":-32603,"message":"rate limits unavailable"}}"#
            ),
        ]

        for testCase in cases {
            #expect(decode(testCase.jsonl) == nil)
        }
    }

    @Test func malformedEarlierLineDoesNotHideLaterMatch() throws {
        let usage = try #require(decode("""
        {not-json}
        {"id":42,"result":{"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":21,"windowDurationMins":300,"resetsAt":1788617400},"secondary":{"usedPercent":4,"windowDurationMins":10080,"resetsAt":1789160400}}}}}
        """))

        #expect(usage.fiveHour == nil)
        #expect(usage.sevenDay?.usedPercentage == 4)
    }

    @Test func invalidWindowsAreRejected() {
        let cases: [(name: String, window: String)] = [
            ("missing usedPercent", #"{"windowDurationMins":10080,"resetsAt":1789160400}"#),
            ("missing duration", #"{"usedPercent":21,"resetsAt":1788617400}"#),
            ("missing reset", #"{"usedPercent":21,"windowDurationMins":10080}"#),
            ("unknown duration", #"{"usedPercent":21,"windowDurationMins":60,"resetsAt":1788617400}"#),
            ("negative percentage", #"{"usedPercent":-1,"windowDurationMins":10080,"resetsAt":1789160400}"#),
            ("fractional percentage", #"{"usedPercent":21.5,"windowDurationMins":10080,"resetsAt":1789160400}"#),
            ("percentage above 100", #"{"usedPercent":101,"windowDurationMins":10080,"resetsAt":1789160400}"#),
            ("non-finite percentage", #"{"usedPercent":1e309,"windowDurationMins":10080,"resetsAt":1789160400}"#),
            ("zero reset", #"{"usedPercent":21,"windowDurationMins":10080,"resetsAt":0}"#),
            ("negative reset", #"{"usedPercent":21,"windowDurationMins":10080,"resetsAt":-1}"#),
        ]

        for testCase in cases {
            let response = #"{"id":42,"result":{"rateLimitsByLimitId":{"codex":{"primary":\#(testCase.window)}}}}"#
            #expect(decode(response) == nil)
        }
    }

    @Test func invalidNamedBucketDoesNotFallBackToAggregate() {
        let usage = decode("""
        {"id":42,"result":{"rateLimits":{"limitId":"codex","primary":{"usedPercent":92,"windowDurationMins":300,"resetsAt":1788617400},"secondary":{"usedPercent":91,"windowDurationMins":10080,"resetsAt":1789160400}},"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":7,"windowDurationMins":60,"resetsAt":1788617400}}}}}
        """)

        #expect(usage == nil)
    }

    @Test func namedMapWithoutCodexDoesNotFallBackToAggregate() {
        let usage = decode("""
        {"id":42,"result":{"rateLimits":{"limitId":"codex","primary":{"usedPercent":92,"windowDurationMins":300,"resetsAt":1788617400}},"rateLimitsByLimitId":{"other":{"primary":{"usedPercent":7,"windowDurationMins":300,"resetsAt":1788617400}}}}}
        """)

        #expect(usage == nil)
    }

    @Test func duplicateRecognizedDurationIsAmbiguous() {
        let usage = decode("""
        {"id":42,"result":{"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":21,"windowDurationMins":10080,"resetsAt":1789160400},"secondary":{"usedPercent":22,"windowDurationMins":10080,"resetsAt":1789160460}}}}}
        """)

        #expect(usage == nil)
    }
}
