# Gaps and leads

## Open
- Whether `rate_limits` actually arrives in the statusline JSON on this
  account and CLI version, and how quickly after a prompt. Needs the probe
  (see Now block). [S1]
- Snapshot behaviour when a window is absent because it was dropped after
  `resets_at`: the meter must treat absence-after-reset as zero, not as
  missing data. [S1]

## Leads
- A second provider (Codex) would be an additional writer into the same
  provider-keyed snapshot. Nothing in version one should assume one provider.

Related: [data-source decision](../decisions/2026-09-05_data-source-statusline-snapshot.md)

**Last updated**: 2026-09-05
