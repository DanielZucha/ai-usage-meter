# ai-usage-meter

A macOS menu-bar meter for AI-subscription usage. Version one shows the
Claude Code 5-hour and 7-day rate-limit windows next to the Claude glyph in
the menu bar. The design keeps room for other providers (for example Codex)
later.

> Agent orientation lives in `CLAUDE.md`. Humans read this README.

## Why self-built

Public meters read the Claude Code OAuth token from the macOS Keychain and
poll an undocumented Anthropic endpoint. This meter never touches a
credential: a Claude Code statusline hook writes the official `rate_limits`
block to a local snapshot file, and the menu-bar app only reads that file.

## Layout

```
ai-usage-meter/
├── CLAUDE.md          # agent orientation
├── docs/              # immutable sources (fact reports, vendor docs)
├── knowledge/         # LLM wiki: decisions, entities, log (tooling flavor)
└── (Swift package added once the design is approved)
```

## Status

Design phase. See the Now block in `knowledge/index.md`.
