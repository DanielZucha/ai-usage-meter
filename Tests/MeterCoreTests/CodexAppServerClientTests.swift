import Darwin
import Foundation
import Testing
@testable import MeterCore

// Process-heavy fixtures share constrained CI resources; serialize this suite
// so startup latency cannot masquerade as a transport timeout regression.
@Suite(.serialized) struct CodexAppServerClientTests {
    let capturedAt = Date(timeIntervalSince1970: 1_788_608_892)

    @Test func performsHandshakeInOrderAndDecodesUsage() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let captureURL = fixture.directory.appendingPathComponent("stdin.jsonl")
        let argumentsURL = fixture.directory.appendingPathComponent("argv.txt")
        let executableURL = try fixture.writeExecutable(
            named: "codex",
            body: """
            capture=\(shellQuote(captureURL.path))
            printf '%s\\n' "$@" > \(shellQuote(argumentsURL.path))
            IFS= read -r initialize
            printf '%s\\n' "$initialize" >> "$capture"
            printf '%s\\n' '{"id":1,"result":{"userAgent":"fake-codex"}}'
            IFS= read -r initialized
            printf '%s\\n' "$initialized" >> "$capture"
            IFS= read -r rate_limits
            printf '%s\\n' "$rate_limits" >> "$capture"
            printf '%s\\n' '{"id":2,"result":{"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":4,"windowDurationMins":10080,"resetsAt":1789160400},"secondary":{"usedPercent":21,"windowDurationMins":300,"resetsAt":1788617400}}}}}'
            """
        )
        let client = CodexRateLimitsClient(timeout: 1, outputLimitBytes: 16_384)

