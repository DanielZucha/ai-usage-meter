# Decision: app refresh cadence and display rules

## What was decided
- Refresh: a 30-second timer re-reads the snapshot and recomputes the
  countdown. No file-system watcher.
- Bar: the Claude glyph as a template image, then the 5-hour and 7-day
  percentages, for example `42% · 18%`.
- Dropdown: one row per window with utilization and countdown to reset,
  snapshot age with source, Quit. Nothing per-session (context, cost stay
  in the terminal statusline).
- Thresholds, monochrome only: at 70 percent the affected number turns
  bold; at 90 percent the glyph fills solid. No color at any level, no
  notifications.
- Reset: once `resets_at` passes with no newer snapshot, that window shows
  zero. Absence before the first turn of a session leaves the previous
  snapshot standing. No snapshot at all shows the glyph with two dashes.
- Glyph: `assets/claude.svg` (single path, 24x24 viewBox, currentColor),
  rendered as a template image. The normal state is the outline of that
  path; the 90-percent state is the filled path.
- Both the meter and the Claude desktop app keep their asterisk; no
  variant glyph.

## Why
A half-minute lag is invisible on a menu-bar number and the timer is
needed for the countdown anyway. Daniel asked for a clear, modern,
minimalist look; a weight change and a fill are the alerts that idiom
allows. Utilization only changes when quota is consumed, so a stale
snapshot plus a local countdown is correct while idle.

## Evidence
- Statusline windows drop after `resets_at`. [S1]
- Menu-bar icons must be template images to follow light and dark bars. [S1]
- Daniel's menu bar screenshot, 2026-09-05: all icons monochrome template
  style, Claude desktop asterisk already present.

## Alternatives considered
- File-system watch: instant, about 20 more lines, rejected as unneeded.
- Color at thresholds (system red at 95 percent): rejected for the
  minimalist constraint.
- macOS notifications: deferred; add only if a limit surprises Daniel in use.
- Per-model 7-day rows: impossible, only the undocumented endpoint has them.

Related: [snapshot contract](2026-09-05_snapshot-contract.md),
[host decision](2026-09-05_host-native-swift-menubarextra.md)

**Last updated**: 2026-09-05
