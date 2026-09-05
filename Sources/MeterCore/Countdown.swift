import Foundation

/// Human-readable durations for the dropdown. Kept coarse on purpose: the
/// app refreshes every 30 seconds, so seconds would only jitter.
public enum Countdown {
    public static func text(until reset: Date, from now: Date) -> String? {
        let remaining = Int(reset.timeIntervalSince(now).rounded(.up))
        guard remaining > 0 else { return nil }
        let minutes = remaining / 60
        let hours = minutes / 60
        let days = hours / 24
        if days >= 1 { return String(format: "%dd %02dh", days, hours % 24) }
        if hours >= 1 { return String(format: "%dh %02dm", hours, minutes % 60) }
        if minutes >= 1 { return "\(minutes)m" }
        return "under 1m"
    }

    public static func age(since captured: Date, now: Date) -> String {
        let seconds = Int(now.timeIntervalSince(captured))
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60) min ago" }
        if seconds < 86_400 { return "\(seconds / 3600) h ago" }
        return "\(seconds / 86_400) d ago"
    }
}
