# AGENTS.md -- ai-usage-meter

## Phase

Personal tool in daily use; small, stable, maintained by Daniel.

## Product

A macOS menu-bar meter for Claude Code subscription usage that never handles
a credential. It shows Claude's 5-hour and 7-day windows with the Claude
glyph, 75/90 percent styling, reset countdowns, and launch at login. The
snapshot stays provider-keyed so a second provider is an additive change.

## Stack

- Swift 6, SwiftPM only (Command Line Tools, no Xcode); no third-party
  runtime dependencies.
- Data path: Claude Code status-line hook -> snapshot JSON on disk -> menu-bar
  app. The hook is the only writer; the app is read-only.
- `Sources/MeterCore` owns schemas, merge/storage, and display rules and is
  the only tested target. `Sources/MeterHook` and `Sources/AIUsageMeter` are
  thin executables.
- Build with `swift build`; test only with `make test` (bare `swift test`
  fails on this Mac); install with `make install`.

## Rules

- Never read API keys, OAuth tokens, or the Keychain item "Claude
  Code-credentials". Never call `api/oauth/usage`. If a task seems to need
  either, stop and raise it as a decision.
- Installers never edit `~/.claude/settings.json`; they print the snippet.
- The hook fails quietly: it runs in Claude Code's render loop and must never
  block or emit stderr noise.
- Keep the Claude glyph string byte-identical to `assets/claude.svg`.
- No secrets, account identifiers, conversation text, or raw authenticated
  responses in tests, logs, docs, or commits.

## Resources

- Wiki: `knowledge/`; live state is the Now block in `knowledge/index.md`.
- Decisions: `knowledge/decisions/` (Codex removal:
  `2026-10-20_drop-codex-meter.md`).
- Install, wiring, toolchain traps:
  `knowledge/entities/runbooks/install_and_wire.md`.
- Statusline contract: https://code.claude.com/docs/en/statusline
