import Foundation
import Testing
@testable import MeterCore

@Suite struct ClaudeGlyphTests {
    var assetURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // MeterCoreTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("assets/claude.svg")
    }

    @Test func svgMatchesTheAssetFile() throws {
        let file = try String(contentsOf: assetURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(ClaudeGlyph.svg == file)
    }
}