        let usage = try #require(try client.fetchUsage(
            executableURL: executableURL,
            capturedAt: capturedAt
        ))

        #expect(usage.fiveHour == nil)
        #expect(usage.sevenDay == UsageWindow(
            usedPercentage: 4,
            resetsAt: Date(timeIntervalSince1970: 1_789_160_400)
        ))
        #expect(usage.capturedAt == capturedAt)
        #expect(usage.source == "codex-app-server")

        let requests = try readRequests(from: captureURL)
        #expect(requests.count == 3)
        #expect(requests[0] == RequestEnvelope(id: 1, method: "initialize"))
        #expect(requests[1] == RequestEnvelope(id: nil, method: "initialized"))
        #expect(requests[2] == RequestEnvelope(id: 2, method: "account/rateLimits/read"))
        let arguments = try String(contentsOf: argumentsURL, encoding: .utf8)
            .split(separator: "\n")
            .map(String.init)
        #expect(arguments == ["app-server", "--stdio"])
    }

    @Test func rejectsInvalidExecutableBeforeLaunch() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let sentinelURL = fixture.directory.appendingPathComponent("launched")
        let nonExecutableURL = try fixture.writeFile(
            named: "not-executable",
            contents: "#!/bin/sh\\nprintf launched > \(shellQuote(sentinelURL.path))\\n",
            permissions: 0o600
        )
        let client = CodexRateLimitsClient(timeout: 0.2, outputLimitBytes: 1_024)

        #expect(throws: CodexRateLimitsClientError.invalidExecutable) {
            _ = try client.fetchUsage(
                executableURL: URL(string: "relative-codex")!,
                capturedAt: capturedAt
            )
        }
        #expect(throws: CodexRateLimitsClientError.invalidExecutable) {
            _ = try client.fetchUsage(executableURL: nonExecutableURL, capturedAt: capturedAt)
        }
        #expect(!FileManager.default.fileExists(atPath: sentinelURL.path))
    }

    @Test func timeoutReturnsPromptlyAndReapsTheChild() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let pidURL = fixture.directory.appendingPathComponent("pid")
        let fifoURL = fixture.directory.appendingPathComponent("never-opened-fifo")
        guard mkfifo(fifoURL.path, 0o600) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        let executableURL = try fixture.writeExecutable(
            named: "codex-timeout",
            body: """
            printf '%s\\n' "$$" > \(shellQuote(pidURL.path))
            IFS= read -r initialize
            printf '%s\\n' '{"id":1,"result":{}}'
            IFS= read -r initialized
            IFS= read -r rate_limits
            IFS= read -r blocked < \(shellQuote(fifoURL.path))
            """
        )
        let client = CodexRateLimitsClient(timeout: 1, outputLimitBytes: 1_024)
        let start = ContinuousClock.now

        #expect(throws: CodexRateLimitsClientError.timedOut) {
            _ = try client.fetchUsage(executableURL: executableURL, capturedAt: capturedAt)
        }

        #expect(start.duration(to: .now) < .seconds(3))
        let pid = try #require(Int32(try String(contentsOf: pidURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)))
        errno = 0
        #expect(kill(pid, 0) == -1)
        #expect(errno == ESRCH)
    }

    @Test func outputBeyondConfiguredLimitFailsPromptly() throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let executableURL = try fixture.writeExecutable(
            named: "codex-noisy",
            body: """
            IFS= read -r initialize
            printf '%4096s\\n' x
            """
        )
        let client = CodexRateLimitsClient(timeout: 1, outputLimitBytes: 256)
        let start = ContinuousClock.now

        #expect(throws: CodexRateLimitsClientError.outputLimitExceeded) {
            _ = try client.fetchUsage(executableURL: executableURL, capturedAt: capturedAt)
        }
        #expect(start.duration(to: .now) < .seconds(3))
    }

    @Test(arguments: [
        (61.0, 1_024),
        (Double.infinity, 1_024),
        (1.0, 16_777_217),
    ])
    func rejectsConfigurationBeyondHardBounds(timeout: TimeInterval, outputLimitBytes: Int) {
        let client = CodexRateLimitsClient(
            timeout: timeout,
            outputLimitBytes: outputLimitBytes
        )

        #expect(throws: CodexRateLimitsClientError.invalidConfiguration) {
            _ = try client.fetchUsage(
                executableURL: URL(fileURLWithPath: "/bin/echo"),
                capturedAt: capturedAt
            )
        }
    }

    @Test(arguments: [
        (#"{"id":1,"error":{"code":-32603,"message":"initialize failed"}}"#, "protocol error", CodexRateLimitsClientError.protocolFailure),
        ("{not-json}", "malformed output", CodexRateLimitsClientError.protocolFailure),
        (#"{"id":999,"result":{}}"#, "no matching response", CodexRateLimitsClientError.unexpectedEndOfFile),
    ])
    func badProtocolOutputDoesNotHang(
        output: String,
        name: String,
        expectedError: CodexRateLimitsClientError
    ) throws {
        let fixture = try makeFixture()
        defer { fixture.remove() }
        let executableURL = try fixture.writeExecutable(
            named: "codex-bad-output",
            body: "printf '%s\\n' \(shellQuote(output))"
        )
        let client = CodexRateLimitsClient(timeout: 1, outputLimitBytes: 1_024)
        let start = ContinuousClock.now
        #expect(throws: expectedError) {
            _ = try client.fetchUsage(
                executableURL: executableURL,
                capturedAt: capturedAt
            )
        }

        #expect(start.duration(to: .now) < .seconds(3), "case: \(name)")
    }
}

private struct RequestEnvelope: Decodable, Equatable {
    let id: Int64?
    let method: String
}

private struct ExecutableFixture {
    let directory: URL

    func writeExecutable(named name: String, body: String) throws -> URL {
        try writeFile(
            named: name,
            contents: "#!/bin/sh\nset -eu\n\(body)\n",
            permissions: 0o700
        )
    }

    func writeFile(named name: String, contents: String, permissions: mode_t) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try Data(contents.utf8).write(to: url)
        guard chmod(url.path, permissions) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        return url
    }

    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }
}

private func makeFixture() throws -> ExecutableFixture {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("ai-usage-meter-codex-client-tests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return ExecutableFixture(directory: directory)
}

private func readRequests(from url: URL) throws -> [RequestEnvelope] {
    try String(contentsOf: url, encoding: .utf8)
        .split(separator: "\n")
        .map { try JSONDecoder().decode(RequestEnvelope.self, from: Data($0.utf8)) }
}

private func shellQuote(_ value: String) -> String {
    let escaped = value.replacingOccurrences(of: "'", with: "'\"'\"'")
    return "'\(escaped)'"
}
