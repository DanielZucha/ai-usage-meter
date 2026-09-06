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

## [2026-09-05] ingest | Probe 2, per-model weekly window
- source: docs/2026-09-05_statusline-probe-2.md (S3)
- pages touched: sources/source_registry.md, synthesis/gaps_and_leads.md, decisions/2026-09-05_data-source-statusline-snapshot.md, index.md (Now block)
- notes: Fable weekly row is usage-API only; statusline emits five_hour, seven_day, spend_limit; third meter deferred with a named trigger

## [2026-09-05] lint
- contradictions: none
- stale claims: none (superseded design bullets were folded on 2026-09-05; remaining mentions of the 70/90 outline design live in History sections only)
- orphan pages: none
- missing cross-refs: WIKI_SCHEMA.md and sources/source_registry.md carry no outbound link (utility pages; warning only)
- now-block: fresh (all five lines dated 2026-09-05, no later log entry contradicts them)
- claude-md: compliant (50 lines, static Now-block pointer, no mutable state)

## [2026-09-05] ingest | PR audit round 1
- source: six-agent audit verdicts (session), commits c822f0b and b7cc5be
- pages touched: decisions/2026-09-05_pr-1_audit.md (new), synthesis/gaps_and_leads.md, index.md (Now block, catalog), WIKI_SCHEMA.md
- notes: all six approve; HIGH freshness bug fixed; 72 tests

## [2026-09-05] ingest | Release v0.1.0
- source: PR #1 (devel, merge 27bc05d), PR #2 (main, merge 3d3c9e6), tag v0.1.0
- pages touched: index.md (Now block)
- notes: first release; no code change since the audit

## [2026-09-06] ingest | Codex counterpart source findings
- source: S4: docs/2026-09-06_codex-data-source.md
- pages touched: decisions/2026-09-06_codex-app-server-snapshot.md, entities/runbooks/install_and_wire.md, synthesis/gaps_and_leads.md, sources/source_registry.md, WIKI_SCHEMA.md, index.md
- notes: Codex usage comes from its authenticated App Server via a bounded async Stop hook; native TUI fields provide model, effort, and context signage

## [2026-09-06] lint
- contradictions: none
- stale claims: none
- orphan pages: none
- missing cross-refs: WIKI_SCHEMA.md and sources/source_registry.md have no outbound wiki links (utility-page warning only)
- now-block: fresh
- claude-md: unmigrated (project has a 50-line CLAUDE.md but no project AGENTS.md); its goal and architecture pointers still describe the Claude-only v1 surface

## [2026-09-06] ingest | Codex Pro weekly-only correction
- source: S5: docs/2026-09-06_codex-pro-weekly-limit.md
- pages touched: decisions/2026-09-06_codex-pro-weekly-only.md, decisions/2026-09-06_codex-app-server-snapshot.md, entities/runbooks/install_and_wire.md, sources/source_registry.md, index.md
- notes: Codex Pro now decodes and renders only its 7-day limit; Claude retains its 5-hour and 7-day windows

## [2026-09-06] lint
- contradictions: none (S4's initial 300/10080-minute interpretation is explicitly superseded by S5 for Codex Pro)
- stale claims: none
- orphan pages: none
- missing cross-refs: none
- now-block: fresh (visual styling is approved; async-hook freshness remains active until the Stop hook is wired)
- claude-md: compliant (44-line static AGENTS.md; CLAUDE.md delegates to it)

## [2026-09-06] ingest | PR 4 audit verdict
- source: six-role audit of commits b5836ee and 234c0e2
- pages touched: decisions/2026-09-06_pr-4_audit.md, index.md
- notes: all merge criteria pass after accessibility, stable-launcher, shell-injection, project-orientation, and hook-trust fixes; 100 Swift tests plus the snippet integration test pass
