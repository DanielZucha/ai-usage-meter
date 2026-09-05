# Decision: the glyph ships as an SVG string constant, not a resource

## What was decided
`assets/claude.svg` is embedded verbatim as `ClaudeGlyph.filledSVG` in
MeterCore; a test keeps the constant byte-identical to the asset. The
outline variant is derived at runtime by replacing the fill attribute with
a stroke. The app turns each string into a template `NSImage` with
`NSImage(data:)`.

## Why
SwiftPM resources for an executable target resolve through `Bundle.module`,
which looks next to the binary or under `Bundle.main.bundleURL`; a
hand-assembled `.app` (no Xcode here) would have to reproduce that layout
exactly or crash at launch. A 1.7 KB string has no layout, no bundle, and
no runtime lookup. macOS 11 and later render SVG data in `NSImage`.

## Evidence
- Host decision: SwiftPM only, no Xcode. [host decision](2026-09-05_host-native-swift-menubarextra.md)
- Display decision: outline normally, filled at 90 percent, template image.
  [display rules](2026-09-05_app-refresh-and-display-rules.md)
- Measured 2026-09-05 via the AppKit ObjC bridge: `NSImage(data:)` on the
  asset returns an `_NSSVGImageRep`; filled and stroke-width-1 outline
  both rasterize at 32 and 128 px. The `1em` size attributes are harmless
  because the app sets the image size explicitly.

## Alternatives considered
- SwiftPM `resources: [.copy("claude.svg")]` plus `Bundle.module`: rejected
  for the bundle-layout coupling above.
- Parsing the path data into a SwiftUI `Shape`: rejected, the path uses
  arc commands and a parser is more code than the whole app.
- Two PNG sets at 1x and 2x: rejected, a raster loses the template
  crispness at fractional scales and doubles the asset count.

Related: [display rules](2026-09-05_app-refresh-and-display-rules.md)

**Last updated**: 2026-09-05
