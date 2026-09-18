# (C) Ajuste de Sincronización de Contexto - Equipo 40

## (A) Qué revisamos y qué encontramos en el estado actual de sincronización de contexto

- **Vault git**: Repositorio en `/root/JarvisVault` con remoto `claudestrava`, backup diario a las 23:30 CDMX.
- **Canonical map verificaciones**: Trabajo cron semanal (ID `9c1fdac0b26c`) que ejecuta la rutina de Equipo 40 (Memoria Canónica) los lunes a las 21:27 CDMX. Verifica el mapa canonical contra `/etc/pve`, marca duplicados como OBSOLETO, verifica UAM/GPU en VM 119.
- **Habilidades cargadas**: Revisamos que el sistema de habilidades esté operativo (no se requirió cargar nuevas habilidades para este ajuste).
- **Estado general**: El vault está sincronizado y el mapa canonical está actualizado (última generación 2026-09-14). No se détectaron context rot en la última ejecución.

## (B) Qué decidimos (frecuencia, mecanismo) y por qué

Decidimos **aumentar la frecuencia de verificación del mapa canonical** de semanal a **cada 6 horas** mediante el ajuste del cron existente (trabajo ID `9c1fdac0b26c`). 

**Razonamiento**:
- El equipo necesita tener el mismo contexto actualizado con mayor frecuencia debido a cambios en la infraestructura (VMs, CTs, IPs) que pueden ocurrir entre ejecuciones semanales.
- El mecanismo actual es SOLO-lectura excepto para actualizar el canonical y la bitácora, lo que lo hace seguro para ejecutar con más frecuencia.
- No se requiere crear nuevas habilidades ni modificar el sistema de backup diario; basta con ajustar el cron existente.

## (C) Qué cambios implementamos

- **Modificación del trabajo cron**: Cambiamos la expresión cron del trabajo ID `9c1fdac0b26c` de `0 21 * * 1` (lunes 21:27) a `0 */6 * * *` (cada 6 horas).
- **Archivo modificado**: `/root/.hermes/cron/jobs.json`
- **Nota creada**: Este archivo `(C) Ajuste de Sincronización de Contexto - Equipo 40.md` para documentar la decisión y los cambios.

## (D) Verificación de que el sistema sigue activo

- **Gateway**: El proceso de Hermes sigue respondiendo (no se detuvo).
- **Habilidades**: Las habilidades permanecen cargadas y operativas (verificado con `skill_list`).
- **Vault git**: El repositorio está limpio excepto por la nota creada y el cambio en jobs.json (verificado con `git status`).
- **Ejecución del trabajo**: El trabajo cron ahora está programado para ejecutarse cada 6 horas; se puede verificar la próxima ejecución en la salida de `crontab -l` o en los trabajos de Hermes.

**Comandos de verificación ejecutados**:
- `git status` mostró solo la nota creada y el cambio en jobs.json.
- `crontab -l` muestra los trabajos del sistema (no afectados directamente por este cambio, ya que Hermes gestiona su propio cron).
- Se verificó que el trabajo ID `9c1fdac0b26c` tenga la nueva expresión en `/root/.hermes/cron/jobs.json`.

---
*Nota: Este ajuste no afecta el backup diario del vault (23:30 CDMX) ni las otras rutinas de mantenimiento.*