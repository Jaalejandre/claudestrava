# Spec: zwift-recommender

## Objective

Mapear la **sesión del día** que produce `plan-engine` a un **workout o ruta concreta de Zwift**: si toca intervalos Z4 → un workout de Zwift con esa estructura; si toca rodada larga Z2 → una ruta virtual de duración similar. El usuario conecta el rodillo a Zwift, busca la recomendación en el dashboard y la carga.

Historia de usuario:
> Como atleta con rodillo, quiero que el plan me diga qué CARGAR en Zwift hoy (en vez de inventar), para que la sesión indoor sea exactamente lo que mi coach prescribió.

## Entrada (depende de)

| Fuente | Qué usa | Módulo |
|---|---|---|
| `plan-engine` | Tipo de sesión, zona, minutos objetivo | today_plan() |

## Tech Stack

| Componente | Detalle |
|---|---|
| Lenguaje | Python 3.12 |
| Catálogo | **Estático en v1** — JSON `data/zwift_catalog.json` (workouts + rutas manuales curadas) |
| Mapeo | Tabla de reglas sesión→recomendación (determinístico) |
| API interna | endpoint `/zwift/today` en la FastAPI de plan-engine o standalone |

## Reglas de mapeo (v1)

| Sesión (del plan) | Recomendación Zwift |
|---|---|
| Rodada estructurada Z4 (intervalos) | Workout Zwift con bloques Z4 (ej. "SST - 2x12min" o custom) |
| Rodada estructurada Z2 | Workout "Endurance" Z2 45-60 min, o ruta flat corta |
| Cadencia/técnica (Z1-Z2, 85-95 rpm) | Workout cadencia (ej. "Cadence Drills") o ruta flat con foco rpm |
| Rodada larga Z2 | Ruta virtual de duración equivalente (ej. Watopia Flat Route) |
| Descanso activo | Sin recomendación (o ruta recovery Z1 20 min) |
| Fuerza | Sin recomendación — fuerza no es Zwift |

**Campos del catálogo:**
```json
{
  "workouts": [
    {
      "id": "LETAPE-SST-2x12",
      "name": "Sweet Spot 2x12",
      "zone": "Z4",
      "duration_min": 60,
      "structure": "15min Z2 + 2x(12min Z4/5min Z2) + 10min Z1",
      "zwift_search": "SST (Short) 2 x 12'",
      "lock": false
    }
  ],
  "routes": [
    {
      "id": "WATOPIA-FLAT",
      "name": "Watopia - Flat Route",
      "duration_min": 50,
      "kind": "route"
    }
  ]
}
```

## Scope

**IN:**
- Catálogo inicial `zwift_catalog.json` con ~10 workouts + ~5 rutas (curadas a mano, zoom no — reales de Zwift)
- `recommend(session)` → workout/ruta por reglas de la tabla
- Endpoint `/zwift/today` (retorna recomendación + query de búsqueda en Zwift)
- Test unitario: cada tipo de sesión mapea a recomendación válida (o null justificando)

**OUT:**
- No conectarse a la API de Zwift (no es necesaria en v1 — el rodillo usa Zwift App nativa)
- No auto-enviar workouts al dispositivo
- Catálogo v1 manual — la curación de workouts la hago contigo (no el modelo)

## Success Criteria (testables)

- [ ] Catálogo con ≥10 workouts y ≥5 rutas reales de Zwift
- [ ] `recommend(rodada_estructurada Z4)` → workout Z4 con duración ≈ target
- [ ] `recommend(rodada_larga Z2 120min)` → ruta virtual ~120 min
- [ ] `recommend(fuerza)` → null con `reason_no_zwift`
- [ ] `/zwift/today` integrado con `plan-engine` (usa su today_plan())
- [ ] Test unitario de tabla de mapeo

## Boundaries

- **Always:** El catálogo es curado (nombres reales de Zwift, verificables en la app). La recomendación debe ser ejecutable en Zwift sin plugins. Si la sesión no se puede hacer en Zwift, responder null con razón.
- **Ask first:** Agregar integración con Zwift API (login, auto-enqueue); ampliar catálogo con modelos.
- **Never:** Inventar workouts que no existen en Zwift; recomendar a ciegas (cada entrada debe ser verificable en la app Zwift).

## Open Questions

1. ~~¿Qué plan de Zwift tienes?~~ → **Resuelto 2026-09-09: plan estándar** (suscripción regular).
2. ~~¿Watopia o DLCs?~~ → **Pendiente** — v1 asumo Watopia + rutas base; confirma antes del catálogo final.

## Decisiones cerradas (2026-09-09)

- Plan Zwift estándar → catálogo v1 con workouts base + Watopia
- Equipo en casa (para sesiones fuera de Zwift): pesas, banco, caminadora, cajón, pelota de yoga, ligas, tapete
- Sesiones no-Zwift (fuerza, descanso activo) → `null + reason`, el dashboard sugiere equipo en casa
