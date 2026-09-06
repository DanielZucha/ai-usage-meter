# Codex Pro weekly-limit correction

Captured 2026-09-06 while visually validating the Codex counterpart. No
account identifier, credential, conversation text, or raw authenticated
response is retained here.

## Findings

- **C1.** A current authenticated App Server refresh for the active Codex Pro
  subscription produced a 10080-minute Codex window and no 300-minute window.
  The resulting snapshot contained `seven_day` at 10 percent and no
  `five_hour` field.
- **C2.** Daniel confirmed that the Pro subscription is weekly-only and
  approved a provider-specific display contract: Codex shows one 7-day value
  and one 7-day panel row, while Claude keeps its 5-hour and 7-day windows.
