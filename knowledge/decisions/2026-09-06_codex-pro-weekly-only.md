# Decision: Codex Pro displays only the weekly limit

## What was decided

Codex decodes and displays only its 10080-minute 7-day subscription window.
Its menu-bar label contains one percentage and its panel contains one 7-day
row. Claude remains unchanged with its 5-hour and 7-day windows. Legacy Codex
5-hour snapshot data is ignored by the display and cannot trigger threshold
styling. [S5:C1][S5:C2]

## Why

The current authenticated Pro refresh returned only a weekly window, and the
account owner confirmed that Pro should be represented as weekly-only. This
supersedes the window-selection portion of the earlier
[App Server decision](2026-09-06_codex-app-server-snapshot.md) without changing
its transport, credential, freshness, or failure boundaries. [S5:C1][S5:C2]

## Evidence

The correction capture records the live weekly-only snapshot and Daniel's
approved provider-specific display contract. Decoder and display tests retain
a synthetic 300-minute or stale 5-hour value specifically to prove it is
ignored. [S5:C1][S5:C2]

## Alternatives considered

- Rendering a missing 5-hour window as `--` was rejected because it presents a
  non-existent Pro limit as temporarily unavailable.
- Keeping 300-minute decoding but hiding it only in the UI was rejected because
  newly captured Codex snapshots should match the weekly-only product contract.
- Removing the shared `five_hour` schema field was rejected because Claude
  still uses it and the provider-keyed schema already supports optional fields.

Related: [install and wiring runbook](../entities/runbooks/install_and_wire.md)

**Last updated**: 2026-09-06
