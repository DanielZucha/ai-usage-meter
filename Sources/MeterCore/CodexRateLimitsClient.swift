import Darwin
import Foundation

public enum CodexRateLimitsClientError: Error, Equatable, Sendable {
    case invalidExecutable
    case invalidConfiguration
    case launchFailed
    case timedOut
    case outputLimitExceeded
    case protocolFailure
    case unexpectedEndOfFile
}

/// Performs one bounded Codex App Server stdio exchange. Authentication stays
/// inside the Codex process; this client retains only the rate-limit response.
public struct CodexRateLimitsClient: CodexUsageFetching, Sendable {
    public static let defaultTimeout: TimeInterval = 8
    public static let defaultOutputLimitBytes = 1_048_576
    public static let maximumTimeout: TimeInterval = 60
    public static let maximumOutputLimitBytes = 16_777_216

    public let timeout: TimeInterval
    public let outputLimitBytes: Int

    public init(
        timeout: TimeInterval = Self.defaultTimeout,
        outputLimitBytes: Int = Self.defaultOutputLimitBytes
    ) {
        self.timeout = timeout
        self.outputLimitBytes = outputLimitBytes
    }

    public func fetchUsage(executableURL: URL, capturedAt: Date) throws -> ProviderUsage? {
        guard timeout.isFinite,
              timeout > 0,
              timeout <= Self.maximumTimeout,
              outputLimitBytes > 0,
              outputLimitBytes <= Self.maximumOutputLimitBytes else {
            throw CodexRateLimitsClientError.invalidConfiguration
        }
        let executable = try validatedExecutable(executableURL)
        let workingDirectory = SnapshotStore.defaultURL().deletingLastPathComponent()
        try FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true)

        let process = Process()
        let input = Pipe()
        let output = Pipe()
        process.executableURL = executable
        process.arguments = ["app-server", "--stdio"]
        process.currentDirectoryURL = workingDirectory
        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            throw CodexRateLimitsClientError.launchFailed
        }
        defer {
            try? input.fileHandleForWriting.close()
            stopAndReap(process)
            try? output.fileHandleForReading.close()
        }

        let deadline = monotonicDeadline(after: timeout)
        var reader = JSONLReader(
            descriptor: output.fileHandleForReading.fileDescriptor,
            deadlineNanoseconds: deadline,
            outputLimitBytes: outputLimitBytes
        )

        try write(Self.initializeRequest, to: input.fileHandleForWriting)
        try waitForResponse(id: 1, reader: &reader)
        try write(Self.initializedNotification, to: input.fileHandleForWriting)
        try write(Self.rateLimitsRequest, to: input.fileHandleForWriting)
        try waitForResponse(id: 2, reader: &reader)

        return CodexRateLimitsDecoder.providerUsage(
            from: reader.transcript,
            responseID: 2,
            capturedAt: capturedAt
        )
    }

    private static let initializeRequest = Data(
        "{\"id\":1,\"method\":\"initialize\",\"params\":{\"clientInfo\":{\"name\":\"ai-usage-meter\",\"version\":\"1\"}}}\n".utf8
    )
    private static let initializedNotification = Data("{\"method\":\"initialized\"}\n".utf8)
    private static let rateLimitsRequest = Data(
        "{\"id\":2,\"method\":\"account/rateLimits/read\"}\n".utf8
    )
}

private extension CodexRateLimitsClient {
    func validatedExecutable(_ url: URL) throws -> URL {
        guard url.isFileURL, url.path.hasPrefix("/") else {
            throw CodexRateLimitsClientError.invalidExecutable
        }
        let resolved = url.resolvingSymlinksInPath().standardizedFileURL
        let attributes = try? FileManager.default.attributesOfItem(atPath: resolved.path)
        guard attributes?[.type] as? FileAttributeType == .typeRegular,
              FileManager.default.isExecutableFile(atPath: resolved.path) else {
            throw CodexRateLimitsClientError.invalidExecutable
        }
        return resolved
    }

