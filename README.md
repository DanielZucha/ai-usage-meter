# ai-usage-meter

A macOS menu-bar meter for Claude Code's 5-hour and 7-day rate-limit
utilization. It never touches a credential: Claude Code's own statusline
hook writes a small snapshot file, and the menu-bar app reads that file.

## How it works

1. Claude Code runs `ai-usage-meter-hook` as its statusline command after
   every API response, passing the documented statusline JSON on stdin.
2. The hook merges the `rate_limits` block into
   `~/Library/Application Support/ai-usage-meter/snapshot.json` and prints
   one line back to the terminal: `Fable 5.1 · ctx 12% · 5h 21% · 7d 4%`.
3. The menu-bar app re-reads the snapshot every 30 seconds and shows the
   Claude glyph with `21% · 4%`. A number turns bold at 75 percent; at 90
   percent the whole label flips to black on a white background. Clicking
   the item opens a panel with one pill bar per window, the snapshot age,
   and Quit. Windows that have reset show 0 percent until the next turn.

## Install

Requires macOS 14 or later and Swift 6 from the Command Line Tools.

    make test
    make install

Tests must run through `make test`, never bare `swift test`: the Command
Line Tools' SwiftPM does not wire in swift-testing on its own, and the
Makefile adds the flags that make it work.

`make install` builds a release, assembles `AI Usage Meter.app`, copies it
to `~/Applications`, copies the hook to `~/.local/bin`, launches the app,
and prints the `statusLine` snippet for `~/.claude/settings.json`. Paste
that snippet yourself; the installer never edits that file. The app
registers itself to launch at login.

`make uninstall` removes the app and the hook.

## Layout

    Sources/MeterCore      schema, parsing, merge, storage, formatting (tested)
    Sources/MeterHook      the statusline executable
    Sources/AIUsageMeter   the SwiftUI MenuBarExtra shell
    Tests/MeterCoreTests   Swift Testing suites
    packaging/             Info.plist for the app bundle
    knowledge/             project wiki: decisions, runbooks, log
