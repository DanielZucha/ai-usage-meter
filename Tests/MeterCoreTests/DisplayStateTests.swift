import Foundation
import Testing
@testable import MeterCore

@Suite struct DisplayStateTests {
    let now = Date(timeIntervalSince1970: 1_788_608_892)

    func snapshot(five: Int?, seven: Int?, capturedAgo: TimeInterval = 120) -> Snapshot {
        Snapshot(schemaVersion: 1, providers: [
            Snapshot.claudeProviderID: ProviderUsage(
                fiveHour: five.map { UsageWindow(usedPercentage: $0, resetsAt: Fixtures.fiveReset) },
                sevenDay: seven.map { UsageWindow(usedPercentage: $0, resetsAt: Fixtures.sevenReset) },
                capturedAt: now.addingTimeInterval(-capturedAgo),
                source: "statusline")
        ])
    }

    @Test func normalStateIsPlain() {
        let display = MeterDisplay.make(
            snapshot: snapshot(five: 42, seven: 18),
            providerID: Snapshot.claudeProviderID,
            now: now
        )
        #expect(display.fiveHour.percentText == "42%")
        #expect(display.sevenDay.percentText == "18%")
        #expect(display.fiveHour.isBold == false)
        #expect(display.sevenDay.isBold == false)
        #expect(display.isFlipped == false)
        #expect(display.fiveHour.fraction == 0.42)
        #expect(display.sevenDay.fraction == 0.18)
        #expect(display.fiveHour.rowText == "5-hour  42% · resets in 2h 21m")
        #expect(display.sevenDay.rowText == "7-day  18% · resets in 6d 09h")
        #expect(display.visibleWindows == [display.fiveHour, display.sevenDay])
        #expect(display.ageText == "Updated 2 min ago · statusline")
    }

    @Test func seventyFiveBoldsOnlyTheAffectedNumber() {
        let display = MeterDisplay.make(
            snapshot: snapshot(five: 75, seven: 74),
            providerID: Snapshot.claudeProviderID,
            now: now
        )
        #expect(display.fiveHour.isBold == true)
        #expect(display.sevenDay.isBold == false)
        #expect(display.isFlipped == false)
    }

    @Test func ninetyFlipsTheLabel() {
        let display = MeterDisplay.make(
            snapshot: snapshot(five: 12, seven: 90),
            providerID: Snapshot.claudeProviderID,
            now: now
        )
        #expect(display.isFlipped == true)
        #expect(display.sevenDay.isBold == true)
        let below = MeterDisplay.make(
            snapshot: snapshot(five: 89, seven: 89),
            providerID: Snapshot.claudeProviderID,
            now: now
        )
        #expect(below.isFlipped == false)
    }

    @Test func passedResetShowsZero() {
        let afterFiveHourReset = Fixtures.fiveReset.addingTimeInterval(60)
        let display = MeterDisplay.make(
            snapshot: snapshot(five: 95, seven: 40),
            providerID: Snapshot.claudeProviderID,
            now: afterFiveHourReset
        )
        #expect(display.fiveHour.percent == 0)
        #expect(display.fiveHour.percentText == "0%")
        #expect(display.fiveHour.isBold == false)
        #expect(display.fiveHour.fraction == 0)
        #expect(display.fiveHour.rowText == "5-hour  0% · reset")
        #expect(display.isFlipped == false)
        #expect(display.sevenDay.percent == 40)
    }

    @Test func absentWindowShowsDashes() {
        let display = MeterDisplay.make(
            snapshot: snapshot(five: 42, seven: nil),
            providerID: Snapshot.claudeProviderID,
            now: now
        )
        #expect(display.fiveHour.percentText == "42%")
        #expect(display.sevenDay.percentText == "--")
        #expect(display.sevenDay.percent == nil)
        #expect(display.sevenDay.fraction == 0)
        #expect(display.sevenDay.rowText == "7-day  --")
    }

    @Test func fractionIsClampedToOne() {
        let display = MeterDisplay.make(
            snapshot: snapshot(five: 130, seven: 18),
            providerID: Snapshot.claudeProviderID,
            now: now
        )
        #expect(display.fiveHour.fraction == 1)
        #expect(display.isFlipped == true)
    }

    @Test func noSnapshotShowsDashesAndNoAge() {
        let display = MeterDisplay.make(
            snapshot: nil,
            providerID: Snapshot.claudeProviderID,
            now: now
        )
        #expect(display.fiveHour.percentText == "--")
        #expect(display.sevenDay.percentText == "--")
        #expect(display.isFlipped == false)
        #expect(display.ageText == "No snapshot yet")
    }

    @Test func selectsRequestedProviderFromConflictingValues() {
        let providers = [
            Snapshot.claudeProviderID: ProviderUsage(
                fiveHour: UsageWindow(usedPercentage: 42, resetsAt: Fixtures.fiveReset),
                sevenDay: UsageWindow(usedPercentage: 18, resetsAt: Fixtures.sevenReset),
                capturedAt: now.addingTimeInterval(-120),
                source: "statusline"
            ),
            Snapshot.codexProviderID: ProviderUsage(
                fiveHour: UsageWindow(usedPercentage: 99, resetsAt: Fixtures.fiveReset),
                sevenDay: UsageWindow(usedPercentage: 63, resetsAt: Fixtures.sevenReset),
                capturedAt: now.addingTimeInterval(-30),
                source: "app-server"
            )
        ]
        let display = MeterDisplay.make(
            snapshot: Snapshot(schemaVersion: 1, providers: providers),
            providerID: Snapshot.codexProviderID,
            now: now
        )

        #expect(display.fiveHour.percentText == "99%")
        #expect(display.sevenDay.percentText == "63%")
        #expect(display.fiveHour.isBold == true)
        #expect(display.sevenDay.isBold == false)
        #expect(display.visibleWindows == [display.sevenDay])
        #expect(display.visibleWindows.map(\.percentText) == ["63%"])
        #expect(display.isFlipped == false)
        #expect(display.ageText == "Updated just now · app-server")
    }

    @Test func missingRequestedProviderShowsDashesAndNoAge() {
        let display = MeterDisplay.make(
            snapshot: snapshot(five: 42, seven: 18),
            providerID: Snapshot.codexProviderID,
            now: now
        )

        #expect(display.fiveHour.percentText == "--")
        #expect(display.sevenDay.percentText == "--")
        #expect(display.isFlipped == false)
        #expect(display.ageText == "No snapshot yet")
    }

    @Test func separatorIsTheSingleSourceOfTruth() {
        #expect(MeterDisplay.separator == " · ")
        #expect(StatuslineLine.separator == MeterDisplay.separator)
    }
}
