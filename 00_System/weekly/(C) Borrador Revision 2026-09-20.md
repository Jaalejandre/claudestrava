# Revisión — 2026-09-20 (BORRADOR / pre-carga)

> **Estado:** BORRADOR preparado por Hermes (subagente) antes de la rutina semanal de Claude Strava.
> **⚠️ No incluye datos Strava todavía** — la fuente de actividad (MCP Strava) vive en Claude cloud y no es accesible desde este entorno. Los campos entre `[ ]` deben completarse cuando corra la rutina en la nube (~19:00 CDMX domingo).
> **NO push a GitHub.** Este archivo es solo para preparar el borrador.

---

## Ventana de la revisión

- **Periodo cubierto:** 15 sep – 21 sep 2026 (Semana 3 de Fase 1 — Base)
- **Fecha de carrera:** 15 nov 2026 (~8 semanas)
- **Última revisión escrita:** 2026-09-14 (ver `03 Revisiones Semanales/`)
- **Rutina semanal hoy:** `[PENDIENTE — verificar si corrió en Claude cloud]`

> Hoy (domingo 2026-09-20) **no existe** `(C) Revision 2026-09-20.md` en `03 Revisiones Semanales/`. La rutina semanal **no ha corrido/pusheado** todavía.

## ⚠️ Disparador crítico del plan

El ajuste del 14 sep dejó marcado en `02 Plan de Entrenamiento/`:

> **"Si la semana del 17-23 sep (arranque real de esta Fase 1 extendida) vuelve a mostrar consistencia muy baja, el objetivo de la carrera necesita replantearse (por ejemplo: correr para terminar dentro del límite de tiempo, no para un tiempo objetivo)."**

La semana 17-23 sep **cae exactamente dentro de esta ventana de revisión (15-21 sep).** Esta es **LA revisión gatillo.** Si los datos de Strava muestran otra semana con poco o nulo volumen, el plan debe activar el replanteamiento del objetivo de carrera (terminar, no tiempo objetivo).

## Métricas clave (a completar con datos Strava)

### Volumen
| Métrica | Valor | Meta de la ventana | Cumplimiento |
|---|---|---|---|
| Actividades en ventana (15-21 sep) | `[N]` | ≥5 (estructura semanal) | `[x/N]` |
| Distancia total | `[X km]` | `[Z km]` (plan semana 3) | `[%]` |
| Tiempo en bici | `[HH:MM]` | — | — |
| Horas de fuerza | `[N]` | 1 | `[%]` |
| Rodada larga outdoor | `[X km]` | 20 km *(progresión bajada: 20→25→30)* | `[Sí/No/¿]` |

### Intensidad
| Métrica | Valor | Zona objetivo |
|---|---|---|
| Potencia avg sesiones | `[W]` | Z2 (82-111 W) |
| FC avg | `[bpm]` | Z2 (120-148 bpm) |
| Cadencia avg | `[rpm]` | 85-95 rpm (foco Fase 1) |
| Test de FTP real | `[PENDIENTE]` | Lleva **4 semanas de retraso** — prioridad #1 |

### Cumplimiento
- Sesiones ejecutadas de las `[N]` planeadas: `[N]` → `[%]`
- Consistencia acumulada desde arranque del plan (3 sep): Semana 1: 0 · Semana 2: 1 corta · Semana 3: `[N]`
- **Valoración:** `[Alta / Media / Baja]`
- **Acción requerida:** `[Ninguna / Ajuste de plan / Replantear objetivo de carrera]`

## Pendientes arrastrados (sin importar el resultado de esta semana)

- **Test de FTP real** — 4 semanas de retraso, es la base para cualquier trabajo de intensidad en Fase 2 (8 oct – 28 oct).
- **Fuerza (piernas + core)** — no se ha registrado fuerza desde que arrancó el plan; el objetivo es frenar la pérdida de masa muscular esquelética (32.7 kg, bajando).
- **Cadencia 85-95 rpm** — la única sesión registrada (8 sep) fue a 75.6 rpm; el punto débil detectado sigue sin trabajarse.
- **Descanso activo** — sin registrar.

## Datos disponibles / faltantes

**Disponibles (local):**
- Plan vigente (`02 Plan de Entrenamiento/`, actualizado 14 sep: Fase 1 extendida a 5 semanas, termina 7 oct; Fase 2 comprimida 8-28 oct; rodada larga bajada a 20→25→30 km).
- Revisiones previas (03, 07, 14 sep) con la trayectoria de consistencia baja.
- Resumen InBody 19 ago (sin medición nueva — no cruzar nutrición).
- Ruta del evento (LEtape-CDMX-RL26.gpx) para programar la rodada larga sobre el perfil real.

**FALTANTES (requeridos de la rutina en nube):**
1. **Datos de actividad 15-21 sep desde Strava** (MCP `list_activities` + `get_activity_performance`/`streams`).
2. Verificación de si la rutina semanal corrió hoy en Claude cloud (~19:00 CDMX).
3. Completar todas las métricas entre `[ ]`, decidir ajuste/replanteo, y luego **si** se decide publicar, mover a `03 Revisiones Semanales/(C) Revision 2026-09-20.md`.

## Nota operativa

Este borrador se guardó en `00_System/weekly/` como pre-carga para la revisión de hoy. No debe confundirse con la revisión oficial (`03 Revisiones Semanales/`). La revisión oficial la firma la rutina de Claude Strava una vez con datos reales de actividad.

---
*Borrador generado por Hermes (subagente) · 2026-09-20 · Sin push a GitHub*
