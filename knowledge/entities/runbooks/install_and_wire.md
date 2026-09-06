# Runbook: install and wire the meter

## Requirements

- macOS 14 or later and Swift 6 from the Command Line Tools.
- Claude Code for the Claude meter.
- For the Codex meter, an authenticated Codex CLI with an active subscription
  and App Server rate-limit support. `codex` must be on `PATH` while rendering
  the configuration snippet.

## Steps

1. `make test` must pass. Do not use bare `swift test`.
2. Run `make install`. It builds and launches the app and installs both hooks:
   `~/.local/bin/ai-usage-meter-hook` and
   `~/.local/bin/ai-usage-meter-codex-hook`.
3. Run `make snippet` if the install output is no longer visible.
4. Paste the printed Claude `statusLine` object into
   `~/.claude/settings.json` by hand.
5. Merge the printed asynchronous `Stop` hook entry into the `Stop` array in
   `~/.codex/hooks.json`. Keep the absolute hook and Codex executable paths
   printed by the command.
6. Start Codex, run `/hooks`, review the new hook, and mark it trusted. Codex
   skips unmanaged hooks until this review is complete.
7. Add the printed native footer configuration to `~/.codex/config.toml`:

       [tui]
       status_line = ["model-with-reasoning", "context-remaining"]

The installer never edits any of these files, consistent with the
[hook decision](../../decisions/2026-09-05_hook-is-a-swift-target.md).

## Checks

- Send one prompt in Claude Code. The CLI status line shows
  `<model> · <effort> · ⛁ <n>%` (effort is omitted when unavailable),
  `snapshot.json` contains `providers.claude`, and its menu-bar item follows
  on the next 30-second refresh.
- Complete one Codex turn. Its native footer shows model plus reasoning and
  remaining context, and the asynchronous hook adds `providers.codex` on a
  best-effort basis. The Codex menu-bar item follows on the next refresh with
  one 7-day percentage and one 7-day panel row.
- If the Codex age keeps increasing, run `/hooks` and verify the `Stop` hook is
  present, enabled, and trusted. The app polls the snapshot every 30 seconds;
  it cannot create a new Codex snapshot when the hook has not run.
- `cat "$HOME/Library/Application Support/ai-usage-meter/snapshot.json"`
  shows available provider windows with ISO-8601 dates.
- Both menu-bar items use the same color rules: numbers become bold at 75
  percent, and the full provider label flips to black on white at 90 percent.
  Claude displays its 5-hour and 7-day windows; Codex Pro displays only 7-day.
- Login Items lists "AI Usage Meter".
- The Claude 7-day number equals the `/usage` row "Current week (all models)",
  not the per-model row.

The Codex `Stop` hook is asynchronous. Its snapshot can lag, complete out of
turn order, or be interrupted when a session exits; use the age displayed in
the provider panel when assessing freshness.

## Credential check

The app and hooks must not read or log API keys, OAuth tokens, Codex
`auth.json`, Keychain values, or Codex hook stdin. Codex usage is obtained by
launching the user's authenticated Codex CLI as an App Server over stdio.

## Undo

- Run `make uninstall`.
- Remove the Claude `statusLine` entry, the Codex `Stop` hook entry, and the
  Codex `[tui]` status-line fields by hand. The snapshot remains on disk.

## Toolchain traps

1. Two `*.private.swiftinterface` files from a 2024 Command Line Tools
   release survived every later update inside
   `/Library/Developer/CommandLineTools/usr/lib/swift/pm/ManifestAPI/PackageDescription.swiftmodule/`.
   swiftc prefers a private interface when one exists, so manifests
   compiled against a 2024 API and failed to link against the current
   dylib with `Undefined symbols ... Package.__allocating_init`. Updating
   the tools did not remove them; moving them to
   `~/clt-stale-private-interfaces/` did. `SWIFTPM_CUSTOM_LIBS_DIR` is not
   a workaround. Resolved 2026-09-05.
2. The Command Line Tools' SwiftPM passes the swift-testing framework
   directory with `-I` instead of `-F` and adds no rpath, so bare
   `swift test` fails with `no such module 'Testing'`. Putting the search
   paths into `Package.swift` is worse: SwiftPM's generated runner is
   guarded by `#if canImport(Testing)` and never sees manifest flags, so
   the suite silently runs zero tests and exits 0. `make test` passes
   `-Xswiftc -F` plus two `-Xlinker -rpath` flags and is the only supported
   way to run the tests here. Standing since 2026-09-05.

Related: [snapshot contract](../../decisions/2026-09-05_snapshot-contract.md),
[display rules](../../decisions/2026-09-05_app-refresh-and-display-rules.md),
[Codex weekly-only decision](../../decisions/2026-09-06_codex-pro-weekly-only.md)

**Last updated**: 2026-09-06
