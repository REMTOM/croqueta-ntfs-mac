#!/bin/bash
# Genera build/Croqueta-NTFS-<versión>.pkg: instalador con asistente (doble clic y Continuar).
# Requisitos en el Mac que lo genera: Xcode/CLT y ntfs-3g de Homebrew (gromgit/fuse/ntfs-3g-mac).
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Croqueta Digital NTFS Write on Mac"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Info.plist)
PKG_ID=es.croquetadigital.ntfswrite.pkg

./build.sh
./helper/empaquetar-ntfs3g.sh

raiz=build/pkgroot
rm -rf "$raiz" build/pkg
mkdir -p "$raiz/Applications" "$raiz/Library/PrivilegedHelperTools/croqueta-ntfs" build/pkg/resources

cp -R "build/$APP_NAME.app" "$raiz/Applications/"
cp uninstall.sh "$raiz/Applications/$APP_NAME.app/Contents/Resources/"
codesign --force --sign - "$raiz/Applications/$APP_NAME.app"
install -m 755 helper/croqueta-ntfs-helper "$raiz/Library/PrivilegedHelperTools/"

# ntfs-3g sin libfuse (es de macFUSE: el postinstall copia la del sistema).
dest="$raiz/Library/PrivilegedHelperTools/croqueta-ntfs"
for f in build/ntfs3g/*; do
    [[ $(basename "$f") == libfuse* ]] || install -m 755 "$f" "$dest/"
done

# Licencias GPL/LGPL de ntfs-3g junto a los binarios, con el enlace a su código fuente.
cellar=$(dirname "$(dirname "$(readlink -f /opt/homebrew/bin/ntfs-3g)")")
install -m 644 "$cellar/COPYING" "$dest/COPYING-ntfs-3g.txt"
install -m 644 "$cellar/COPYING.LIB" "$dest/COPYING.LIB-ntfs-3g.txt"
cat > "$dest/FUENTES.txt" <<EOF
ntfs-3g $(basename "$cellar") — GPL-2.0-or-later / LGPL-2.0-or-later
Código fuente: https://github.com/tuxera/ntfs-3g/archive/refs/tags/$(basename "$cellar").tar.gz
libintl (GNU gettext) — LGPL-2.1-or-later — https://www.gnu.org/software/gettext/
EOF

# Paquete de componente montado a mano (Bom + cpio) en vez de con pkgbuild:
#  - pkgbuild convierte atributos extendidos (com.apple.provenance) en archivos "._"
#  - y marca la app como "relocatable", lo que puede instalarla fuera de /Applications.
comp=build/pkg/comp
mkdir -p "$comp"
cpio_gz() { (cd "$1" && find . | LC_ALL=C sort | cpio -o --quiet --format odc -R 0:0 | gzip -9 -c); }
chmod 755 installer/scripts/*
cpio_gz "$raiz" > "$comp/Payload"
# pkgutil --flatten espera Scripts como carpeta (Payload sí va ya comprimido).
mkdir "$comp/Scripts"
install -m 755 installer/scripts/preinstall installer/scripts/postinstall "$comp/Scripts/"
# mkbom también lista los atributos extendidos como "._": se filtran, se fija root:wheel
# y se regenera el Bom.
mkbom "$raiz" build/pkg/bruto.bom
lsbom build/pkg/bruto.bom | awk -F'\t' 'BEGIN { OFS = "\t" } $1 !~ /\/\._/ { $3 = "0/0"; print }' > build/pkg/bom.txt
mkbom -i build/pkg/bom.txt "$comp/Bom"
rm -f build/pkg/bruto.bom build/pkg/bom.txt
archivos=$(find "$raiz" | wc -l | tr -d ' ')
kbytes=$(du -sk "$raiz" | cut -f1)
cat > "$comp/PackageInfo" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<pkg-info format-version="2" identifier="$PKG_ID" version="$VERSION" install-location="/" auth="root">
    <payload numberOfFiles="$archivos" installKBytes="$kbytes"/>
    <scripts>
        <preinstall file="./preinstall"/>
        <postinstall file="./postinstall"/>
    </scripts>
</pkg-info>
EOF
pkgutil --flatten "$comp" build/pkg/croqueta-ntfs-component.pkg
rm -rf "$comp"

cp installer/resources/*.html build/pkg/resources/
sips -z 160 160 assets/croqueta.png --out build/pkg/resources/background.png >/dev/null
sed "s/__VERSION__/$VERSION/" installer/distribution.xml > build/pkg/distribution.xml

salida="build/Croqueta-NTFS-$VERSION.pkg"
productbuild --distribution build/pkg/distribution.xml \
             --resources build/pkg/resources \
             --package-path build/pkg \
             "$salida"
rm -rf "$raiz" build/pkg
echo "OK: $salida ($(du -h "$salida" | cut -f1))"
