# ai-usage-meter knowledge index
<!-- Master catalog. Updated on every INGEST. Read at session start. -->
<!-- Generated 2026-09-05 during the founding grill session -->

## Now
- Phase: build. Founding grill closed, probe confirmed the data source; no code yet (as of 2026-09-05)
- Active: writing the implementation plan from the six decision pages (as of 2026-09-05)
- Next: SwiftPM package with library, app and hook targets on a feature branch, PR to devel via /pr-audit (as of 2026-09-05)
- Deferred: threshold notifications; Codex as a second provider (see synthesis/gaps_and_leads.md) (as of 2026-09-05)

## Sources
- [source_registry.md](sources/source_registry.md) -- registry of immutable inputs

## Entities

### Components
### Integrations
### Data formats
### Runbooks

## Synthesis
- [gaps_and_leads.md](synthesis/gaps_and_leads.md) -- open questions and leads

## Decisions
- [2026-09-05_data-source-statusline-snapshot.md](decisions/2026-09-05_data-source-statusline-snapshot.md) -- read usage from the official statusline JSON via a snapshot file; never touch credentials
- [2026-09-05_host-native-swift-menubarextra.md](decisions/2026-09-05_host-native-swift-menubarextra.md) -- native SwiftPM app with MenuBarExtra, no third-party runtime
- [2026-09-05_snapshot-contract.md](decisions/2026-09-05_snapshot-contract.md) -- provider-keyed snapshot in Application Support, atomic rename, absence preserved
- [2026-09-05_hook-is-a-swift-target.md](decisions/2026-09-05_hook-is-a-swift-target.md) -- hook is a compiled target sharing the model; prints one terminal line; installer never edits settings.json
- [2026-09-05_app-refresh-and-display-rules.md](decisions/2026-09-05_app-refresh-and-display-rules.md) -- 30 s timer, glyph plus two numbers, bold at 70, filled glyph at 90, zero after reset
- [2026-09-05_snapshot-merge-rule.md](decisions/2026-09-05_snapshot-merge-rule.md) -- every session writes; same window keeps the max, later reset replaces, epoch converted to ISO
