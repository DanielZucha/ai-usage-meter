#!/bin/sh
set -eu

# Values come through the environment, never shell interpolation or eval.
: "${SNAPSHOT:?Missing snapshot directory}"
: "${CODEX_HOOK_DEST:?Missing legacy hook path}"
case "$SNAPSHOT" in /*) ;; *) exit 1 ;; esac
case "$CODEX_HOOK_DEST" in /*/ai-usage-meter-codex-hook) ;; *)
    printf 'Invalid legacy Codex hook destination\n' >&2; exit 1 ;; esac
mkdir -p "$SNAPSHOT"
if [ -L "$SNAPSHOT" ]; then
    printf 'Snapshot directory must not be a symlink\n' >&2
    exit 1
fi
if [ -L "$SNAPSHOT/codex-launcher" ] || [ -d "$SNAPSHOT/codex-launcher" ]; then
    printf 'Codex launcher configuration must be a regular file\n' >&2
    exit 1
fi
printf 'If you configured the preview Codex Stop hook, remove its ai-usage-meter-codex-hook entry from ~/.codex/hooks.json manually.\n'
codex_bin=$(command -v codex 2>/dev/null || true)
if [ -z "$codex_bin" ]; then
    rm -f "$SNAPSHOT/codex-launcher" "$CODEX_HOOK_DEST"
    printf 'Codex CLI not found; Claude remains available. Rerun make install with Codex on PATH to enable polling.\n'
    exit 0
fi
case "$codex_bin" in /*) ;; *) exit 1 ;; esac
if [ ! -f "$codex_bin" ] || [ ! -x "$codex_bin" ] ||
    printf '%s' "$codex_bin" | LC_ALL=C grep -q '[[:cntrl:]]'; then
    printf 'Invalid Codex launcher\n' >&2
    exit 1
fi
umask 077
temporary=$(mktemp "$SNAPSHOT/.codex-launcher.XXXXXX")
trap 'rm -f "$temporary"' EXIT HUP INT TERM
printf '%s\n' "$codex_bin" > "$temporary"
chmod 600 "$temporary"
mv -f "$temporary" "$SNAPSHOT/codex-launcher"
rm -f "$CODEX_HOOK_DEST"
printf 'Codex launcher saved; the app refreshes usage every 30 seconds.\n'
