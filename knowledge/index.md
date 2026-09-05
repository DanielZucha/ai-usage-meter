# ai-usage-meter knowledge index
<!-- Master catalog. Updated on every INGEST. Read at session start. -->
<!-- Generated 2026-09-05 during the founding grill session -->

## Now
- Phase: design. Founding grill in progress; repo scaffolded, no code yet (as of 2026-09-05)
- Active: settle the remaining grill decisions (snapshot contract, hook language, glyph, threshold visuals), then /design the menu-bar look (as of 2026-09-05)
- Next: run the statusline probe to confirm `rate_limits` arrives on this account, pending Daniel's go-ahead to edit settings.json (as of 2026-09-05)

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
