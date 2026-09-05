# CLAUDE.md -- ai-usage-meter

> Coding style, git workflow, testing, security, memory protocol, agent
> rules: see ~/.claude/CLAUDE.md. This file: durable orientation only,
> per ~/.claude/rules/agent-docs.md. Target 40-60 lines.

## Project goal

A personal macOS menu-bar meter for AI-subscription usage, owned and
maintained by Daniel, that never handles a credential. Version one renders
Claude Code's 5-hour and 7-day rate-limit utilization. Done means: the glyph
and two numbers sit in the menu bar, update after every Claude Code turn,
count down to reset while idle, and launch at login.

## Ultimate-goal alignment

Every change must keep two properties: no credential is read, stored, or
transmitted by any part of this repo; and the snapshot contract stays
provider-keyed so a second provider is an additive change, not a rewrite.

## Architecture (pointers)

- Data path: Claude Code statusline hook -> snapshot JSON on disk -> menu-bar
  app. The hook is the only writer; the app is read-only.
- Package: `Sources/MeterCore` holds every rule and is the only tested
  target; `Sources/MeterHook` and `Sources/AIUsageMeter` are thin shells.
  Build with `swift build`, test with `make test` (never bare `swift test`
  on this Mac, see the runbook), ship with `make install`.
- Language: Swift, SwiftPM only (Command Line Tools, no Xcode on this Mac).
- Decisions: `knowledge/decisions/` (one page per non-obvious choice).
- Data sources and their sharp edges: `docs/2026-09-05_usage-data-sources.md`
  and `docs/2026-09-05_statusline-probe.md`.
- Install and wiring steps: `knowledge/entities/runbooks/install_and_wire.md`.

## Session rules

- Never read the Keychain item "Claude Code-credentials" from code or tests.
  Never call `api/oauth/usage`. If a task seems to need either, stop and
  raise it as a decision.
- Never write to `~/.claude/settings.json` from an installer; print the
  snippet and let the user apply it.
- Fail quietly in the hook: it runs inside Claude Code's render loop and must
  never block or emit stderr noise.

## Resources

- Knowledge wiki: `knowledge/` (index auto-injected; contract in
  ~/.claude/rules/llm-wiki.md). Flavor: tooling.
- Live state: see the Now block in knowledge/index.md (auto-injected).
- Statusline contract: https://code.claude.com/docs/en/statusline
