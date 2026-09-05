import Foundation
import Testing
@testable import MeterCore

@Suite struct CountdownTests {
    let now = Date(timeIntervalSince1970: 1_788_608_892)

    @Test func daysAndHours() {
        #expect(Countdown.text(until: now.addingTimeInterval(4 * 86_400 + 6 * 3600 + 59 * 60), from: now) == "4d 06h")
    }

    @Test func hoursAndMinutes() {
        #expect(Countdown.text(until: now.addingTimeInterval(3600 + 2 * 60), from: now) == "1h 02m")
    }

    @Test func minutesOnly() {
        #expect(Countdown.text(until: now.addingTimeInterval(42 * 60), from: now) == "42m")
    }

    @Test func underAMinute() {
        #expect(Countdown.text(until: now.addingTimeInterval(30), from: now) == "under 1m")
    }

    @Test func nilOnceReset() {
        #expect(Countdown.text(until: now, from: now) == nil)
        #expect(Countdown.text(until: now.addingTimeInterval(-1), from: now) == nil)
    }

    @Test func ageBuckets() {
        #expect(Countdown.age(since: now.addingTimeInterval(-10), now: now) == "just now")
        #expect(Countdown.age(since: now.addingTimeInterval(-3 * 60), now: now) == "3 min ago")
        #expect(Countdown.age(since: now.addingTimeInterval(-2 * 3600), now: now) == "2 h ago")
        #expect(Countdown.age(since: now.addingTimeInterval(-3 * 86_400), now: now) == "3 d ago")
    }

    @Test func hugeResetDistanceDoesNotCrash() {
        let farAway = Date(timeIntervalSince1970: 1e300)
        let text = Countdown.text(until: farAway, from: now)
        #expect(text != nil)
    }

    @Test func nonFiniteResetDistanceReturnsNilNotCrash() {
        let text = Countdown.text(until: Date(timeIntervalSince1970: .infinity), from: now)
        #expect(text == nil)
    }

    @Test func hugeAgeDoesNotCrash() {
        let ancient = Date(timeIntervalSince1970: -1e300)
        let text = Countdown.age(since: ancient, now: now)
        #expect(!text.isEmpty)
    }
}
