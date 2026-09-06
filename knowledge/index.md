# ai-usage-meter knowledge index
<!-- Master catalog. Updated on every INGEST. Read at session start. -->
<!-- Generated 2026-09-05 during the founding grill session -->

## Now
- Phase: app-owned Codex polling installed, live values verified, renewed six-role audit complete; PR 4 open (as of 2026-09-06)
- Active: user monitoring of automatic refresh after both freshness fixes (as of 2026-09-06)
- Next: collect monitoring feedback on the pushed revision in PR 4; merge remains on hold (as of 2026-09-06)
- Deferred: threshold notifications (as of 2026-09-06)
- Known: per-model weekly usage (the /usage Fable row) is not in the statusline payload; the builder emits five_hour, seven_day, spend_limit only, and the Fable row comes from the usage API the meter never calls (probe 2, S3) (as of 2026-09-05)

## Sources
- [source_registry.md](sources/source_registry.md) -- registry of immutable inputs
- [2026-09-06_codex-data-source.md](../docs/2026-09-06_codex-data-source.md) -- verified Codex App Server, hook, signage, and glyph findings
- [2026-09-06_codex-pro-weekly-limit.md](../docs/2026-09-06_codex-pro-weekly-limit.md) -- live Pro refresh and approved weekly-only correction

## Entities

### Components
### Integrations
### Data formats
### Runbooks
- [install_and_wire.md](entities/runbooks/install_and_wire.md) -- make install, paste the snippet, verify, undo, toolchain traps

## Synthesis
- [gaps_and_leads.md](synthesis/gaps_and_leads.md) -- open questions and leads

## Decisions
- [2026-09-05_data-source-statusline-snapshot.md](decisions/2026-09-05_data-source-statusline-snapshot.md) -- read usage from the official statusline JSON via a snapshot file; never touch credentials
- [2026-09-05_host-native-swift-menubarextra.md](decisions/2026-09-05_host-native-swift-menubarextra.md) -- native SwiftPM app with MenuBarExtra, no third-party runtime
- [2026-09-05_snapshot-contract.md](decisions/2026-09-05_snapshot-contract.md) -- provider-keyed snapshot in Application Support, atomic rename, absence preserved
- [2026-09-05_hook-is-a-swift-target.md](decisions/2026-09-05_hook-is-a-swift-target.md) -- hook is a compiled target sharing the model; prints one terminal line; installer never edits settings.json
- [2026-09-05_app-refresh-and-display-rules.md](decisions/2026-09-05_app-refresh-and-display-rules.md) -- 30 s timer, filled glyph plus two numbers, bold at 75, label flips at 90, zero after reset, window-style dropdown with pill bars
- [2026-09-05_snapshot-merge-rule.md](decisions/2026-09-05_snapshot-merge-rule.md) -- Claude session merge keeps the max for the same window; serialized Codex reads use provider replacement
- [2026-09-05_glyph-embedded-svg-string.md](decisions/2026-09-05_glyph-embedded-svg-string.md) -- glyph travels as a Swift string constant, byte-identical to assets/claude.svg; no resource bundle
- [2026-09-05_pr-1_audit.md](decisions/2026-09-05_pr-1_audit.md) -- v1 merges as audited; hollow rate_limits no longer refreshes captured_at; low notes recorded, not ticketed
- [2026-09-06_codex-app-server-snapshot.md](decisions/2026-09-06_codex-app-server-snapshot.md) -- retained authenticated App Server source; historical Stop-hook scheduling superseded
- [2026-09-06_codex-app-owned-polling.md](decisions/2026-09-06_codex-app-owned-polling.md) -- verified launch/30-second collection, authoritative Codex replacement, successful-capture age, and hook retirement
- [2026-09-06_codex-pro-weekly-only.md](decisions/2026-09-06_codex-pro-weekly-only.md) -- Codex Pro decodes and renders only its 7-day window; Claude remains unchanged
- [2026-09-06_pr-4_audit.md](decisions/2026-09-06_pr-4_audit.md) -- historical audit of Stop-hook implementation; stale for app-owned polling revision
- [2026-09-06_pr-4_polling_audit.md](decisions/2026-09-06_pr-4_polling_audit.md) -- renewed six-role audit, 108 tests, coverage limits, installed polling/value checks, and remaining low findings

**Last updated**: 2026-09-06
