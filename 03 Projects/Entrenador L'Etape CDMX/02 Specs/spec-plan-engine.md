# Spec: plan-engine

## Objective

Módulo central que convierte el **plan maestro de Claude Strava** (vault) en instrucciones ejecutables para el dashboard: "qué entrenamiento me toca hoy", días restantes al 15-nov, km acumulados vs meta, horas en zona, carga semanal — y **auto-ajusta** la sesión del día según la recuperación real (HRV, sueño, TSB de Garmin).

Historia de usuario:
> Como atleta, quiero que el plan que ya diseñó mi coach (Claude Strava) se adapte cada día a cómo estoy durmiendo y recuperándome, para llegar óptimo a la competencia sin sobreentrenar.

## Entrada (depende de)

| Fuente | Datos que usa | Módulo |
|---|---|---|
| Plan maestro | Estructura semanal (5 días), fases, zonas FTP, progresión de km | Claude Strava (vault, MD) |
| Garmin | HRV, sueño, TSB/CTL/ATL, FTP (test real) | `garmin-ingest` |
| Strava | Km reales, horas en zona, actividades completadas | `strava-ingest` |

## Tech Stack

| Componente | Detalle |
|---|---|
| Lenguaje | Python 3.12 (CT 901) |
| Modelo de datos | JSON en `data/` (no DB en v1) — `plan.json` (maestro), `state.json` (progreso), `adjustment.json` (ajustes del día) |
| Parser del plan | Transforma el MD del vault → estructuras (fases, semanas, sesiones con zonas/targets) |
| Determinístico | Sin LLM en el hot path: las reglas de ajuste son **heurísticas** (reglas explícitas), el LLM solo propone fuera-de-banda |
| API interna | FastAPI app interna (`/plan/today`, `/plan/progress`) consumida por `web-dashboard` |

## Reglas de ajuste (heurísticas v1)

Cada mañana computa `today_plan()`:

1. **Día base del plan:** según calendario desde el inicio del plan → qué tipo de sesión toca (estructurada / fuerza / descanso / cadencia / rodada larga).
2. **Modificador de recuperación** (Garmin):
   - HRV bajo (desviación >2σ de la media 7d) → bajar intensidad un escalón (Z2→Z1, o recortar duración 30%)
   - Sueño < 6h → descanso activo en vez de sesión dura
   - TSB < -20 (fatiga alta) → sesión de recuperación
   - HRV normal + TSB -10..0 → sesión normal conforme al plan
3. **Progreso real** (Strava):
   - km semana completada < 80% meta → siguiente rodada larga +5% duración (compensación suave, no agresiva)
   - > 110% → recortar 10% (evitar sobrecarga)
4. **Regla de oro:** nunca ajustar hacia arriba si HRV/sueño están mal; la recuperación manda.

Output de `today_plan()`:
```json
{
  "date": "2026-09-09",
  "session": {
    "type": "rodada_estructurada",
    "zone": "Z2",
    "target_minutes": 50,
    "notes": "Z2 continuo 45-60 min — versión recortada por HRV bajo",
    "swift_workout_id": "LETAPE-Z2-50"
  },
  "days_to_event": 67,
  "adjusted": true,
  "reason": "hrv_low",
  "progress": {
    "km_accumulated": 148.5,
    "km_week_meta": 60,
    "km_week_real": 48,
    "hours_zone2": 3.2,
    "load_weekly": 412
  }
}
```

## Scope

**IN:**
- Parser del plan maestro MD → `plan.json` (fases/semanas/sesiones, zonas por FTP)
- `today_plan()` con reglas de ajuste heurísticas (arriba)
- `progress()` — km acumulados, horas zona, carga semanal (vía strava-ingest)
- API interna FastAPI con `/plan/today`, `/plan/progress`, `/plan/week`
- Test unitario: reglas de ajuste con fixtures (HRV bajo, sueño corto, TSB bajo)

**OUT:**
- No reescribir el plan maestro del vault (solo lectura) — **Claude Strava autoriza cambios estructurales**
- No decisiones nutricionales (InBody/Mounjaro fuera)
- No LLM en el hot path del `today_plan()` (determinístico)
- Sin DB — JSON files en v1

## Success Criteria (testables)

- [ ] `plan.json` generado desde el MD oficial (5 fases, semanas, sesiones por día)
- [ ] `today_plan()` devuelve la sesión correcta para hoy según el calendario
- [ ] Con fixture `hrv_low` devuelve sesión recortada con `adjusted:true` y `reason`
- [ ] Con fixture `normal` devuelve la sesión tal cual (`adjusted:false`)
- [ ] `days_to_event` = 67 (2026-09-09 → 2026-11-15)
- [ ] `progress()` integra km/horas/carga de strava-ingest
- [ ] `/plan/today` responde 200 con JSON válido del shape documentado

## Boundaries

- **Always:** Determinístico primero; LLM solo para sugerencias fuera-de-banda. Leer el plan maestro como fuente de verdad. Loggear cada ajuste con su razón (auditable).
- **Ask first:** Cambiar reglas heurísticas (umbrales HRV/TSB); agregar DB; modificar el MD del plan maestro.
- **Never:** Escribir sobre el plan del vault sin permiso de Claude Strava; decisiones de nutrición; ignorar la señal de recuperación para "no perder el plan".

## Open Questions

1. ~~¿Tienes los umbrales de HRV de Garmin interpretables?~~ → **Resuelto 2026-09-09: usar el rating de Garmin (Balanceado/Desbalanceado) como señal principal.** Raw HRV queda como dato complementario si el MCP lo expone.
2. ~~¿Carga semanal: fórmula simple o Training Load de Garmin?~~ → **Pendiente de decisión** — ver "Decisiones cerradas" y responde la OQ2 del review si tienes preferencia; por defecto arranco con fórmula simple (min×factor zona).

## Decisiones cerradas (2026-09-09)

- HRV: rating de Garmin (Balanceado → normal, Desbalanceado → recortar)
- Equipo disponible en casa (para sesiones de fuerza/cadencia outdoor/indoor):
  - Pesas (mancuernas), banco, caminadora, cajón (plio), pelota de yoga, ligas de ejercicio, tapete de yoga
  - Rodillo + Zwift (plan estándar)
- La sesión de fuerza del plan (sentadilla, peso muerto rumano, zancadas, plancha) se ejecuta con este equipo — el `plan.json` mapeará ejercicios → equipo en los targets de fuerza
- Carga semanal v1: fórmula simple `min × factor zona` (Z1=0.5, Z2=1, Z3=1.5, Z4=2.5, Z5=4) salvo que se decida lo contrario