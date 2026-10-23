#!/bin/bash
# Copia ntfs-3g y sus librerías no del sistema a build/ntfs3g para instalarlas en una carpeta
# propiedad de root. Así el helper (que corre como root) no ejecuta nada de /opt/homebrew ni de
# /usr/local/lib, que tu usuario puede modificar sin contraseña.
set -euo pipefail
cd "$(dirname "$0")/.."

origen=$(readlink -f /opt/homebrew/bin/ntfs-3g 2>/dev/null) || { echo "ntfs-3g no instalado (brew install gromgit/fuse/ntfs-3g-mac)" >&2; exit 1; }
dest=build/ntfs3g
rm -rf "$dest"
mkdir -p "$dest"
cp "$origen" "$dest/ntfs-3g"
chmod u+w "$dest/ntfs-3g"

# Rutas de dependencias que no son del sistema (/usr/lib, /System) ni de macFUSE en /Library.
deps_externas() {
    otool -L "$1" | awk 'NR>1 {print $1}' | grep -vE '^(/usr/lib/|/System/|/Library/Filesystems/|@)' || true
}

# Recorre el árbol de dependencias copiando cada librería una sola vez.
pendientes=("$dest/ntfs-3g")
while ((${#pendientes[@]})); do
    actual=${pendientes[0]}
    pendientes=("${pendientes[@]:1}")
    for dep in $(deps_externas "$actual"); do
        nombre=$(basename "$dep")
        [[ $nombre == "$(basename "$actual")" ]] && continue      # su propio install name
        if [[ ! -e $dest/$nombre ]]; then
            cp "$(readlink -f "$dep")" "$dest/$nombre"
            chmod u+w "$dest/$nombre"
            # libfuse viene firmada por macFUSE: no se toca, solo se reapunta quien la usa.
            [[ $nombre == libfuse* ]] || pendientes+=("$dest/$nombre")
        fi
        install_name_tool -change "$dep" "@loader_path/$nombre" "$actual" 2>/dev/null
    done
    [[ $actual == *.dylib ]] && install_name_tool -id "@loader_path/$(basename "$actual")" "$actual" 2>/dev/null
done

# install_name_tool invalida la firma: se vuelve a firmar (ad hoc) todo salvo libfuse.
for f in "$dest"/*; do
    [[ $(basename "$f") == libfuse* ]] || codesign --force --sign - "$f" 2>/dev/null
done

# Comprobación: no debe quedar ninguna referencia a rutas modificables por el usuario.
for f in "$dest"/*; do
    if otool -L "$f" | awk 'NR>1 {print $1}' | grep -qE '^(/opt/homebrew|/usr/local)'; then
        [[ $(basename "$f") == libfuse* ]] && continue   # su install name propio, no se carga por ahí
        echo "Quedan rutas de Homebrew en $f" >&2; otool -L "$f" >&2; exit 1
    fi
done
"$dest/ntfs-3g" --version >/dev/null 2>&1 || "$dest/ntfs-3g" --help 2>&1 | head -1 | grep -qi ntfs || { echo "La copia de ntfs-3g no arranca" >&2; exit 1; }
echo "OK: $dest ($(ls "$dest" | tr '\n' ' '))"
