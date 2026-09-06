# ai-usage-meter

A credential-free macOS menu-bar meter for Claude Code and Codex subscription
usage. It shows a separate provider glyph for each service: Claude has 5-hour
and 7-day utilization, while Codex Pro has its 7-day utilization.

## How it works

1. Claude Code runs `ai-usage-meter-hook` as its status-line command after
   each API response. The hook merges the documented `rate_limits` input into
   `~/Library/Application Support/ai-usage-meter/snapshot.json` and prints the
   CLI line `<model> · <effort> · ⛁ <context>%` (without the effort field
   when Claude Code omits it).
2. The app fetches Codex usage at launch and every 30 seconds. It launches
   the configured Codex executable as a short-lived
   [App Server](https://learn.chatgpt.com/docs/app-server), requests
   `account/rateLimits/read`, and merges a successful result into the same
   snapshot. The bounded process runs away from the UI thread. Overlapping
   polls are skipped, with a separate process lock protecting collection.
   Each successful account read replaces the Codex provider entry, including
   its percentage and reset time; Claude's session merge rules are unchanged.
3. The app re-reads the snapshot every 30 seconds and presents two menu-bar
   items. Claude is followed by `<5-hour>% · <7-day>%`; Codex is followed by
   `<7-day>%`. A number turns bold at 75 percent; at 90 percent the whole label
   flips to black on white. Clicking either item opens its provider panel with
   one pill bar per visible window, snapshot age, and Quit.

Windows that have reset show 0 percent until the next provider update. A
missing provider snapshot shows dashes. The Codex panel's age means time since
the last successful capture, even if the percentage was unchanged. A failed
refresh preserves the prior value and timestamp and shows `Refresh unavailable`.
Polling continues while the app runs, independently of Codex session hooks.

## Credential boundary

Neither the Claude hook nor the app reads API keys, OAuth tokens, Codex `auth.json`, or
the macOS Keychain. Claude supplies usage in status-line stdin. For Codex, the
app starts the user's own authenticated Codex CLI process and communicates
with it over stdio; credential handling remains inside Codex.

## Install

Requirements:

- macOS 14 or later and Swift 6 from the Command Line Tools.
- Claude Code for the Claude meter.
- For the Codex meter, a Codex CLI that supports App Server rate-limit reads,
  signed in with an active Codex subscription. `codex` must be on `PATH` when
  `make install` runs.

Run:

    make test
    make install

Tests must run through `make test`, never bare `swift test`: the Command Line
Tools' SwiftPM does not wire in swift-testing on its own, and the Makefile adds
the required flags.

`make install` builds and launches `AI Usage Meter.app`, registers it to launch
at login, installs `~/.local/bin/ai-usage-meter-hook`, and then runs
`make snippet`. It saves the stable Codex launcher path atomically in
`~/Library/Application Support/ai-usage-meter/codex-launcher` with mode `0600`.
If Codex is missing or its launcher moves, install from a shell where `codex`
is available on `PATH`. The app retains its last successful reading when the
configured launcher is unavailable.
Installing without `codex` on `PATH` removes any stale launcher configuration;
Claude remains available. Rerun the install with Codex available to enable
polling.

The snippet command prints configuration for you to apply manually:

1. The Claude `statusLine` entry for `~/.claude/settings.json`.
2. The native Codex footer configuration for `~/.codex/config.toml`:

       [tui]
       status_line = ["model-with-reasoning", "context-remaining"]

The Codex footer uses Codex's native
[status-line configuration](https://learn.chatgpt.com/docs/config-file/config-sample)
to show the CLI model, reasoning effort, and remaining context.
Neither `make install` nor `make snippet` edits Claude or Codex configuration.
Run `make snippet` again whenever you need the current manual configuration.

Upgrading from the preview removes the obsolete
`~/.local/bin/ai-usage-meter-codex-hook` executable. Remove only that hook's
entry from `~/.codex/hooks.json` manually, preserving unrelated hooks. The
installer prints this reminder; automatic Codex polling needs no `Stop` hook.

`make uninstall` removes the app, launcher configuration, and installed hook executables. Remove
their configuration entries by hand; the snapshot is retained.

## Layout

    Sources/MeterCore       schema, provider clients, polling, launcher, storage
    Sources/MeterHook       Claude status-line executable
    Sources/AIUsageMeter    the two-item SwiftUI MenuBarExtra shell
    Tests/MeterCoreTests    Swift Testing suites
    assets/                 source SVGs for the embedded provider glyphs
    packaging/              Info.plist for the app bundle
    knowledge/              project wiki: decisions, runbooks, log

## Codex glyph attribution

The Codex Blossom SVG is reproduced from OpenAI's official
[Codex IDE extension](https://marketplace.visualstudio.com/items?itemName=openai.chatgpt).
OpenAI owns its names and marks; the glyph is used only to identify the Codex
provider. This project is independent and is not affiliated with, sponsored
by, or endorsed by OpenAI. See the official
[OpenAI brand guidelines](https://openai.com/brand/) and the repository's
[provider asset notice](assets/NOTICE.md).
