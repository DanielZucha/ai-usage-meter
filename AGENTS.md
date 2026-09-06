# AGENTS.md -- ai-usage-meter

## Project goal

A personal macOS menu-bar meter for Claude Code and Codex subscription usage,
owned and maintained by Daniel, that never handles a credential. Claude shows
its 5-hour and 7-day windows; Codex Pro shows its 7-day window. Both use native
provider glyphs, shared 75/90 percent styling, reset countdowns, and launch at
login.

## Architecture

- Claude Code status-line input and a Codex asynchronous `Stop` hook write a
  provider-keyed JSON snapshot; the menu-bar app is read-only.
- `Sources/MeterCore` owns schemas, provider clients, merge/storage, and display
  rules. `Sources/MeterHook`, `Sources/MeterCodexHook`, and
  `Sources/AIUsageMeter` are thin executables.
- Build with `swift build`; test only with `make test`; install with
  `make install`.
- Decisions live under `knowledge/decisions/`; live state is the Now block in
  `knowledge/index.md`; wiring details are in
  `knowledge/entities/runbooks/install_and_wire.md`.

## Boundaries

- Never read API keys, OAuth tokens, Codex `auth.json`, the macOS Keychain, or
  conversation-bearing Codex hook input.
- Never call provider usage endpoints directly with extracted credentials.
  Codex usage must remain inside the user's authenticated Codex process.
- Installers never edit Claude or Codex configuration; they print snippets for
  manual review. Codex hooks must be reviewed and trusted through `/hooks`.
- Hook failures are silent and best effort. Network/process work happens before
  the snapshot lock; a lock timeout skips the update.
- The Codex Pro display and persisted provider state are weekly-only. Claude
  retains both 5-hour and 7-day windows.

## Repository conventions

- Swift and SwiftPM only; no third-party runtime dependencies.
- Preserve provider isolation when merging snapshots.
- Keep the official provider SVG assets byte-identical and maintain ownership,
  provenance, and non-endorsement notices.
- No secrets, account identifiers, conversation text, or raw authenticated
  responses in tests, logs, docs, or commits.
