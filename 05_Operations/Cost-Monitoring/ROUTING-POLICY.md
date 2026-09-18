# OmniRoute Routing Policy — Token-Efficient Cascade

**Date**: 2026-09-17
**Budget**: $2 USD/day max
**Philosophy**: Gratis primero → Haiku → Sonnet/Fable (solo crítico)

## Instancia 1: GRATIS (primera opción)
- **Gemini 2.0 Flash** (1.5M tokens/mes gratis)
- **DeepSeek** (1M tokens/mes gratis)
- Modelos locales si están disponibles y confiables
- **Duración típica**: ~1 hora antes de agotar cuota

**Tareas**: Code gen, design, specs, análisis, research, testing

## Instancia 2: Claude Haiku (fallback barato)
- Cuando gratis agotado o insuficiente para tarea
- **Haiku 5x más barato que Sonnet**
- Tareas: code review, debugging, error analysis, docs
- Límite: $0.50 USD/día (soft)

## Instancia 3: Claude Sonnet / Fable (MUY CRÍTICO)
- Arquitectura, security audit, complex reasoning SOLO
- **Requiere aprobación José** vía Telegram
- No usar "por si acaso"
- Límite: $1.50 USD/día (hard stop)

## Escalation Logic

```
Tarea llega
├─ ¿Puedo con Gemini/DeepSeek? → SÍ → usa gratis
├─ ¿Gratis agotado? → usa Haiku
├─ ¿Haiku insuficiente? → pide aprobación José
└─ José aprobó Sonnet? → usa Sonnet
   else → BLOQUEA
```

## Daily Budget Allocation

- **Gratis**: $0 (~80% tareas, ~1 hr máx)
- **Haiku**: $0.50 (~15% tareas)
- **Sonnet/Fable**: $1.50 (~5% tareas, crítico)
- **TOTAL**: $2.00/día

## Monitor Alerts

- **Green**: Claude < $0.50/día
- **Yellow**: Claude $0.50–$1.50 → sugerir más Haiku
- **Red**: Claude > $1.50 → emergency (gratis only)

## Cómo aprobar escalation

José en Telegram:
```
Usa Sonnet para [tarea específica]
```

Monitor log + track costo. Después desescala a gratis/Haiku.

