import Foundation
import Testing
@testable import MeterCore

@Suite struct DisplayStateTests {
    let now = Date(timeIntervalSince1970: 1_788_608_892)

    func snapshot(five: Int?, seven: Int?, capturedAgo: TimeInterval = 120) -> Snapshot {
        Snapshot(schemaVersion: 1, providers: [
            "claude": ProviderUsage(
                fiveHour: five.map { UsageWindow(usedPercentage: $0, resetsAt: Fixtures.fiveReset) },
                sevenDay: seven.map { UsageWindow(usedPercentage: $0, resetsAt: Fixtures.sevenReset) },
                capturedAt: now.addingTimeInterval(-capturedAgo),
                source: "statusline")
        ])
    }

    @Test func normalStateIsPlain() {
        let display = MeterDisplay.make(snapshot: snapshot(five: 42, seven: 18), now: now)
        #expect(display.barText == "42% · 18%")
        #expect(display.fiveHour.isBold == false)
        #expect(display.sevenDay.isBold == false)
        #expect(display.glyphFilled == false)
        #expect(display.fiveHour.rowText == "5-hour  42% · resets in 2h 21m")
        #expect(display.sevenDay.rowText == "7-day  18% · resets in 6d 09h")
        #expect(display.ageText == "Updated 2 min ago · statusline")
    }

    @Test func seventyBoldsOnlyTheAffectedNumber() {
        let display = MeterDisplay.make(snapshot: snapshot(five: 70, seven: 69), now: now)
        #expect(display.fiveHour.isBold == true)
        #expect(display.sevenDay.isBold == false)
        #expect(display.glyphFilled == false)
    }

    @Test func ninetyFillsTheGlyph() {
        let display = MeterDisplay.make(snapshot: snapshot(five: 12, seven: 90), now: now)
        #expect(display.glyphFilled == true)
        #expect(display.sevenDay.isBold == true)
    }

    @Test func passedResetShowsZero() {
        let afterFiveHourReset = Fixtures.fiveReset.addingTimeInterval(60)
        let display = MeterDisplay.make(snapshot: snapshot(five: 95, seven: 40), now: afterFiveHourReset)
        #expect(display.fiveHour.percent == 0)
        #expect(display.fiveHour.percentText == "0%")
        #expect(display.fiveHour.isBold == false)
        #expect(display.fiveHour.rowText == "5-hour  0% · reset")
        #expect(display.glyphFilled == false)
        #expect(display.sevenDay.percent == 40)
    }

    @Test func absentWindowShowsDashes() {
        let display = MeterDisplay.make(snapshot: snapshot(five: 42, seven: nil), now: now)
        #expect(display.barText == "42% · --")
        #expect(display.sevenDay.percent == nil)
        #expect(display.sevenDay.rowText == "7-day  --")
    }

    @Test func noSnapshotShowsDashesAndNoAge() {
        let display = MeterDisplay.make(snapshot: nil, now: now)
        #expect(display.barText == "-- · --")
        #expect(display.glyphFilled == false)
        #expect(display.ageText == "No snapshot yet")
    }
}
