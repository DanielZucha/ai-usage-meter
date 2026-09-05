import Foundation

/// Rounds to Int without trapping: non-finite values become nil, everything
/// else is clamped to the given range. `Int(x.rounded())` aborts the process
/// on values outside `Int`'s range, and untrusted JSON (`used_percentage:
/// 1e300`) can carry exactly that, so every Double-to-Int conversion fed by
/// external input goes through here instead.
public func clampedInt(_ value: Double, _ range: ClosedRange<Int> = 0...1_000) -> Int? {
    guard value.isFinite else { return nil }
    return Int(min(max(value.rounded(), Double(range.lowerBound)), Double(range.upperBound)))
}
