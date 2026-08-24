#!/bin/zsh
# Packages build/Penumbra.app into a drag-to-install disk image.
#   ./Tools/make-dmg.sh 1.1.0
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-1.1.0}"
APP="build/Penumbra.app"
DMG="Penumbra-$VERSION.dmg"

[[ -d "$APP" ]] || { echo "missing $APP — run ./build.sh first" >&2; exit 1; }

STAGE=$(mktemp -d)
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
hdiutil create \
    -volname "Penumbra" \
    -srcfolder "$STAGE" \
    -fs HFS+ \
    -format UDZO \
    -quiet \
    "$DMG"

rm -rf "$STAGE"
echo "Built: $PWD/$DMG"
