import Foundation
import ServiceManagement

/// Registers the app to start at login. Skipped when the binary runs
/// unbundled (`swift run`), where `SMAppService` has nothing to register.
enum LaunchAtLogin {
    static func registerIfNeeded() {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }
        let service = SMAppService.mainApp
        defer { print("launch-at-login status: \(String(describing: service.status))") }
        guard service.status != .enabled else { return }
        do {
            try service.register()
        } catch {
            print("launch-at-login registration failed: \(error)")
        }
    }
}
