import Foundation
import Testing
@testable import MeterCore

@Suite struct StatuslineLineTests {
    @Test func rendersModelContextAndBothWindows() throws {
        let payload = try StatuslinePayload.decode(Fixtures.samplePayloadJSON)
        #expect(StatuslineLine.render(payload) == "Fable 5.1 · high · ctx 12% · 5h 21% · 7d 4%")
    }

    @Test func rendersDashesForMissingWindows() throws {
        let payload = try StatuslinePayload.decode(Fixtures.noRateLimitsJSON)
        #expect(StatuslineLine.render(payload) == "Fable 5.1 · ctx 3% · 5h -- · 7d --")
    }

    @Test func omitsEffortWhenAbsent() throws {
        let payload = try StatuslinePayload.decode(Fixtures.noRateLimitsJSON)
        #expect(StatuslineLine.render(payload) == "Fable 5.1 · ctx 3% · 5h -- · 7d --")
    }

    @Test func rendersAnyEffortWord() throws {
        let json = Data(#"{"model":{"display_name":"Opus 4.8"},"effort":{"level":"medium"}}"#.utf8)
        let payload = try StatuslinePayload.decode(json)
        #expect(StatuslineLine.render(payload) == "Opus 4.8 · medium · ctx -- · 5h -- · 7d --")
    }

    @Test func roundsFractionalPercentages() throws {
        let payload = try StatuslinePayload.decode(Fixtures.onlyFiveHourJSON)
        #expect(StatuslineLine.render(payload) == "Opus 4.8 · ctx 41% · 5h 55% · 7d --")
    }

    @Test func fallsBackToClaudeWhenNothingIsKnown() {
        #expect(StatuslineLine.render(nil) == "Claude · ctx -- · 5h -- · 7d --")
    }
}
