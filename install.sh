#!/bin/bash
# Instala Croqueta Digital NTFS Write on Mac: app en /Applications, helper root,
# copia protegida de ntfs-3g y regla sudoers.
# Ejecutar como usuario normal: ./install.sh  (pedirá la contraseña de administrador)
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Croqueta Digital NTFS Write on Mac"
HELPER=/Library/PrivilegedHelperTools/croqueta-ntfs-helper
NTFS_DIR=/Library/PrivilegedHelperTools/croqueta-ntfs
SUDOERS=/etc/sudoers.d/croqueta-ntfs

usuario=$(id -un)
[[ $usuario != root ]] || { echo "Ejecútalo sin sudo; lo pedirá cuando haga falta."; exit 1; }

[[ -d /Library/Filesystems/macfuse.fs ]] || { echo "Falta macFUSE: brew install --cask macfuse"; exit 1; }

./build.sh
./helper/empaquetar-ntfs3g.sh

sudo mkdir -p /Library/PrivilegedHelperTools
sudo install -o root -g wheel -m 755 helper/croqueta-ntfs-helper "$HELPER"

# ntfs-3g y sus librerías, propiedad de root (ver helper/empaquetar-ntfs3g.sh).
sudo rm -rf "$NTFS_DIR"
sudo mkdir -m 755 "$NTFS_DIR"
sudo install -o root -g wheel -m 755 build/ntfs3g/* "$NTFS_DIR/"

regla=$(mktemp)
echo "$usuario ALL=(root) NOPASSWD: $HELPER" > "$regla"
sudo visudo -cf "$regla" >/dev/null
sudo install -o root -g wheel -m 440 "$regla" "$SUDOERS"
rm -f "$regla"

# Restos de versiones anteriores (antes se llamaba "NTFS Mount").
pkill -x NTFSMount 2>/dev/null || true
rm -rf "/Applications/NTFS Mount.app"
sudo rm -rf /Library/PrivilegedHelperTools/ntfsmount-helper /Library/PrivilegedHelperTools/ntfsmount /etc/sudoers.d/ntfsmount

pkill -x CroquetaNTFS 2>/dev/null || true
rm -rf "/Applications/$APP_NAME.app"
cp -R "build/$APP_NAME.app" /Applications/
open "/Applications/$APP_NAME.app"
echo "Instalado. Busca la croqueta en la barra de menús."
