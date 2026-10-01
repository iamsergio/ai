#!/bin/sh
# Builds build/MyApp.app from Sources/*.swift. Usage: ./build.sh [run]
set -e
cd "$(dirname "$0")"

NAME=MyApp
BUNDLE_ID=com.example.myapp
APP="build/$NAME.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -target arm64-apple-macos14 -parse-as-library Sources/*.swift -o "$APP/Contents/MacOS/$NAME"

cp -R img "$APP/Contents/Resources/img"
find "$APP/Contents/Resources/img" -name .DS_Store -delete
rm -rf "$APP/Contents/Resources/img/3d-icon-reference/cloud.blend" "$APP/Contents/Resources/img/3d-icon-reference/preview-render.png"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>$NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleName</key><string>$NAME</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign -s - "$APP"
echo "Built $APP"

if [ "$1" = "run" ]; then
    open "$APP"
fi
