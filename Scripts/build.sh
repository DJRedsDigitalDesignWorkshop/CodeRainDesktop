#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/CodeRainDesktop.app/Contents/MacOS build/CodeRainDesktop.app/Contents/Resources dist
cp Template/preferences.plist build/CodeRainDesktop.app/Contents/Resources/
cp Info.plist build/CodeRainDesktop.app/Contents/Info.plist
xcrun swiftc -O -whole-module-optimization -target arm64-apple-macos13.0 -framework AppKit -framework ScreenSaver -framework QuartzCore -framework ServiceManagement Sources/*.swift -o build/CodeRainDesktop.app/Contents/MacOS/CodeRainDesktop
codesign --force --sign "${SIGNING_IDENTITY:--}" build/CodeRainDesktop.app
mkdir -p build/dmg
cp -R build/CodeRainDesktop.app build/dmg/
ln -sfn /Applications build/dmg/Applications
hdiutil create -volname "CodeRainDesktop 1.0.0" -srcfolder build/dmg -ov -format UDZO dist/CodeRainDesktop-1.0.0-Apple-Silicon.dmg
