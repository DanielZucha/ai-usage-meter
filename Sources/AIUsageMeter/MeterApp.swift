import SwiftUI

@main
struct MeterApp: App {
    @State private var model = MeterModel()

    init() {
        LaunchAtLogin.registerIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra {
            MeterMenu(display: model.claudeDisplay)
        } label: {
            MeterLabel(
                image: model.claudeLabelImage,
                accessibilityLabel: model.claudeDisplay.accessibilityLabel,
                accessibilityValue: model.claudeDisplay.accessibilityValue
            )
        }
        .menuBarExtraStyle(.window)

        MenuBarExtra {
            MeterMenu(display: model.codexDisplay)
        } label: {
            MeterLabel(
                image: model.codexLabelImage,
                accessibilityLabel: model.codexDisplay.accessibilityLabel,
                accessibilityValue: model.codexDisplay.accessibilityValue
            )
        }
        .menuBarExtraStyle(.window)
    }
}
