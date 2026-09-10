---
tipo: system
proyecto: claude-strava
actualizado: 2026-09-09
---

# (C) Revisión semanal automática — Strava ↔ Plan

Mecanismo que revisa el progreso real de Strava contra el plan y ajusta si hace falta. **NO requiere crear nada nuevo: ya está corriendo.**

## Cómo funciona (estado actual)

| Dato | Valor |
| --- | --- |
| Dónde corre | **Claude cloud** (sesión del proyecto Claude Strava, no local) |
| Cuándo | **Domingos ~19:00 CDMX** |
| Qué hace | 1) Lee actividades de la semana desde Strava (MCP Strava) → 2) cruza contra el plan vigente → 3) si aplica, ajusta el plan in-place y lo avisa → 4) escribe en `03 Revisiones Semanales/` → 5) push al repo GitHub |
| Última revisión | 2026-09-07 (ver [[(C) Revision 2026-09-07]]) |
| Próxima | **2026-09-14** ⚠️ — la crítica: si dos semanas seguidas en 0 sesiones, se recorren fechas/fases del plan |

## Reglas de la revisión (contrato)

1. Compara lo entrenado vs. lo planeado de la semana → tabla de sesiones planeadas vs. hechas.
2. Si la desviación lo amerita → ajusta el plan **in-place** (misma página, nunca una nueva) y deja el aviso visible.
3. Toda revisión queda documentada en `03 Revisiones Semanales/` con fecha.
4. La del **14 sep** tiene gatillo explícito ya escrito en el plan: **2 revisiones seguidas en 0 sesiones = recorrer fechas/fases** (más volumen de gracia al inicio, o correr las fases).
5. El InBody se cruza solo cuando hay medición nueva (no tocar nutrición — externa).

## Herramientas (MCP Strava conectado)

`list_activities` · `get_activity_performance` · `get_activity_streams` · `get_athlete_profile` · `get_athlete_zones` · `get_gear` · `get_training_plan` · `eligibility` / `health`

## Notas

- La rutina no está en `04 System/` del vault porque vive en la nube; esta nota existe para que el mecanismo quede documentado y auditable desde el repo.
- Si algún domingo no corrió (revisión ausente en `03 Revisiones Semanales/`), avisar vía el canal del proyecto y re-dispararla manualmente.