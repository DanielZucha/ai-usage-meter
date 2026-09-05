import Foundation
import Testing
@testable import MeterCore

@Suite struct StatuslineLineTests {
    @Test func rendersModelContextAndBothWindows() throws {
        let payload = try StatuslinePayload.decode(Fixtures.samplePayloadJSON)
        #expect(StatuslineLine.render(payload) == "Fable 5.1 · high · ⛁ 12%")
    }

    @Test func rendersDashesForMissingWindows() throws {
        let payload = try StatuslinePayload.decode(Fixtures.noRateLimitsJSON)
        #expect(StatuslineLine.render(payload) == "Fable 5.1 · ⛁ 3%")
    }

    @Test func omitsEffortWhenAbsent() throws {
        let payload = try StatuslinePayload.decode(Fixtures.noRateLimitsJSON)
        #expect(StatuslineLine.render(payload) == "Fable 5.1 · ⛁ 3%")
    }

    @Test func rendersAnyEffortWord() throws {
        let json = Data(#"{"model":{"display_name":"Opus 4.8"},"effort":{"level":"medium"}}"#.utf8)
        let payload = try StatuslinePayload.decode(json)
        #expect(StatuslineLine.render(payload) == "Opus 4.8 · medium · ⛁ --")
    }

    @Test func roundsFractionalPercentages() throws {
        let payload = try StatuslinePayload.decode(Fixtures.onlyFiveHourJSON)
        #expect(StatuslineLine.render(payload) == "Opus 4.8 · ⛁ 41%")
    }

    @Test func fallsBackToClaudeWhenNothingIsKnown() {
        #expect(StatuslineLine.render(nil) == "Claude · ⛁ --")
    }

    @Test func contextGlyphIsTheDraughtsKing() {
        #expect(StatuslineLine.contextGlyph == "\u{26C1}")
    }
}
