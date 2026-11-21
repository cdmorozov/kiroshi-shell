#!/usr/bin/env bash
# Restores the newest backup made by install.sh (configs only; packages and fonts stay).
set -euo pipefail
B="$(ls -dt "$HOME"/.netrunner-backup-* 2>/dev/null | head -1 || true)"
[ -n "$B" ] || { echo "no backup found"; exit 1; }
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
echo "restoring from $B"
for d in "$B"/config/*; do
    [ -e "$d" ] || continue
    n="$(basename "$d")"
    rm -rf "${CFG:?}/${n:?}"
    cp -a "$d" "${CFG:?}/${n:?}"
done
rm -f "$HOME/.local/bin/rice-snapshot" "$HOME/.local/bin/rice-restore" "$HOME/.local/bin/wallpaper-sync" "$HOME/.local/bin/spotify-toggle" "$HOME/.local/bin/netrun-updates"
echo "done. Configs that did not exist before were left in place; delete them by hand if you want."
