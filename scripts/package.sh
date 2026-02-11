#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="ZenBar"
VERSION="${1:-0.1.0}"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
BUILD_DIR="$ROOT_DIR/.build/release"

rm -rf "$DIST_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

swift build -c release --package-path "$ROOT_DIR"

cp "$BUILD_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
if [[ -f "$ROOT_DIR/assets/ZenBar.icns" ]]; then
  cp "$ROOT_DIR/assets/ZenBar.icns" "$APP_DIR/Contents/Resources/ZenBar.icns"
fi

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP_DIR/Contents/Info.plist"

codesign --force --deep --sign - "$APP_DIR"

DMG_DIR="$DIST_DIR/dmg"
DMG_NAME="$APP_NAME-$VERSION.dmg"
mkdir -p "$DMG_DIR"
cp -R "$APP_DIR" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_DIR" -ov -format UDZO "$DIST_DIR/$DMG_NAME"

echo "DMG_PATH=$DIST_DIR/$DMG_NAME"
