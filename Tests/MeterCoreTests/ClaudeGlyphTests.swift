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

    @Test func filledMatchesTheAssetFile() throws {
        let file = try String(contentsOf: assetURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(ClaudeGlyph.filledSVG == file)
    }

    @Test func outlineStrokesInsteadOfFilling() {
        #expect(ClaudeGlyph.outlineSVG.contains("fill=\"none\""))
        #expect(ClaudeGlyph.outlineSVG.contains("stroke=\"currentColor\""))
        #expect(!ClaudeGlyph.outlineSVG.contains("fill=\"currentColor\""))
        #expect(ClaudeGlyph.outlineSVG.contains("<path d=\"M4.709"))
    }

    @Test func selectorPicksTheVariant() {
        #expect(ClaudeGlyph.svg(filled: true) == ClaudeGlyph.filledSVG)
        #expect(ClaudeGlyph.svg(filled: false) == ClaudeGlyph.outlineSVG)
    }
}
