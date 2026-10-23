# Avisos y software de terceros

## Marca Croqueta Digital

El nombre **Croqueta Digital** ([croquetadigital.es](https://croquetadigital.es)), el logo y las imágenes de `assets/` (`logo.png`, `croqueta.png`, `menubar.png`) son de Croqueta Digital. Todos los derechos reservados.

**No** están incluidos en la licencia MIT del código. Puedes usarlos sin modificar para referirte a este proyecto, pero si publicas un fork o una versión modificada, quita el logo y cambia el nombre.

## Dependencias externas (no se distribuyen con este repositorio)

| Componente | Licencia | Web |
|---|---|---|
| ntfs-3g | GNU GPL v2 (librería libntfs-3g: GNU LGPL v2) | https://github.com/tuxera/ntfs-3g |
| macFUSE | Licencia propia de macFUSE (componentes BSD) | https://macfuse.github.io/ |
| Fórmula Homebrew `ntfs-3g-mac` | BSD-2-Clause (tap gromgit/fuse) | https://github.com/gromgit/homebrew-fuse |

`helper/empaquetar-ntfs3g.sh` copia en **tu propio Mac** los binarios de ntfs-3g que ya tienes instalados con Homebrew. Este repositorio no publica esos binarios. Si algún día distribuyes una versión que los incluya, tendrás que cumplir la GPL v2 (ofrecer el código fuente de ntfs-3g, etc.) y la licencia de macFUSE.

NTFS es una marca de Microsoft Corporation. Paragon y Tuxera son marcas de sus propietarios. Este proyecto no tiene relación con ellos.
