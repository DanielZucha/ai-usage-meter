# Decision: the snapshot file is the only interface between hook and app

This remains the Claude hook/app interface. Codex collection is now owned by
the app under the [polling decision](2026-09-06_codex-app-owned-polling.md),
while retaining the provider-keyed snapshot storage contract. [ADR:codex-polling]

## What was decided
The hook writes `~/Library/Application Support/ai-usage-meter/snapshot.json`
by writing a temp file in the same directory and renaming it into place.
The document carries a top-level `schema_version`, and a `providers` map
keyed by provider id. Version one has one key, `claude`, holding
`five_hour` and `seven_day` objects (each `used_percentage` and
`resets_at`, ISO-8601), plus `captured_at` and `source: "statusline"`.
A window absent from the statusline input is written as absent, never as
zero; interpreting absence is the app's job.

## Why
Provider keying makes a second service (Codex is the named candidate) an
additive writer, not a schema change. Atomic rename means the app, which
polls on a timer, never parses a partial file. Application Support is the
macOS-native home and keeps the file out of `~/.claude`, which Claude Code
owns.

## Evidence
- Statusline windows can be absent independently and are dropped once
  `resets_at` passes. [S1]
- The statusline delivers `resets_at` as epoch seconds; the hook converts
  to ISO-8601 so the file is human-readable and the app parses one
  format. [S2:F2]
- Writes come from every running session, concurrently, so the hook merges
  rather than overwrites; see the [merge rule](2026-09-05_snapshot-merge-rule.md).
  [S2:F3][S2:F4]
- Daniel named Codex as a future provider in the founding grill.

## Alternatives considered
- Placing the file under `~/.claude/`: rejected, that directory belongs to
  Claude Code and its layout is not ours to extend.
- Flat, single-provider schema: rejected for the cost of one nesting level.

Related: [data-source decision](2026-09-05_data-source-statusline-snapshot.md),
[app behaviour](2026-09-05_app-refresh-and-display-rules.md)

**Last updated**: 2026-09-06
