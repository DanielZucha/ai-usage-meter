# Gaps and leads

## Open
- None. The probe closed the last one: `rate_limits` arrives with both
  windows on this account and CLI version, and the settings change was
  picked up live by every running session. [S2:F1][S2:F3]

## Closed
- 2026-09-05: whether `rate_limits` arrives at all. Yes; see
  [the merge rule](../decisions/2026-09-05_snapshot-merge-rule.md) for
  the cross-session wrinkle the probe exposed.

## Leads
- Notifications at thresholds were deferred, not rejected. Trigger: a
  limit surprises Daniel in use.
- A second provider (Codex) would be an additional writer into the same
  provider-keyed snapshot. Nothing in version one should assume one provider.

Related: [data-source decision](../decisions/2026-09-05_data-source-statusline-snapshot.md)

**Last updated**: 2026-09-05
