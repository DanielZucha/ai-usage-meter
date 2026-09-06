#!/bin/sh
set -eu
test_root=$(mktemp -d "${TMPDIR:-/tmp}/ai-usage-meter-snippet.XXXXXX")
trap 'rm -rf "$test_root"' EXIT
mkdir -p "$test_root/bin" "$test_root/releases/current/bin" "$test_root/state"
codex_target="$test_root/releases/current/bin/codex"
codex_launcher="$test_root/bin/codex"
touch "$codex_target"
chmod 755 "$codex_target"
ln -s "$codex_target" "$codex_launcher"
legacy_hook="$test_root/ai-usage-meter-codex-hook"
touch "$legacy_hook"
PATH="$test_root/bin:/usr/bin:/bin" SNAPSHOT="$test_root/state" CODEX_HOOK_DEST="$legacy_hook" \
    sh packaging/install-codex-launcher.sh
[ "$(cat "$test_root/state/codex-launcher")" = "$codex_launcher" ]
[ "$(stat -f '%Lp' "$test_root/state/codex-launcher")" = 600 ]
[ ! -e "$legacy_hook" ]
output=$(make --no-print-directory snippet)
printf '%s\n' "$output" | grep -Fq 'model-with-reasoning'
if printf '%s\n' "$output" | grep -Eq 'Stop|hooks.json|codex-hook'; then
    printf 'snippet still requires a Codex hook\n' >&2
    exit 1
fi
marker="$test_root/injection-ran"
literal_state="$test_root/\`touch $marker\`"
PATH="$test_root/bin:/usr/bin:/bin" SNAPSHOT="$literal_state" CODEX_HOOK_DEST="$legacy_hook" \
    sh packaging/install-codex-launcher.sh
[ -f "$literal_state/codex-launcher" ]
[ ! -e "$marker" ]
PATH="/usr/bin:/bin" SNAPSHOT="$test_root/state" CODEX_HOOK_DEST="$legacy_hook" \
    sh packaging/install-codex-launcher.sh
[ ! -e "$test_root/state/codex-launcher" ]

# A symlinked configuration destination must never redirect the atomic rename.
mkdir -p "$test_root/victim"
ln -s "$test_root/victim" "$test_root/state/codex-launcher"
if PATH="$test_root/bin:/usr/bin:/bin" SNAPSHOT="$test_root/state" CODEX_HOOK_DEST="$legacy_hook" \
    sh packaging/install-codex-launcher.sh >/dev/null 2>&1; then
    printf 'installer accepted symlinked configuration destination\n' >&2
    exit 1
fi
