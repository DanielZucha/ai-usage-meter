import Foundation
import Testing
@testable import MeterCore

struct CodexLauncherTests {
    @Test func validatesStableSymlinkAndRejectsUnsafeFiles() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let target = root.appendingPathComponent("codex-version")
        try Data().write(to: target)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: target.path)
        let launcher = root.appendingPathComponent("codex")
        try FileManager.default.createSymbolicLink(at: launcher, withDestinationURL: target)
        let config = root.appendingPathComponent("codex-launcher")
        #expect(throws: (any Error).self) { try CodexLauncher.load(from: config) }
        try Data((launcher.path + "\n").utf8).write(to: config)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: config.path)
        #expect(try CodexLauncher.load(from: config) == launcher)
        let link = root.appendingPathComponent("config-link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: config)
        #expect(throws: (any Error).self) { try CodexLauncher.load(from: link) }
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: config.path)
        #expect(throws: (any Error).self) { try CodexLauncher.load(from: config) }
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: config.path)
        try FileManager.default.removeItem(at: target)
        #expect(throws: (any Error).self) { try CodexLauncher.load(from: config) }
        for value in ["", "relative/path\n", "/bin/sh\n/bin/sh\n", String(repeating: "x", count: 5000), root.path, config.path] {
            try Data(value.utf8).write(to: config)
            #expect(throws: (any Error).self) { try CodexLauncher.load(from: config) }
        }
    }
}
