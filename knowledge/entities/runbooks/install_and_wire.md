# Runbook: install and wire the meter

## Requirements

- macOS 14 or later and Swift 6 from the Command Line Tools.
- Claude Code for the Claude meter.
- For the Codex meter, an authenticated Codex CLI with an active subscription
  and App Server rate-limit support. `codex` must be on `PATH` during install.

## Steps

1. `make test` must pass. Do not use bare `swift test`.
2. Run `make install`. It builds and launches the app, installs
   `~/.local/bin/ai-usage-meter-hook`, and saves the stable Codex launcher path
   atomically with mode `0600` in
   `~/Library/Application Support/ai-usage-meter/codex-launcher`.
3. Run `make snippet` if the install output is no longer visible.
4. Paste the printed Claude `statusLine` object into
   `~/.claude/settings.json` by hand.
5. When upgrading the preview, manually remove only the obsolete
   `ai-usage-meter-codex-hook` entry from `~/.codex/hooks.json`, preserving
   other hooks. The installer removes that executable and prints a reminder.
6. Add the printed native footer configuration to `~/.codex/config.toml`:

       [tui]
       status_line = ["model-with-reasoning", "context-remaining"]

The installer never edits any of these files, consistent with the
[hook decision](../../decisions/2026-09-05_hook-is-a-swift-target.md).
When Codex is missing from `PATH`, installation removes stale launcher
configuration and the old hook executable while preserving the usage snapshot.
Rerun `make install` with Codex available to enable polling. [ADR:codex-polling]

## Checks

- Send one prompt in Claude Code. The CLI status line shows
  `<model> · <effort> · ⛁ <n>%` (effort is omitted when unavailable),
  `snapshot.json` contains `providers.claude`, and its menu-bar item follows
  on the next 30-second refresh.
- Codex usage is fetched at app launch and every 30 seconds, even without a
  completed turn or configured hook. Observe at least three cycles: successful
  captures renew the displayed age even when the percentage stays unchanged.
  Compare the one 7-day percentage with the same weekly window in Codex
  `/status`; its native footer separately shows model, effort, and context.
  A renewed timestamp alone is insufficient: verify the percentage and reset
  window too. The initial live poll exposed a reset-time merge bug that kept
  12% despite a 23% current account response. Successful Codex reads must
  replace its provider entry; Claude's session merge remains unchanged.
  [ADR:codex-polling]
- If Codex age keeps increasing or the panel shows `Refresh unavailable`,
  check that the configured launcher still exists, is executable, and Codex is
  signed in. Rerun `make install` with `codex` on `PATH` to refresh the launcher
  configuration. A failed read leaves the prior value and capture time intact.
- `cat "$HOME/Library/Application Support/ai-usage-meter/snapshot.json"`
  shows available provider windows with ISO-8601 dates.
- Both menu-bar items use the same color rules: numbers become bold at 75
  percent, and the full provider label flips to black on white at 90 percent.
  Claude displays its 5-hour and 7-day windows; Codex Pro displays only 7-day.
- Login Items lists "AI Usage Meter".
- The Claude 7-day number equals the `/usage` row "Current week (all models)",
  not the per-model row.

These Codex checks are repeatable acceptance checks for the
[app-owned polling change](../../decisions/2026-09-06_codex-app-owned-polling.md);
the [renewed audit](../../decisions/2026-09-06_pr-4_polling_audit.md) records
successful installed captures and matching direct reads after the merge fix.
User monitoring and merge status remain in the [Now block](../../index.md).
[PRAudit:2] A poll is a bounded, short-lived App Server
exchange off the main actor. An actor busy flag and a separate process poll
lock prevent overlapping fetches. The snapshot lock only covers the final
provider replacement/write, preserving independent Claude writes.
[ADR:codex-polling]

## Credential check

The app and Claude hook must not read or log API keys, OAuth tokens, Codex
`auth.json`, Keychain values, or Codex hook stdin. Codex usage is obtained by
launching the user's authenticated Codex CLI as an App Server over stdio.

## Undo

- Run `make uninstall`; this also removes the saved launcher configuration.
- Remove the Claude `statusLine` entry and, if desired, the Codex `[tui]`
  status-line fields by hand. Remove any leftover preview Codex hook entry
  without disturbing unrelated hooks. The snapshot remains on disk.

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
