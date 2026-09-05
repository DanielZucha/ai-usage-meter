# Knowledge Wiki Log
<!-- Append-only. Records all INGEST, QUERY, LINT operations. -->
<!-- Format: ## [YYYY-MM-DD] operation | description -->

## [2026-09-05] INIT | Wiki scaffolded during the founding grill session
- Scaffold created by hand from ~/.claude/templates/knowledge (tooling flavor)
- Seed source: docs/2026-09-05_usage-data-sources.md

## [2026-09-05] ingest | Usage data-source fact report
- source: docs/2026-09-05_usage-data-sources.md
- pages touched: decisions/2026-09-05_data-source-statusline-snapshot.md, decisions/2026-09-05_host-native-swift-menubarextra.md, synthesis/gaps_and_leads.md, index.md
- notes: two real quota sources exist (official statusline JSON, undocumented OAuth endpoint); only the first is credential-free

## [2026-09-05] ingest | Founding grill rounds one and two
- source: grill session answers (Daniel), assets/claude.svg
- pages touched: decisions/2026-09-05_snapshot-contract.md, decisions/2026-09-05_hook-is-a-swift-target.md, decisions/2026-09-05_app-refresh-and-display-rules.md, index.md, synthesis/gaps_and_leads.md
- notes: all frontier questions settled; one parked item (statusline probe) awaits go-ahead

## [2026-09-05] ingest | Statusline probe capture
- source: docs/2026-09-05_statusline-probe.md
- pages touched: decisions/2026-09-05_snapshot-merge-rule.md (new), decisions/2026-09-05_snapshot-contract.md, synthesis/gaps_and_leads.md, sources/source_registry.md, index.md
- notes: rate_limits confirmed on 2.1.261; resets_at is epoch seconds; every running session renders concurrently with its own stale value, so the hook merges per window (max within a window, later reset wins); grill closed

## [2026-09-05] ingest | v1 implementation on feature/v1-meter
- source: docs/superpowers/plans/2026-09-05-v1-meter.md and the resulting commits
- pages touched: decisions/2026-09-05_glyph-embedded-svg-string.md (new), entities/runbooks/install_and_wire.md (new), decisions/2026-09-05_app-refresh-and-display-rules.md, decisions/2026-09-05_data-source-statusline-snapshot.md, index.md
- notes: three-target SwiftPM package, 51 MeterCore tests, make install wiring; display rules revised the same day after Daniel's first look (75 bold, 90 flip, pill bars); two toolchain traps recorded in the runbook (stale private interfaces moved aside; CLT swift-testing wired through make test); seven_day confirmed as the all-models weekly row

## [2026-09-05] ingest | Tasks 15 and 16, terminal line
- source: the plan `docs/superpowers/plans/2026-09-05-v1-meter.md` Tasks 15 and 16
- pages touched: decisions/2026-09-05_hook-is-a-swift-target.md, entities/runbooks/install_and_wire.md, README.md
- notes: line format now `<model> · <effort> · U+26C1 <n>%`, 5h/7d dropped; test count 54 plus the fix-wave additions, 70 total from `make test`
