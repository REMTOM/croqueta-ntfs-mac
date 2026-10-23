#!/bin/bash
# Desinstala Croqueta Digital NTFS Write on Mac (no toca macFUSE ni ntfs-3g de Homebrew).
set -euo pipefail

APP_NAME="Croqueta Digital NTFS Write on Mac"

# Desmontar antes los volúmenes NTFS montados con escritura.
mount | awk '/macfuse/ && $1 ~ /^\/dev\/disk/ {print $1}' | while read -r dev; do
    sudo /Library/PrivilegedHelperTools/croqueta-ntfs-helper unmount "${dev#/dev/}" || true
done

pkill -x CroquetaNTFS 2>/dev/null || true
rm -rf "/Applications/$APP_NAME.app"
sudo rm -rf /Library/PrivilegedHelperTools/croqueta-ntfs-helper \
            /Library/PrivilegedHelperTools/croqueta-ntfs \
            /etc/sudoers.d/croqueta-ntfs
defaults delete es.croquetadigital.ntfswrite 2>/dev/null || true
echo "Desinstalado. Para quitar también macFUSE y ntfs-3g:"
echo "  brew uninstall gromgit/fuse/ntfs-3g-mac && brew uninstall --cask macfuse"
