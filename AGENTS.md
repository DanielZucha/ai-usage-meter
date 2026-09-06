# AGENTS.md -- ai-usage-meter

## Project goal

A personal macOS menu-bar meter for Claude Code and Codex subscription usage,
owned and maintained by Daniel, that never handles a credential. Claude shows
its 5-hour and 7-day windows; Codex Pro shows its 7-day window. Both use native
provider glyphs, shared 75/90 percent styling, reset countdowns, and launch at
login.

## Architecture

- Claude Code status-line input writes its provider snapshot. The app polls
  Codex at launch and every 30 seconds through the authenticated CLI App Server.
- `Sources/MeterCore` owns schemas, provider clients, merge/storage, and display
  rules, `CodexSnapshotUpdater`, `CodexUsagePoller`, and `CodexLauncher`.
  `Sources/MeterHook` and `Sources/AIUsageMeter` are thin executables.
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
- Installers never edit Claude or Codex configuration. They persist the stable
  Codex launcher in the meter's support directory with mode 0600.
- Codex process work runs off the main actor with bounded execution and no
  overlapping polls. Network/process work precedes the snapshot lock.
- Failed Codex refreshes preserve the last successful value and capture time;
  the panel shows `Refresh unavailable`. Claude hook failures remain silent.
- The Codex Pro display and persisted provider state are weekly-only. Claude
  retains both 5-hour and 7-day windows.

## Repository conventions

- Swift and SwiftPM only; no third-party runtime dependencies.
- Preserve provider isolation: successful serialized Codex reads replace the
  Codex entry; Claude retains its monotonic cross-session merge.
- Keep the official provider SVG assets byte-identical and maintain ownership,
  provenance, and non-endorsement notices.
- No secrets, account identifiers, conversation text, or raw authenticated
  responses in tests, logs, docs, or commits.
