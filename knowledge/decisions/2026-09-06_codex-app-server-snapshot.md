# Decision: Codex usage comes from its authenticated App Server process

**Status**: App Server source retained; the Stop-hook scheduling and freshness
policy below is SUPERSEDED by
[app-owned polling](2026-09-06_codex-app-owned-polling.md). The original decision
is preserved as history. [ADR:codex-polling]

## What was decided

The Codex meter launches the user's configured Codex executable as a
short-lived App Server over stdio after an asynchronous root `Stop` hook. It
performs the initialize handshake, requests `account/rateLimits/read`, and
stores the 10080-minute weekly percentage/reset pair under `providers.codex`.
The earlier probe also exposed a 300-minute window, but the approved Pro
contract ignores it; that correction is recorded in the
[weekly-only decision](2026-09-06_codex-pro-weekly-only.md).
[S4:C1][S4:C2][S4:C3][S5:C1][S5:C2]

Codex's native TUI renders model, reasoning effort, and remaining context via
`model-with-reasoning` and `context-remaining`; the custom hook is responsible
only for subscription usage. [S4:C4]

## Why

This keeps credentials inside Codex itself: the meter never reads `auth.json`,
Keychain entries, tokens, account metadata, or conversation-bearing hook
input. The provider-keyed snapshot makes the new writer additive to the
existing [Claude source](2026-09-05_data-source-statusline-snapshot.md), while
the file lock covers only the final read-merge-write cycle.

## Reliability boundary

The process exchange is bounded by a monotonic timeout and output cap, and a
hung child is terminated and reaped. Invalid, partial, timed-out, or
unavailable responses leave the prior snapshot untouched. Because the hook is
asynchronous, the UI exposes capture age and treats freshness as best effort.
[S4:C3][S4:C6]

## Evidence

The App Server protocol, local authenticated probe, async-hook behavior,
native TUI fields, glyph provenance, and bounded-client validation are captured
in S4. The later weekly-only Pro correction is captured in S5 and changes only
which subscription window is retained and displayed. [S4:C1][S4:C2][S4:C3]
[S4:C4][S4:C5][S4:C6][S5:C1][S5:C2]

## Provider identity

The Codex menu item uses the exact official IDE Blossom only beside Codex
usage; it is not the product identity and does not imply endorsement.
[S4:C5] This extends the existing
[embedded-glyph decision](2026-09-05_glyph-embedded-svg-string.md).

## Alternatives considered

- Reading Codex credentials and polling a web endpoint was rejected because it
  breaks the project's credential-free boundary.
- Parsing transcripts was rejected because it does not provide authoritative
  subscription-window utilization.
- Replacing the native Codex footer was rejected because Codex already exposes
  the required model, effort, and context fields directly.

**Last updated**: 2026-09-06
