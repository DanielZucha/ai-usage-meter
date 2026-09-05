import SwiftUI

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
            MeterLabel(image: model.labelImage)
        }
        .menuBarExtraStyle(.window)
    }
}
