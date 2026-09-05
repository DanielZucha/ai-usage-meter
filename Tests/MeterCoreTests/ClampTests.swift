import Foundation
import Testing
@testable import MeterCore

@Suite struct ClampTests {
    @Test func roundsWithinRange() {
        #expect(clampedInt(42.4) == 42)
        #expect(clampedInt(42.5) == 43)
    }

    @Test func clampsBelowLowerBound() {
        #expect(clampedInt(-5) == 0)
    }

    @Test func clampsAboveUpperBound() {
        #expect(clampedInt(1_500) == 1_000)
    }

    @Test func nonFiniteBecomesNil() {
        #expect(clampedInt(.infinity) == nil)
        #expect(clampedInt(-.infinity) == nil)
        #expect(clampedInt(.nan) == nil)
    }

    @Test func hugeFiniteValueClampsInsteadOfTrapping() {
        #expect(clampedInt(1e300) == 1_000)
        #expect(clampedInt(-1e300) == 0)
    }

    @Test func honorsACustomRange() {
        #expect(clampedInt(1e300, 0...1_000_000_000_000) == 1_000_000_000_000)
        #expect(clampedInt(5, 10...20) == 10)
    }
}
