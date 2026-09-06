# Codex counterpart source findings

Captured 2026-09-06 for the Codex provider implementation. No account
identifier, credential, conversation text, or raw authenticated response is
retained here.

## Findings

- **C1.** Codex App Server uses JSONL over stdio and requires an `initialize`
  request followed by an `initialized` notification before ordinary requests.
  The installed Codex CLI's generated schema includes the non-experimental
  `account/rateLimits/read` request. Official protocol:
  <https://learn.chatgpt.com/docs/app-server>.
- **C2.** A local authenticated probe returned Codex rate limits in
  `rateLimitsByLimitId.codex`, with reset timestamps in epoch seconds and
  window durations of 300 and 10080 minutes. Those durations correspond to
  the meter's 5-hour and 7-day windows. The implementation retains only those
  window percentages and reset times.
- **C3.** Codex supports an asynchronous root `Stop` command hook. Async hooks
  can finish out of order and may be cancelled when a session exits, so hook
  freshness is best effort. Official hook configuration:
  <https://learn.chatgpt.com/docs/hooks>.
- **C4.** Codex's native TUI status line supports `model-with-reasoning` and
  `context-remaining`, providing model, effort, and context signage without a
  custom terminal renderer. Official configuration sample:
  <https://learn.chatgpt.com/docs/config-file/config-sample>.
- **C5.** The exact `blossom-black.svg` asset from OpenAI's official Codex IDE
  extension has SHA-256
  `8652777b55544c572ba445dd230a90c2e248611e92eaa77de5805e8d0561fc30`.
  It is used only to identify Codex, with OpenAI ownership and no endorsement
  acknowledged. Official extension:
  <https://marketplace.visualstudio.com/items?itemName=openai.chatgpt> and
  brand guidance: <https://openai.com/brand/>.
- **C6.** The client rejects unbounded timeout/output configurations, reads
  JSONL incrementally, suppresses App Server stderr, and terminates and reaps
  the direct child on every exit path. Tests cover the real handshake, exact
  failure modes, output overflow, timeout cleanup, and concurrent provider
  snapshot writes.
