#!/bin/zsh
# Builds DynamicWallpaper and assembles its .app bundle, without Xcode.
set -euo pipefail
cd "$(dirname "$0")"

APP="build/Dynamic Wallpaper.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -parse-as-library \
    -target arm64-apple-macos26.0 \
    Sources/*.swift \
    -o "$APP/Contents/MacOS/DynamicWallpaper"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>                 <string>Dynamic Wallpaper</string>
    <key>CFBundleDisplayName</key>          <string>Dynamic Wallpaper</string>
    <key>CFBundleExecutable</key>           <string>DynamicWallpaper</string>
    <key>CFBundleIdentifier</key>           <string>local.francescocataldo.DynamicWallpaper</string>
    <key>CFBundlePackageType</key>          <string>APPL</string>
    <key>CFBundleShortVersionString</key>   <string>1.0</string>
    <key>CFBundleVersion</key>              <string>1</string>
    <key>CFBundleIconFile</key>             <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>       <string>26.0</string>
    <key>NSHighResolutionCapable</key>      <true/>
    <key>NSPrincipalClass</key>             <string>NSApplication</string>
</dict>
</plist>
PLIST

[[ -f Resources/AppIcon.icns ]] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"

codesign --force --deep --sign - "$APP" 2>/dev/null || true
echo "Built: $PWD/$APP"
