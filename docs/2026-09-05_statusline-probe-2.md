# Statusline probe 2 -- per-model weekly window

Run 2026-09-05 17:03-17:10 UTC on Claude Code 2.1.261 (Max plan), after
Daniel asked for the Fable weekly usage as a third meter. The installed
hook was wrapped by a tee script for a few minutes (settings.json
untouched); two payloads were captured, one of them after opening `/usage`.
Facts only.

## Findings

- F1. Both payloads carry `rate_limits.five_hour` and `rate_limits.seven_day`
  only. No per-model key, and opening `/usage` first changed nothing.
- F2. The statusline builder in the 2.1.261 binary emits exactly three
  optional windows: `five_hour`, `seven_day`, and `spend_limit` (the last
  only when the API provider is a gateway). It reads them from the unified
  rate-limit response headers.
- F3. The `/usage` screen builds its "Current week (Fable)" row from the
  `limits[]` array of the usage API response, filtered by a server-side
  allowlist of overage-included models. That array is projected into a
  `model_scoped` field of a different, richer payload schema (the one that
  also carries `subscription_type` and `rate_limits_available`), not into
  the statusline payload.
- F4. The unified headers do carry a `seven_day_overage_included` window
  described in the binary as a per-model bucket, but the statusline builder
  does not forward it.

## Consequence

The Fable weekly window is not reachable from the statusline payload on
this version. Reaching it would require the usage API, which the
data-source decision forbids.
