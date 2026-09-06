import Foundation

/// Parses the deliberately narrow command line accepted by the Codex hook.
public enum CodexHookArguments {
    public static func executableURL(from arguments: [String]) -> URL? {
        guard arguments.count == 3,
              arguments[1] == "--codex-bin",
              arguments[2].hasPrefix("/") else { return nil }
        return URL(fileURLWithPath: arguments[2])
    }
}
