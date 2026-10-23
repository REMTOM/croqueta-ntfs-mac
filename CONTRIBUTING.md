# Contribuir

¡Gracias por echar una mano! 🥟

1. Haz un fork y crea una rama: `git checkout -b mejora/lo-que-sea`.
2. Compila: `./build.sh` (sin sudo).
3. Si cambias scripts, pásales `shellcheck helper/* *.sh`.
4. Prueba con un disco o una imagen NTFS **de prueba**, nunca con datos importantes.
5. Abre un Pull Request explicando qué cambia y cómo lo has probado.

## Normas

- El código, los comentarios y los mensajes de la interfaz van en español.
- Cualquier cambio en `helper/croqueta-ntfs-helper` (se ejecuta como root) necesita una explicación de su impacto en la seguridad.
- No subas binarios de ntfs-3g ni de macFUSE, ni claves, certificados o tokens.
