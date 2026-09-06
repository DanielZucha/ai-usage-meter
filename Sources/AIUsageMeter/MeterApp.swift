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
            MeterLabel(image: model.claudeLabelImage)
        }
        .menuBarExtraStyle(.window)

        MenuBarExtra {
            MeterMenu(display: model.codexDisplay)
        } label: {
            MeterLabel(image: model.codexLabelImage)
        }
        .menuBarExtraStyle(.window)
    }
}
