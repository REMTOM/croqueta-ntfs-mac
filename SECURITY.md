# Política de seguridad

## Versiones con soporte

Solo la última versión de la rama `main`.

## Cómo informar de una vulnerabilidad

**No abras un issue público.** Usa [GitHub → Security → Report a vulnerability](https://github.com/REMTOM/croqueta-ntfs-mac/security/advisories/new) (aviso privado).

Incluye:
- Versión de macOS y del proyecto (commit).
- Pasos para reproducirlo.
- Impacto (por ejemplo, escalada a root mediante el helper).

Responderemos en un máximo de 7 días.

## Superficie de ataque

Lo más delicado es `helper/croqueta-ntfs-helper`, porque se ejecuta como **root** mediante una regla de sudo sin contraseña. Se considera vulnerabilidad cualquier forma de conseguir que el helper:

- ejecute código distinto de la copia de ntfs-3g que pertenece a root,
- monte, desmonte o escriba fuera de `/Volumes`,
- actúe sobre dispositivos que no sean particiones NTFS `diskXsY`.
