# Decision: retire the meter

## What was decided

The meter is retired and uninstalled. The app, the hook, and the snapshot
are removed from this Mac, and the hook is unwired from the statusline. The
code stays on `main` as history. The credential boundary in AGENTS.md is
kept: polling `api/oauth/usage` was considered and rejected. [ADR:retire-meter]

## Why

Daniel now works mostly in the Claude desktop app's Code tab. The Code tab
runs hooks but not the `statusLine` command, and hook payloads carry no
`rate_limits`, so the meter cannot see in-app usage. [ADR:retire-meter]

## Evidence

On 2026-11-25 at 15:30Z, `snapshot.json` was last written 2026-11-24 15:51Z
(a terminal session). An in-app session had been running for several minutes
and had written nothing. [ADR:retire-meter]

## Alternatives considered

- Poll `api/oauth/usage` with the Keychain token from the app. Rejected: it
  breaks the credential boundary of the
  [data-source decision](2026-09-05_data-source-statusline-snapshot.md), and
  the endpoint is undocumented. [ADR:retire-meter]
- Keep it installed for terminal sessions only. Rejected: Daniel rarely uses
  the terminal now, so the meter would show stale numbers. [ADR:retire-meter]

## Reversal

`make install`, then restore the hook argument in `~/.claude/settings.json`:
`"command": "python3 ~/.claude/scripts/plan_status.py ~/.local/bin/ai-usage-meter-hook"`.
Revisit only if the desktop app starts running the statusline or exposes
usage to hooks.

**Last updated**: 2026-11-25
