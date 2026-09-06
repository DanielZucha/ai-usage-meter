#!/bin/sh
set -eu

test_root=$(mktemp -d "${TMPDIR:-/tmp}/ai-usage-meter-snippet.XXXXXX")
trap 'rm -rf "$test_root"' EXIT

mkdir -p "$test_root/bin" "$test_root/releases/current/bin"
codex_target="$test_root/releases/current/bin/codex"
codex_launcher="$test_root/bin/codex"
custom_hook="$test_root/custom-bin/ai-usage-meter-codex-hook"

touch "$codex_target"
chmod 755 "$codex_target"
ln -s "$codex_target" "$codex_launcher"

output=$(
    PATH="$test_root/bin:/usr/bin:/bin" \
    make --no-print-directory snippet CODEX_HOOK_DEST="$custom_hook"
)

printf '%s\n' "$output" | grep -Fq -- "--codex-bin '$codex_launcher'"
printf '%s\n' "$output" | grep -Fq -- "'$custom_hook' --codex-bin"

if printf '%s\n' "$output" | grep -Fq "$codex_target"; then
    printf 'snippet pinned the versioned Codex target instead of its stable launcher\n' >&2
    exit 1
fi

injection_marker="$test_root/injection-ran"
unsafe_hook="$test_root/\`touch $injection_marker\`/hook"
if PATH="$test_root/bin:/usr/bin:/bin" \
    make --no-print-directory snippet CODEX_HOOK_DEST="$unsafe_hook" >/dev/null 2>&1; then
    printf 'snippet accepted a hook destination with shell metacharacters\n' >&2
    exit 1
fi

if [ -e "$injection_marker" ]; then
    printf 'snippet evaluated the hook destination before validating it\n' >&2
    exit 1
fi

quoted_hook="$test_root/quoted\"path/hook"
if PATH="$test_root/bin:/usr/bin:/bin" \
    make --no-print-directory snippet CODEX_HOOK_DEST="$quoted_hook" >/dev/null 2>&1; then
    printf 'snippet accepted a hook destination containing a quote\n' >&2
    exit 1
fi
