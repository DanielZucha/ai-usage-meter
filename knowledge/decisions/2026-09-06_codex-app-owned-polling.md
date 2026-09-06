# Decision: the app owns Codex usage polling

**Status**: IMPLEMENTED; live captures and renewed audit verified; user monitoring
continues before merge. [PRAudit:2]
**Owner**: Daniel

## What was decided

The app collects Codex weekly usage immediately at launch and every 30 seconds
through a bounded, short-lived authenticated Codex App Server process. Work
runs away from the main actor. `CodexUsagePoller` skips overlapping requests;
`CodexSnapshotUpdater` uses a separate process poll lock before collection and
the existing short snapshot lock for provider-isolated updates. Each successful
serialized account read replaces the entire Codex provider entry, including
its reset time, rather than applying Claude's monotonic session merge. The
Claude entry and its existing merge rules remain unchanged. [ADR:codex-polling]

Only a successful capture renews the Codex timestamp. Failures preserve the
last successful value and age and show `Refresh unavailable` in the panel.
`CodexLauncher` reads the stable launcher path saved atomically with mode
`0600` in the meter's Application Support `codex-launcher` file. The installer
retires the preview hook executable and prints instructions to remove its
configuration manually. It never edits Claude or Codex configuration.
[ADR:codex-polling]

## Why

A 30-second snapshot reread cannot obtain new data when its writer never runs.
The diagnosed installation had no Codex Stop hook: the stored weekly value
was 12% while the direct authenticated account read showed 18% for the same
weekly window. Resetting the app or taking one manual snapshot cannot supply
recurring freshness. The user approved independent periodic collection.
[ADR:codex-polling]

The missing writer is one independent cause, not a complete explanation of
the original value mismatch. The subsequent live check below establishes a
second cause in the persisted-value merge. The observed saved reset is a
local snapshot artifact; it is not evidence that upstream promises immutable
reset seconds. [ADR:codex-polling]

The first live polling run exposed a second failure: the stored weekly value
remained 12% while a current account read showed 23%, and the reset time in
the current read was one second earlier than the saved reset. Claude's merge
rule rejected that window as stale while renewing its capture timestamp.
Codex's serialized authoritative account reads therefore replace its provider
entry, so timestamp freshness cannot hide a rejected value. [ADR:codex-polling]

## Evidence

- The user approved the revised polling plan on 2026-09-06 after reporting the
  12% widget / 18% weekly account mismatch and increasing capture age. This
  decision records that session finding without retaining raw account data.
  [ADR:codex-polling]
- The retained [App Server source](2026-09-06_codex-app-server-snapshot.md)
  supplies rate-limit reads inside the authenticated Codex process; no meter
  component reads credentials. [S4:C1][S4:C6]
- The [weekly-only contract](2026-09-06_codex-pro-weekly-only.md) and Claude
  provider isolation remain acceptance requirements. [S5:C2]
- Live installation demonstrated 30-second timestamp updates, but the
  12%/23% mismatch revealed the reset-time merge failure. These observations
  establish timer activity, not a correct end-to-end result. The replacement
  rule requires regression tests, redeployment, and renewed live comparison.
  [ADR:codex-polling]
- Implementation resides in `Sources/MeterCore/CodexLauncher.swift`,
  `CodexUsagePoller.swift`, `CodexSnapshotUpdater.swift`, the app shell, and
  installer. The [renewed audit](2026-09-06_pr-4_polling_audit.md) records
  passing regression tests, coverage, and successful installed captures after
  the replacement fix. The [Now block](../index.md) tracks handoff status.
  [PRAudit:2]

## Alternatives considered

- Wiring the Stop hook was rejected because completed turns do not guarantee
  a 30-second account refresh across active sessions. [ADR:codex-polling]
- A persistent App Server would add lifecycle state; the existing bounded
  client supports a short-lived process per poll. [ADR:codex-polling]
- Direct provider requests with extracted credentials remain prohibited.
  [ADR:codex-polling]
- Reusing Claude's monotonic merge is rejected for Codex because a corrected
  reset time can reject a current authoritative read. [ADR:codex-polling]

## Consequences

The [original PR 4 audit](2026-09-06_pr-4_audit.md) is historical; the
[renewed polling audit](2026-09-06_pr-4_polling_audit.md) covers this revision.
Live checks include three observed automatic captures, a usage increase from
24% to 26%, and direct reads bracketing a matching 26% app capture with the
same reset. [PRAudit:2] A
successful poll confirms a new account read; it does not guarantee that
upstream accounting changes after every individual token. [ADR:codex-polling]

Related: [installation runbook](../entities/runbooks/install_and_wire.md)

**Last updated**: 2026-09-06
