import Foundation

/// Loads installer-selected launcher without resolving version-manager symlinks.
public enum CodexLauncher {
    public static var defaultURL: URL {
        SnapshotStore.defaultURL().deletingLastPathComponent().appendingPathComponent("codex-launcher")
    }

    public enum LoadError: Error { case invalidConfiguration, unavailableExecutable }

    public static func load(from url: URL = defaultURL) throws -> URL {
        let fd = open(url.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard fd >= 0 else { throw LoadError.invalidConfiguration }
        defer { close(fd) }
        var info = stat()
        guard fstat(fd, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG,
              info.st_uid == getuid(), (info.st_mode & 0o777) == 0o600,
              info.st_size > 0, info.st_size <= 4096 else {
            throw LoadError.invalidConfiguration
        }
        var bytes = [UInt8](repeating: 0, count: 4097)
        let count = read(fd, &bytes, bytes.count)
        guard count > 0, count <= 4096,
              var path = String(bytes: bytes.prefix(count), encoding: .utf8) else {
            throw LoadError.invalidConfiguration
        }
        if path.hasSuffix("\n") { path.removeLast() }
        guard path.hasPrefix("/"), !path.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) else {
            throw LoadError.invalidConfiguration
        }
        var target = stat()
        guard stat(path, &target) == 0, (target.st_mode & S_IFMT) == S_IFREG,
              access(path, X_OK) == 0 else { throw LoadError.unavailableExecutable }
        return URL(fileURLWithPath: path)
    }
}
