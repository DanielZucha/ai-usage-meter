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
2. Codex runs `ai-usage-meter-codex-hook` from an asynchronous `Stop` hook
   after a completed turn. The hook discards its stdin without parsing or
   logging it, launches the configured Codex executable as an
   [App Server](https://learn.chatgpt.com/docs/app-server), requests
   `account/rateLimits/read`, and merges the result into the same snapshot.
3. The app re-reads the snapshot every 30 seconds and presents two menu-bar
   items. Claude is followed by `<5-hour>% · <7-day>%`; Codex is followed by
   `<7-day>%`. A number turns bold at 75 percent; at 90 percent the whole label
   flips to black on white. Clicking either item opens its provider panel with
   one pill bar per visible window, snapshot age, and Quit.

Windows that have reset show 0 percent until the next provider update. A
missing provider snapshot shows dashes. Codex freshness is best effort: its
hook is intentionally asynchronous, so a hook can finish after a later turn
or be interrupted when a session exits; the app always shows the captured
snapshot age.

## Credential boundary

Neither hook nor the app reads API keys, OAuth tokens, Codex `auth.json`, or
the macOS Keychain. Claude supplies usage in status-line stdin. For Codex, the
hook starts the user's own authenticated Codex CLI process and communicates
with it over stdio; credential handling remains inside Codex.

## Install

Requirements:

- macOS 14 or later and Swift 6 from the Command Line Tools.
- Claude Code for the Claude meter.
- For the Codex meter, a Codex CLI that supports App Server rate-limit reads,
  signed in with an active Codex subscription. `codex` must be on `PATH` when
  `make snippet` runs.

Run:

    make test
    make install

Tests must run through `make test`, never bare `swift test`: the Command Line
Tools' SwiftPM does not wire in swift-testing on its own, and the Makefile adds
the required flags.

`make install` builds and launches `AI Usage Meter.app`, registers it to launch
at login, installs
`~/.local/bin/ai-usage-meter-hook` and
`~/.local/bin/ai-usage-meter-codex-hook`, and then runs `make snippet`.
When `codex` is available on `PATH`, the snippet command prints three blocks
for you to apply manually; otherwise it prints the Claude block and explains
how to rerun the command for Codex:

1. The Claude `statusLine` entry for `~/.claude/settings.json`.
2. A Codex asynchronous `Stop` hook entry to merge into
   `~/.codex/hooks.json`. The printed command pins the absolute paths of both
   the installed hook and the stable Codex launcher.
3. The native Codex footer configuration for `~/.codex/config.toml`:

       [tui]
       status_line = ["model-with-reasoning", "context-remaining"]

The Codex footer uses Codex's native
[status-line configuration](https://learn.chatgpt.com/docs/config-file/config-sample)
to show the CLI model, reasoning effort, and remaining context. The usage hook
is a separate [Codex `Stop` hook](https://learn.chatgpt.com/docs/hooks).
Neither `make install` nor `make snippet` edits Claude or Codex configuration.
After adding the Codex hook, run `/hooks` inside Codex, review it, and mark it
trusted. Codex skips unmanaged hooks until they are trusted. Run `make snippet`
again whenever you need the current manual configuration.

`make uninstall` removes the app and both installed hook executables. Remove
their Claude and Codex configuration entries by hand; the snapshot is retained.

## Layout

    Sources/MeterCore       schema, provider clients, merge, storage, formatting
    Sources/MeterHook       Claude status-line executable
    Sources/MeterCodexHook  Codex App Server Stop-hook executable
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
