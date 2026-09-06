import CryptoKit
import Foundation
import Testing
@testable import MeterCore

@Suite struct CodexGlyphTests {
    var assetURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // MeterCoreTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("assets/codex.svg")
    }

    @Test func svgMatchesTheAssetFile() throws {
        let file = try String(contentsOf: assetURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(CodexGlyph.svg == file)
    }

    @Test func assetMatchesTheOfficialExtensionDigest() throws {
        let data = try Data(contentsOf: assetURL)
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        #expect(digest == "8652777b55544c572ba445dd230a90c2e248611e92eaa77de5805e8d0561fc30")
    }
}
