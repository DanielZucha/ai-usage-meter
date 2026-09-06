import Foundation
import MeterCore

// Codex Stop-hook input can contain conversation text. Drain it without
// decoding, retaining, logging, or echoing any bytes.
while let chunk = try? FileHandle.standardInput.read(upToCount: 65_536),
      !chunk.isEmpty {}

if let executableURL = CodexHookArguments.executableURL(from: CommandLine.arguments) {
    CodexHookRunner.run(
        executableURL: executableURL,
        store: .default,
        fetcher: CodexRateLimitsClient()
    )
}
