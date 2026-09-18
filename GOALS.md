← Goals, progress, master plan
> Generado por SatanZote AI a partir de datos reales del vault/infra el 2026-09-17. Actualízalo tú directamente o pídeme que lo actualice — no es un documento estático.

## Meta principal

**Construir un servidor autogestionable con un equipo de IA para tareas de programación y generación de dinero.**
Simultáneamente: **Conseguir trabajo formal en IA/ML (remoto o CDMX)** utilizando GromacsMexicano como pieza insignia que demuestra capacidad técnica y evidencia de alto nivel.

El servidor debe ser capaz de autogestionar su infraestructura, ejecutar proyectos de código autónomamente y generar valor mediante equipos de agentes IA.

---

## Proyectos activos — metas medibles

### 1. GromacsMexicano (proyecto insignia)
- **Código canónico**: `/root/phase4_cuda_pinned/` en CT 901. Fortran→C++/CUDA rewrite con potenciales propios (LJ, Mie, FDR, Ewald, Nosé-Hoover, NPT).
- **Estado**: Equipo 41 (Daemon-MolDyn) trabajando ahora mismo en tarea kanban `t_e41_gmxparser_1789517246` — integrar, compilar y validar GMXParser en `PRODUCTION_v3_CPP`. Fases 5a/b/c completadas, fixes físicos aplicados (LJ exponents, temp, sigma/eps).
- **Meta próxima (sin fecha fija aún — pon una si la quieres dura)**: compilar y validar GMXParser en producción → cerrar la integración pendiente.
- **Definición de DONE para física**: calzar numéricamente con el Fortran de referencia (`Programa_DM/`, carpeta Fortran8090) y benchmark contra GROMACS real.
- **Regla dura**: nunca tocar `Programa_DM/` original (referencia congelada de los científicos, tu padre define metodología ahí).
- **Bloqueadores kanban abiertos**: ninguno directo — el trabajo está `in_progress`.

### 2. Entrenador L'Étape CDMX
- **Código**: CT 901 `/home/alejandre/EntrenadorLEtape/`, dashboard `http://192.168.0.230:8003`.
- **Carrera objetivo**: L'Étape CDMX 60 km — **15 de noviembre de 2026** (fecha dura, no negociable).
- **Estado**: Fases 1–5 completadas, 49 tests.
- **Bloqueador activo**: `garmin-ingest` — rate limit 429/403 por IP pública Cloudflare. Kanban `t_5501aefe` (ready). Pendiente esperar enfriamiento o probar desde otra IP.
- **Pendiente**: inyectar HRV/sueño reales al auto-ajuste; endpoint `/adjust` (auditoría de ajustes); backup git a GitHub (`t_338697aa`, ready — sin remote configurado, un solo repo existe en tu GitHub — `claudestrava` — falta decidir si crear uno nuevo o reusar).
- **Meta con fecha dura**: sistema de entrenamiento funcionando end-to-end (Garmin+Strava+Zwift → plan auto-ajustado) **antes de la carrera, 15-nov-2026**.

### 3. Claude Strava (coach agent, mismo objetivo de carrera)
- Rutina semanal automática domingos ~7pm — próxima corrida programada.
- Revisa Strava vs plan 5 fases (Base → Construcción → Pico/Taper), escribe en `03 Projects/Claude Strava/03 Revisiones Semanales/`.
- No tocar nutrición (nutrióloga externa, Mounjaro) — fuera de scope.

### 4. Prototipos (disposable, sin meta de fecha)
- Harness Ollama local en CT 109, memoria en `error_log.json`.
- Vivo: `airbnb-admin` en `http://192.168.0.64:8877/` (v2 funcional). Pendiente: CSS-redesign (spec v4).

---

## Infraestructura — deuda técnica abierta (afecta avance de todo lo demás)

- `t_e11e0ed6` (ready): reconectar OAuth OmniRoute (claude + agy) en dashboard — **nota: memoria indica que Claude ya se reconectó 2026-09-17, revisar si esta tarea sigue vigente o se puede cerrar.**
- `t_338697aa` (ready): backup git de Entrenador L'Étape a GitHub — pendiente decidir repo.
- ⚠️ **Hallazgo de seguridad sin resolver**: nota `03 Projects/Entrenador L'Etape CDMX/CLAUDE.md` contiene un fragmento de contraseña de Garmin en texto plano. Viola la regla de "nunca credenciales en chat/markdown plano". Pendiente: moverlo a Vaultwarden y purgar del markdown (no tocado aún, requiere tu OK explícito).

---

## Weekly Update

> **Last updated:** 2026-09-17 (por SatanZote AI, primera vez que este archivo tiene contenido)

- **What's working:** GromacsMexicano avanzando con Equipo 41 activo; infraestructura Hermes/OmniRoute estabilizada (audit diario ya corre limpio, 6 combos rotos eliminados, vault limpiado de 964MB de código basura).
- **What's not working:** Garmin auth bloqueado por rate limit — sin ETA de resolución (depende de Cloudflare/IP, no de código).
- **What I'm sitting on / need to decide:** nombre de repo GitHub para backup de Entrenador L'Étape; qué hacer con la credencial Garmin expuesta en markdown.
- **What I'm feeling pulled toward:** _(sin dato — pon tú esto cuando actualices)_
- **Deadlines:** L'Étape CDMX 60km — 15 nov 2026 (dura). GMXParser integration — sin fecha puesta aún.
