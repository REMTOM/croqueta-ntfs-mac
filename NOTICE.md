# Avisos y software de terceros

## Marca Croqueta Digital

El nombre **Croqueta Digital** ([croquetadigital.es](https://croquetadigital.es)), el logo y las imágenes de `assets/` (`logo.png`, `croqueta.png`, `menubar.png`, `social-preview.png`) son de Croqueta Digital. Todos los derechos reservados.

**No** están incluidos en la licencia MIT del código. Puedes usarlos sin modificar para referirte a este proyecto, pero si publicas un fork o una versión modificada, quita el logo y cambia el nombre.

## Dependencias externas (no se distribuyen con este repositorio)

| Componente | Licencia | Web |
|---|---|---|
| ntfs-3g | GNU GPL v2 (librería libntfs-3g: GNU LGPL v2) | https://github.com/tuxera/ntfs-3g |
| macFUSE | Licencia propia de macFUSE (componentes BSD) | https://macfuse.github.io/ |
| Fórmula Homebrew `ntfs-3g-mac` | BSD-2-Clause (tap gromgit/fuse) | https://github.com/gromgit/homebrew-fuse |

El repositorio no contiene binarios de terceros.

El **instalador `.pkg`** (Releases) **sí incluye** ntfs-3g 2026.9.28 y libintl compilados. Se distribuyen bajo sus licencias GPL-2.0-or-later y LGPL; los textos van en `/Library/PrivilegedHelperTools/croqueta-ntfs/` y el código fuente correspondiente está en https://github.com/tuxera/ntfs-3g/archive/refs/tags/2026.9.28.tar.gz y https://www.gnu.org/software/gettext/.
El `.pkg` **no** incluye macFUSE: lo descarga de su web oficial durante la instalación, y la `libfuse` que usa ntfs-3g se copia de la instalación local de macFUSE.

NTFS es una marca de Microsoft Corporation. Paragon y Tuxera son marcas de sus propietarios. Este proyecto no tiene relación con ellos.
