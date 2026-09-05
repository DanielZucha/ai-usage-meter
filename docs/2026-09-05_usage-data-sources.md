# Claude usage data sources on macOS -- fact report

Gathered 2026-09-05 by two read-only fact-finding agents (local machine
inspection and web survey) during the founding grill session. Facts only;
decisions derived from them live in `knowledge/decisions/`.

## Local facts (this Mac, Claude Code 2.1.261)

- Credentials live only in the macOS Keychain, generic-password item with
  service name "Claude Code-credentials". No `~/.claude/.credentials.json`.
- `~/.claude/settings.json` has `statusLine: null`. No statusline script
  exists anywhere under `~/.claude`.
- `~/.claude/stats-cache.json` holds locally computed aggregates
  (per-model tokens, `costUSD`). It is history, not quota.
- Transcript JSONL records carry `message.usage` token fields and
  `requestId` but no cost and no rate-limit data. 2609 files, 1.6 GB.
- `strings` on the CLI binary shows it calls
  `api/oauth/usage?at_wall=1&skip_spend=1` and reads response headers
  prefixed `anthropic-ratelimit-unified-` (5h/7d utilization, reset,
  overage, grace). JSON keys present: `five_hour`, `seven_day`,
  `seven_day_opus`, `seven_day_sonnet`, `resets_at`.
- Toolchain: Swift 6.2.4 via Command Line Tools only (`xcodebuild`
  unavailable), Python 3.12.7 with uv, Node 25, Homebrew. SwiftBar, xbar,
  Hammerspoon not installed. jq present at /opt/anaconda3/bin/jq.

## Web facts

- Statusline stdin JSON (official docs, code.claude.com/docs/en/statusline)
  includes `rate_limits.five_hour` and `rate_limits.seven_day`, each with
  `used_percentage` and `resets_at`, for Pro/Max subscribers, populated
  after the first API response of a session. Each window can be absent
  independently and is dropped once `resets_at` passes. Also present:
  `context_window.used_percentage`, `cost.total_cost_usd`, model info.
- `GET https://api.anthropic.com/api/oauth/usage` with
  `Authorization: Bearer <accessToken>` and `anthropic-beta: oauth-2025-04-20`
  returns `five_hour`, `seven_day`, `seven_day_opus`, `seven_day_sonnet`
  (utilization 0-100, `resets_at` ISO-8601) and `extra_usage`. It is
  undocumented. Without a `claude-code/<version>` User-Agent it 429s;
  polling under about 3 minutes gets throttled
  (anthropics/claude-code#31021).
- External tools that refresh the OAuth token can invalidate Claude Code's
  copy; setting `CLAUDE_CODE_OAUTH_TOKEN` makes Claude Code delete the
  Keychain entry on exit (anthropics/claude-code#37512).
- No official subscription-usage API exists; the Admin API usage reports
  cover API-key organizations only (anthropics/claude-code#44328 open).
- Reference minimal implementation of the endpoint approach:
  grzegorz-raczek-unit8/claude-quota (SwiftBar plugin, read-only Keychain,
  no refresh). Larger tools: Maciek-roboblog/Claude-Code-Usage-Monitor
  (statusline as source of truth, provenance labels), ryoppippi/ccusage
  (transcripts only), tddworks/ClaudeBar (multi-provider native Swift),
  hamed-elfayome/Claude-Usage-Tracker (claude.ai web session, not CLI).
- In-app claude.ai chats count against the same unified 5h/7d quota, and
  the server-reported percentage includes them.

## Menu-bar host facts

- Native SwiftUI `MenuBarExtra` needs macOS 13+; a locally built app needs
  no notarization; launch at login via `SMAppService.mainApp.register()`.
- SwiftBar/xbar plugins encode the refresh interval in the filename.
- Menu-bar icons should be template images so they follow the light/dark
  menu bar.
