# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y [SemVer](https://semver.org/lang/es/).

## [1.0.0] - 2026-10-23

### Añadido
- App de barra de menús **Croqueta Digital NTFS Write on Mac** con el logo de Croqueta Digital.
- Detección de discos NTFS con DiskArbitration y montaje automático con escritura.
- Abrir en Finder, desmontar y expulsar.
- Enlaces a la web [croquetadigital.es](https://croquetadigital.es) y al repositorio desde el menú.
- Opción de abrir al iniciar sesión.
- Helper root `croqueta-ntfs-helper` con validación de argumentos y comprobación real del montaje.
- Copia aislada de ntfs-3g que pertenece a root (`empaquetar-ntfs3g.sh`).
- `install.sh`, `uninstall.sh`, CI de compilación en GitHub Actions.
