# AGENTS.md -- ai-usage-meter

## Project goal

A personal macOS menu-bar meter for Claude Code subscription usage, owned and
maintained by Daniel, that never handles a credential. It shows Claude's
5-hour and 7-day windows with the Claude glyph, 75/90 percent styling, reset
countdowns, and launch at login. Codex support was removed on 2026-10-20
(`knowledge/decisions/2026-10-20_drop-codex-meter.md`); the snapshot stays
provider-keyed so a second provider is an additive change.

## Architecture

- Data path: Claude Code status-line hook -> snapshot JSON on disk -> menu-bar
  app. The hook is the only writer; the app is read-only.
- `Sources/MeterCore` owns schemas, merge/storage, and display rules and is
  the only tested target. `Sources/MeterHook` and `Sources/AIUsageMeter` are
  thin executables.
- Build with `swift build`; test only with `make test` (never bare
  `swift test` on this Mac); install with `make install`.
- Decisions live under `knowledge/decisions/`; live state is the Now block in
  `knowledge/index.md`; wiring details are in
  `knowledge/entities/runbooks/install_and_wire.md`.

## Boundaries

- Never read API keys, OAuth tokens, or the Keychain item "Claude
  Code-credentials". Never call `api/oauth/usage`. If a task seems to need
  either, stop and raise it as a decision.
- Installers never edit `~/.claude/settings.json`; they print the snippet.
- The hook fails quietly: it runs in Claude Code's render loop and must never
  block or emit stderr noise.

## Repository conventions

- Swift and SwiftPM only; no third-party runtime dependencies.
- Keep the Claude glyph string byte-identical to `assets/claude.svg`.
- No secrets, account identifiers, conversation text, or raw authenticated
  responses in tests, logs, docs, or commits.
