# Gaps and leads

## Open
- `schema_version` is written but never inspected on read, and there is no
  migration hook; becomes a P3 debt issue at the first `currentSchemaVersion`
  bump.

## Closed
- 2026-09-05: whether `rate_limits` arrives at all. Yes; see
  [the merge rule](../decisions/2026-09-05_snapshot-merge-rule.md) for
  the cross-session wrinkle the probe exposed.

## Leads
- Notifications at thresholds were deferred, not rejected. Trigger: a
  limit surprises Daniel in use.
- A second provider (Codex) would be an additional writer into the same
  provider-keyed snapshot. Nothing in version one should assume one provider.
- Exact-multiple countdown boundaries are untested (e.g. remaining time
  landing precisely on a day, hour, or minute mark). No trigger yet.
- No test exercises the lock being released when `body` throws inside
  `SnapshotStore.withExclusiveLock`. No trigger yet.
- The Quit menu item's keyboard shortcut (`q`) has no visible affordance in
  the dropdown. No trigger yet.
- The Fable per-model weekly window is not in the statusline payload on
  Claude Code 2.1.261 (probe 2, [S3:F1][S3:F2]); the only source is the
  usage API, which the data-source decision forbids. Trigger: a Claude Code
  release that forwards `model_scoped` or `seven_day_overage_included` into
  the statusline `rate_limits` block; then a third window is a small task.
- A `resets_at` unit change upstream (seconds to milliseconds or ISO) would
  render a clamped huge countdown or drop the window silently. Trigger:
  Claude Code changes the unit; then reject values outside now-1d..now+60d.

Related: [data-source decision](../decisions/2026-09-05_data-source-statusline-snapshot.md)

**Last updated**: 2026-09-05
