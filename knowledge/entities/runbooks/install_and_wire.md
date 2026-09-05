# Runbook: install and wire the meter

## Steps
1. `make test` must pass.
2. `make install` builds, bundles, installs to `~/Applications`, copies
   the hook to `~/.local/bin/ai-usage-meter-hook`, launches the app, and
   prints the settings snippet.
3. Paste the printed `statusLine` object into `~/.claude/settings.json`
   by hand. The installer never edits that file by
   [decision](../../decisions/2026-09-05_hook-is-a-swift-target.md).
4. Send one prompt in any Claude Code session. Every running session picks
   the new statusline up immediately and the snapshot appears within the
   same second; the menu bar updates on its next 30-second tick.

## Checks
- `cat "$HOME/Library/Application Support/ai-usage-meter/snapshot.json"`
  shows `providers.claude` with two windows and ISO-8601 dates.
- The terminal status bar shows `<model> · ctx <n>% · 5h <n>% · 7d <n>%`;
  the menu bar follows within 30 seconds.
- Login Items lists "AI Usage Meter".
- The 7-day number equals the `/usage` row "Current week (all models)", not
  the per-model row.

## Undo
- `make uninstall`, then remove the `statusLine` entry from settings.json.

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

Related: [snapshot contract](../../decisions/2026-09-05_snapshot-contract.md)

**Last updated**: 2026-09-05