    func write(_ data: Data, to handle: FileHandle) throws {
        try handle.write(contentsOf: data)
    }

    func waitForResponse(id: Int64, reader: inout JSONLReader) throws {
        while true {
            let line = try reader.nextLine()
            guard let object = try? JSONSerialization.jsonObject(with: line) as? [String: Any] else {
                throw CodexRateLimitsClientError.protocolFailure
            }
            guard (object["id"] as? NSNumber)?.int64Value == id else { continue }
            guard object["error"] == nil, object["result"] != nil else {
                throw CodexRateLimitsClientError.protocolFailure
            }
            return
        }
    }

    func stopAndReap(_ process: Process) {
        guard process.isRunning else {
            process.waitUntilExit()
            return
        }
        let gracefulDeadline = monotonicDeadline(after: 0.1)
        while process.isRunning, DispatchTime.now().uptimeNanoseconds < gracefulDeadline {
            usleep(10_000)
        }
        if process.isRunning { process.terminate() }
        let terminateDeadline = monotonicDeadline(after: 0.1)
        while process.isRunning, DispatchTime.now().uptimeNanoseconds < terminateDeadline {
            usleep(10_000)
        }
        if process.isRunning { kill(process.processIdentifier, SIGKILL) }
        process.waitUntilExit()
    }

    func monotonicDeadline(after seconds: TimeInterval) -> UInt64 {
        let interval = UInt64(max(0, seconds) * 1_000_000_000)
        return DispatchTime.now().uptimeNanoseconds &+ interval
    }
}

private struct JSONLReader {
    let descriptor: Int32
    let deadlineNanoseconds: UInt64
    let outputLimitBytes: Int
    private(set) var transcript = Data()
    private var pending = Data()
    private var reachedEOF = false

    init(descriptor: Int32, deadlineNanoseconds: UInt64, outputLimitBytes: Int) {
        self.descriptor = descriptor
        self.deadlineNanoseconds = deadlineNanoseconds
        self.outputLimitBytes = outputLimitBytes
    }

    mutating func nextLine() throws -> Data {
        while true {
            if let newline = pending.firstIndex(of: 0x0A) {
                let line = Data(pending[..<newline])
                pending.removeSubrange(...newline)
                return line
            }
            if reachedEOF {
                guard !pending.isEmpty else {
                    throw CodexRateLimitsClientError.unexpectedEndOfFile
                }
                defer { pending.removeAll() }
                return pending
            }
            try readAvailableBytes()
        }
    }

    private mutating func readAvailableBytes() throws {
        let now = DispatchTime.now().uptimeNanoseconds
        guard now < deadlineNanoseconds else { throw CodexRateLimitsClientError.timedOut }
        let remaining = deadlineNanoseconds - now
        let milliseconds = Int32(min(UInt64(Int32.max), max(1, (remaining + 999_999) / 1_000_000)))
        var descriptorState = pollfd(fd: descriptor, events: Int16(POLLIN | POLLHUP), revents: 0)
        let result = poll(&descriptorState, 1, milliseconds)
        guard result > 0 else {
            if result == 0 { throw CodexRateLimitsClientError.timedOut }
            if errno == EINTR { return }
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }

        var bytes = [UInt8](repeating: 0, count: 4_096)
        let count = bytes.withUnsafeMutableBytes { buffer in
            Darwin.read(descriptor, buffer.baseAddress, buffer.count)
        }
        guard count >= 0 else {
            if errno == EINTR || errno == EAGAIN { return }
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        guard count > 0 else {
            reachedEOF = true
            return
        }
        guard transcript.count + count <= outputLimitBytes else {
            throw CodexRateLimitsClientError.outputLimitExceeded
        }
        let chunk = Data(bytes.prefix(count))
        transcript.append(chunk)
        pending.append(chunk)
    }
}
