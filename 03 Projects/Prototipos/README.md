---
tipo: indice
---

# Prototipos

Prototipos web simples generados con el **modelo local del servidor** (Ollama en CT 103, GPU), con Claude de orquestador. No son proyectos formales — son desechables.

- **Cómo funciona:** skill [[prototipo-local.md]]
- **Código:** vive en CT 109 en `/project/prototipos/<nombre>/` (no en el vault, salvo que se pida)
- **Aquí** solo se guarda, por prototipo: `(C) spec.md` y `(C) log.md`

## Cómo pedirlo

Dile a Claude: *"prototipo local de …"* o *"hazme un prototipo de …"*. Claude:
1. escribe el spec
2. genera con `qwen2.5-coder:14b` (o `gpt-oss` si necesita razonar)
3. revisa todo
4. lo sirve en un puerto de CT 109 y te pasa el link (`http://192.168.0.64:88xx`)

## Trabajos

| Fecha | Qué | Modelo | Estado |
|---|---|---|---|
| 2026-09-08 | [[(C) analisis y mejoras (revisado)\|Análisis del proyecto airbnb-dashboard]] (CT 112) — documentación + mejoras priorizadas | gpt-oss:latest | ✅ entregado |
