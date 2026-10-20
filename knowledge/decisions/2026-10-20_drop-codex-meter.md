# Decision: drop the Codex meter

## What was decided

The app shows Claude only again. All Codex code, tests, the launcher
installer, and the Codex glyph asset are removed; source code returns to the
v0.1.0 state on `main`. Codex docs and decision pages stay as history.
Supersedes [App Server snapshot](2026-09-06_codex-app-server-snapshot.md),
[app-owned polling](2026-09-06_codex-app-owned-polling.md) and
[Pro weekly-only](2026-09-06_codex-pro-weekly-only.md). [ADR:drop-codex]

## Why

Daniel stopped the OpenAI subscription on 2026-10-20, so the Codex meter has
no data to show and its 30-second App Server poll is dead weight. [ADR:drop-codex]

## Evidence

`make test` passes 72 tests after the restore; `make install` relaunched the
app; the Codex launcher configuration and poll lock were removed from
Application Support. [ADR:drop-codex]

## Reversal

Restore the PR 4 code from merge commit `a0d27de` on `devel`.
