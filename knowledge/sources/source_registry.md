# Source Registry
<!-- One row per immutable input under docs/. -->

| id | path | type | added | summary |
|----|------|------|-------|---------|
| S1 | docs/2026-09-05_usage-data-sources.md | fact report | 2026-09-05 | Local and web facts on how Claude usage is exposed on macOS |
| S2 | docs/2026-09-05_statusline-probe.md | capture report | 2026-09-05 | Live statusline payloads from six sessions; findings F1-F6 plus a sample payload |
| S3 | docs/2026-09-05_statusline-probe-2.md | capture report | 2026-09-05 | Per-model weekly window is absent from the statusline payload; builder emits five_hour, seven_day, spend_limit only |
| S4 | docs/2026-09-06_codex-data-source.md | fact report | 2026-09-06 | Verified Codex App Server rate-limit source, async hook, native TUI signage, and official glyph |
| S5 | docs/2026-09-06_codex-pro-weekly-limit.md | correction capture | 2026-09-06 | Live Codex Pro refresh and approved weekly-only display contract |

### S4 claims

- C1: App Server's initialized JSONL session exposes `account/rateLimits/read` without experimental opt-in.
- C2: The initial probe returned 300- and 10080-minute windows with epoch-second resets; S5 supersedes its persistence interpretation for Codex Pro.
- C3: An async root `Stop` hook is best effort and can complete out of order or be cancelled on exit.
- C4: Native TUI fields `model-with-reasoning` and `context-remaining` provide model, effort, and context signage.
- C5: The official Codex IDE Blossom asset is embedded exactly and used under OpenAI's conditional brand guidance.
- C6: The App Server client is bounded, silent, and incrementally framed; automated tests use a subprocess fixture for handshake/failure/reaping behavior, while the authenticated probe is recorded separately.

### S5 claims

- C1: The current authenticated Codex Pro refresh returned a 10080-minute window and no 300-minute window.
- C2: Codex Pro is represented by one 7-day value and panel row; Claude retains both existing windows.

Related: [Codex App Server decision](../decisions/2026-09-06_codex-app-server-snapshot.md)

**Last updated**: 2026-09-06
