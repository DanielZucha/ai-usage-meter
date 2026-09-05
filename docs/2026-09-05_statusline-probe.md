# Statusline probe -- capture report

Run 2026-09-05 11:43-11:48 UTC on Claude Code 2.1.261 (Max plan). A
temporary `statusLine` entry in `~/.claude/settings.json` pointed at a
script that appended every stdin payload to a file; the entry was removed
afterwards and settings.json restored byte-identical. Facts only;
decisions derived from them live in `knowledge/decisions/`.

## Findings

- F1. `rate_limits` arrives, with both `five_hour` and `seven_day`, in every
  one of the 14 payloads captured. Each window carries `used_percentage`
  (integer) and `resets_at`.
- F2. `resets_at` is Unix epoch seconds (integer), not ISO-8601. Captured
  values: five-hour 1788617400 (2026-09-05 14:10 UTC), seven-day
  1789160400 (2026-09-11 21:00 UTC).
- F3. The settings change was picked up live. Six running sessions
  re-rendered within the same second (11:43:08) without any prompt; their
  concurrent appends interleaved and garbled the first line of the capture
  file. Statusline invocations from different sessions run concurrently.
- F4. Each session reports the rate limits as of its own last API response.
  At 11:43:08 idle sessions reported five-hour 9, 9, 12, 18, 20 percent
  while the active session reported 21 percent; seven-day 2 or 4 percent
  likewise. Within a window (same `resets_at`) the true value is the
  maximum across sessions.
- F5. The statusline fires several times per assistant turn, not once: six
  invocations for this session between 11:47:42 and 11:48:12 during a
  single turn, with `cost.total_cost_usd` ticking up between them. Whatever
  the hook does must be cheap.
- F6. Other fields present: `model.display_name` ("Fable 5.1"),
  `context_window.used_percentage`, `cost.total_cost_usd`, `session_id`,
  `session_name`, `cwd`, `workspace`, `version`, `effort`, `prompt_cache`,
  `thinking`, `fast_mode`, `output_style`, and a `worktree` object when the
  session runs in one.

## Sample payload (this session, 11:48:12 UTC)

```json
{
  "session_id": "f9d550b8-b03e-47b2-aa24-76d4af4f8a26",
  "transcript_path": "/Users/zuixote/.claude/projects/-Users-zuixote-Documents-carta-genum-projects/f9d550b8-b03e-47b2-aa24-76d4af4f8a26.jsonl",
  "cwd": "/Users/zuixote/Documents/carta_genum/projects/ai-usage-meter",
  "scratchpad_dir": "/private/tmp/claude-501/-Users-zuixote-Documents-carta-genum-projects/f9d550b8-b03e-47b2-aa24-76d4af4f8a26/scratchpad",
  "prompt_id": "0bfcd0ff-57be-4241-b321-7d8c0dc3bd4c",
  "effort": {
    "level": "high"
  },
  "session_name": "claude-usage-add-on",
  "model": {
    "id": "claude-fable-5-1",
    "display_name": "Fable 5.1"
  },
  "workspace": {
    "current_dir": "/Users/zuixote/Documents/carta_genum/projects/ai-usage-meter",
    "project_dir": "/Users/zuixote/Documents/carta_genum/projects",
    "added_dirs": []
  },
  "version": "2.1.261",
  "output_style": {
    "name": "default"
  },
  "cost": {
    "total_cost_usd": 8.510461650000002,
    "total_duration_ms": 4138771,
    "total_api_duration_ms": 979855,
    "total_lines_added": 0,
    "total_lines_removed": 0
  },
  "context_window": {
    "total_input_tokens": 125604,
    "total_output_tokens": 1836,
    "context_window_size": 1000000,
    "current_usage": {
      "input_tokens": 32,
      "output_tokens": 1836,
      "cache_creation_input_tokens": 2225,
      "cache_read_input_tokens": 123347
    },
    "used_percentage": 13,
    "remaining_percentage": 87
  },
  "exceeds_200k_tokens": false,
  "prompt_cache": {
    "warm": true,
    "caching_observed": true,
    "ttl": "1h",
    "expires_at": 1788612495,
    "requests": 22,
    "misses": 0,
    "expected_rebuilds": 1,
    "hit_ratio": 0.9404129977181033,
    "cache_write_tokens": 192790,
    "miss_recache_tokens": 0,
    "last_miss_at": null,
    "last_miss_cause": null,
    "miss_causes": {},
    "recache_tokens_if_cold": 125604
  },
  "fast_mode": false,
  "thinking": {
    "enabled": true
  },
  "rate_limits": {
    "five_hour": {
      "used_percentage": 21,
      "resets_at": 1788617400
    },
    "seven_day": {
      "used_percentage": 4,
      "resets_at": 1789160400
    }
  }
}
```
