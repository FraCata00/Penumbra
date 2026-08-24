#!/bin/zsh
# Rigenera Resources/AppIcon.icns disegnando l'icona da codice.
set -euo pipefail
cd "$(dirname "$0")/.."
WORK=$(mktemp -d)
swift Tools/mkicon.swift "$WORK/base.png"
SET="$WORK/AppIcon.iconset"; mkdir -p "$SET"
for s in 16 32 128 256 512; do
    sips -z $s $s "$WORK/base.png" --out "$SET/icon_${s}x${s}.png" >/dev/null
    sips -z $((s*2)) $((s*2)) "$WORK/base.png" --out "$SET/icon_${s}x${s}@2x.png" >/dev/null
done
mkdir -p Resources
iconutil -c icns "$SET" -o Resources/AppIcon.icns
rm -rf "$WORK"
echo "Resources/AppIcon.icns rigenerata"
