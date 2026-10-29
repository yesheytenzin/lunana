#!/usr/bin/env bash
# capture-windows-hyprland.sh — per-client window previews on Hyprland.
#
# Companion to capture-windows.sh (Niri-only). Takes Hyprland hex addresses,
# resolves each client's geometry via `hyprctl -j clients`, and captures it
# with `grim -g`. Output filenames match WindowPreviewService's cache layout:
#   <previewDir>/window-<address>.png
#
# Usage: capture-windows-hyprland.sh <previewDir> <address> [<address> ...]

set -euo pipefail

preview_dir="${1:-}"; shift || true
[ -n "$preview_dir" ] || { echo "usage: $0 <previewDir> <address>..." >&2; exit 2; }
mkdir -p "$preview_dir"

command -v hyprctl >/dev/null || exit 0
command -v grim >/dev/null || exit 0
command -v jq >/dev/null || exit 0

clients_json="$(hyprctl -j clients 2>/dev/null)" || exit 0

for addr in "$@"; do
    geom="$(printf '%s' "$clients_json" | jq -r --arg a "$addr" \
        '.[] | select(.address == $a) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' \
        | head -n 1)" || continue
    [ -n "$geom" ] || continue
    # Skip zero-area or offscreen clients.
    if printf '%s' "$geom" | grep -qE ' 0x0$'; then continue; fi
    grim -g "$geom" "$preview_dir/window-$addr.png" 2>/dev/null || true
done
