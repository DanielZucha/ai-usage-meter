import Foundation

/// One window as the app should draw it.
public struct WindowDisplay: Equatable, Sendable {
    public var percent: Int?
    public var isBold: Bool
    public var percentText: String
    public var rowText: String
}

/// Everything the menu-bar app renders, computed once per refresh so the
/// views stay free of rules.
public struct MeterDisplay: Equatable, Sendable {
    public static let boldThreshold = 70
    public static let fillThreshold = 90
    public static let unknown = "--"
    public static let noSnapshotText = "No snapshot yet"

    public var fiveHour: WindowDisplay
    public var sevenDay: WindowDisplay
    public var glyphFilled: Bool
    public var barText: String
    public var ageText: String

    public static func make(snapshot: Snapshot?, now: Date) -> MeterDisplay {
        let usage = snapshot?.claude
        let fiveHour = window(named: "5-hour", usage?.fiveHour, now: now)
        let sevenDay = window(named: "7-day", usage?.sevenDay, now: now)
        let filled = [fiveHour, sevenDay].contains { ($0.percent ?? 0) >= fillThreshold }
        let age = usage.map { "Updated \(Countdown.age(since: $0.capturedAt, now: now)) · \($0.source)" }
            ?? noSnapshotText
        return MeterDisplay(
            fiveHour: fiveHour,
            sevenDay: sevenDay,
            glyphFilled: filled,
            barText: "\(fiveHour.percentText) · \(sevenDay.percentText)",
            ageText: age
        )
    }

    static func window(named name: String, _ window: UsageWindow?, now: Date) -> WindowDisplay {
        guard let window else {
            return WindowDisplay(percent: nil, isBold: false, percentText: unknown, rowText: "\(name)  \(unknown)")
        }
        guard let countdown = Countdown.text(until: window.resetsAt, from: now) else {
            return WindowDisplay(percent: 0, isBold: false, percentText: "0%", rowText: "\(name)  0% · reset")
        }
        let percent = window.usedPercentage
        return WindowDisplay(
            percent: percent,
            isBold: percent >= boldThreshold,
            percentText: "\(percent)%",
            rowText: "\(name)  \(percent)% · resets in \(countdown)"
        )
    }
}
