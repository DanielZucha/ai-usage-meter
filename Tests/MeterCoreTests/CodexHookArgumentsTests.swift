import Foundation
import Testing
@testable import MeterCore

@Suite struct CodexHookArgumentsTests {
    @Test func acceptsOneAbsoluteCodexBinaryPath() {
        let url = CodexHookArguments.executableURL(
            from: ["ai-usage-meter-codex-hook", "--codex-bin", "/opt/local/bin/codex"]
        )
        #expect(url == URL(fileURLWithPath: "/opt/local/bin/codex"))
    }

    @Test(arguments: [
        ["ai-usage-meter-codex-hook"],
        ["ai-usage-meter-codex-hook", "--codex-bin"],
        ["ai-usage-meter-codex-hook", "--codex-bin", "relative/codex"],
        ["ai-usage-meter-codex-hook", "--codex-bin", "/bin/codex", "extra"],
    ])
    func rejectsIncompleteRelativeOrExtraArguments(arguments: [String]) {
        #expect(CodexHookArguments.executableURL(from: arguments) == nil)
    }
}
