import SwiftUI
import MeterCore

@main
struct MeterApp: App {
    @State private var model = MeterModel()

    init() {
        LaunchAtLogin.registerIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra {
            MeterMenu(display: model.display)
        } label: {
            MeterLabel(display: model.display)
        }
        .menuBarExtraStyle(.menu)
    }
}
