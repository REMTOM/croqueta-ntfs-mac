#!/bin/bash
# Compila y empaqueta "build/Croqueta Digital NTFS Write on Mac.app" (no necesita sudo).
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Croqueta Digital NTFS Write on Mac"

swift build -c release

app="build/$APP_NAME.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$(swift build -c release --show-bin-path)/CroquetaNTFS" "$app/Contents/MacOS/"
cp Info.plist "$app/Contents/"
cp assets/menubar.png assets/croqueta.png "$app/Contents/Resources/"

# Icono de la app a partir del logo.
iconset=build/AppIcon.iconset
rm -rf "$iconset"
mkdir -p "$iconset"
for t in 16 32 128 256 512; do
    sips -z $t $t assets/croqueta.png --out "$iconset/icon_${t}x${t}.png" >/dev/null
    sips -z $((t * 2)) $((t * 2)) assets/croqueta.png --out "$iconset/icon_${t}x${t}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"
rm -rf "$iconset"

codesign --force --sign - "$app"
echo "OK: $app"
