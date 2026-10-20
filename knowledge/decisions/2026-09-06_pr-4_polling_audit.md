# Decision: the polling revision is ready for PR 4 update

**Status**: ACCEPTED for PR update; merge remains on hold for user monitoring
**Owner**: Daniel

## What was decided

The [app-owned polling revision](2026-09-06_codex-app-owned-polling.md) is
ready to update PR 4 after regression tests, installed live checks, and a
renewed six-role audit. This audit covers automatic collection and replacement
of serialized Codex account snapshots, while retaining Claude's existing
merge policy. It supersedes the applicability of the
[historical Stop-hook audit](2026-09-06_pr-4_audit.md). [PRAudit:2]

## Why

Two independent causes prevented correct freshness: no recurring Codex writer,
and Claude's merge rule rejecting a current Codex response with a one-second
earlier reset. Installed verification must therefore establish both recurring
capture and agreement of percentage/reset with current account reads. The
revised implementation satisfies these checks; user monitoring remains the
next product check. [PRAudit:2]

## Evidence

- The latest `make test` run with coverage enabled passes 108 Swift tests in
  17 suites plus shell installer/snippet tests. [PRAudit:2]
- Line coverage is 94.29% for MeterCore, 100% for CodexUsagePoller, 97.73%
  for CodexSnapshotUpdater, 86.21% for CodexLauncher, and 80.28% for MeterModel.
  Whole-package coverage is 75.87%, including unautomated
  SwiftUI and login integration. The whole package does not meet the 80%
  target; core and model coverage do. [PRAudit:2]
- The installed release produces observed automatic captures at 17:07:40 UTC
  (24%), 17:08:40 UTC (26%), and 17:09:10 UTC (26%) on 2026-09-06. Sampling
  every 31 seconds missed an intermediate capture; the sampled list is not
  an exhaustive timer trace. [PRAudit:2]
- A later unattended capture at 17:25:10 UTC still reports 26%, showing
  continued polling roughly ten minutes after the bracketed comparison.
  [PRAudit:2]
- A direct read at 19:15:08 CEST and another at 19:15:41 CEST both report
  26%, bracketing the app capture at 19:15:40 CEST. All three agree on the
  weekly reset `2026-09-13T14:26:00Z`. This is a sanitized comparison, not a
  stored authenticated response. [PRAudit:2]
- Claude's provider entry remains intact between Codex updates. No lingering
  App Server process is present at the process check. [PRAudit:2]
- Code, architecture, security, and critical reviewers APPROVE; documentation
  is CURRENT; Nextflow review is N/A. [PRAudit:2]
- PR 4 remains open. The cloud review check returns HTTP 404 because
  `claude.yml` is absent from the default branch; no automated cloud review
  is claimed. [PRAudit:2]

## Alternatives considered

- Treating a renewed timestamp alone as success is rejected because the first
  live deployment demonstrated a fresh timestamp alongside stale usage.
  [PRAudit:2]
- Applying Codex replacement to Claude is rejected because Claude receives
  concurrent session snapshots and requires its established monotonic merge.
  [PRAudit:2]
- Claiming package-wide 80% coverage is rejected: the measured denominator
  includes UI/login code outside automated coverage. [PRAudit:2]

## Remaining limitations

- Snapshot files retain inherited local permissions, observed as `0644`;
  reviewers classify this as a nonblocking LOW finding. [PRAudit:2]
- The timer is not invalidated; the current model has a single app lifetime.
  Reviewers classify this as a nonblocking LOW finding. [PRAudit:2]
- Energy cost of launching a short-lived App Server every 30 seconds is
  unmeasured. A process check is not a longitudinal leak or energy test.
  [PRAudit:2]
- Live agreement establishes the observed account values, not an upstream
  guarantee of accounting updates after every token. [PRAudit:2]

Related: [installation runbook](../entities/runbooks/install_and_wire.md),
[current state](../index.md)

**Last updated**: 2026-09-06
