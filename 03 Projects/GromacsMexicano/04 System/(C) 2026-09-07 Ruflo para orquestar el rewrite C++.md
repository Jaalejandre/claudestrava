# Ruflo — orquestación del rewrite C++ (setup 2026-09-07)

Ruflo (claude-flow v3.38.21) está instalado en **CT 901**, junto al código, para dar **memoria persistente entre sesiones** y **tracking de tareas** al rewrite a C++. Configurado en modo **secuencial** (un agente a la vez), NO swarm paralelo — coherente con el diseño del plan del rewrite ("una subsistema por fase, un commit por subsistema validado").

## Dónde y cómo

| Dato | Valor |
|---|---|
| Instalado en | CT 901 (`ssh root@192.168.0.52 "pct exec 901 -- su - alejandre -c '<cmd>'"`) |
| Proyecto Ruflo | `/home/alejandre/GromacsMexicano/` (mismo repo, mismo working tree) |
| **Node** | **22 LTS** — Node 24 rompe `better-sqlite3` de Ruflo (crash en `RemoveEnvironmentCleanupHook`, el subsistema de memoria no producía salida). Se bajó de 24 a 22 el 2026-09-07. |
| Proveedor LLM | Anthropic (`claude-sonnet-4-5`), configurado y probado (`ruflo providers test -p anthropic` → PASS) |
| Modo | `swarm.maxAgents=1`, `daemon.autoStart=false` — secuencial, sin daemon corriendo por defecto |
| Archivos locales (en `.gitignore`) | `.claude/`, `.claude-flow/`, `.swarm/`, `.hive-mind/`, `.mcp.json`, `ruvector.db` — estado de herramienta, no se versiona (commit `b669690`) |
| Env var necesaria | `export HF_HOME=$HOME/.cache/huggingface` (ya en `~/.bashrc` de alejandre) — para el modelo de embeddings de la memoria |

## Qué hay cargado en la memoria de Ruflo

Namespace `rewrite`:
- `rewrite/estado-actual` — dónde va el rewrite (fase 0 completa, fase 1 en progreso Task 5, fases 2-5 pendientes)
- `rewrite/constraints` — las 5 reglas del plan (física validada 3x, no tocar Fortran, verificar CT901 libre, un subsistema por fase, plan propio por fase)
- `rewrite/arquitectura` — dónde vive el código, Node 22, config de Ruflo

Consultar: `ruflo memory retrieve --key "rewrite/estado-actual" --namespace rewrite`
Buscar semántico: `ruflo memory search "<query>" --namespace rewrite`
Listar: `ruflo memory list --namespace rewrite`

## Tareas creadas (`ruflo task list` — SIN `--all`, ese flag filtra mal)

| Fase | Descripción | Riesgo |
|---|---|---|
| Fase 1 Task 5 | Terminar parser de topología (`topology.cpp`, hay trabajo sin commitear) | bajo |
| Fase 2 | Portar fuerzas bonded (bonds + ángulos armónicos) | bajo |
| Fase 3 | Driver glue de link-cell + LJ-ST + Ewald (incluye arreglar guard de buffers persistentes = cambio de kernel real) | medio |
| Fase 4 | Loop de integración + barostato/termostato Nosé-Hoover NPT | **alto** |
| Fase 5 | Gate end-to-end (no código nuevo, la compuerta final) | gate |

## Cómo usarlo en la próxima sesión de rewrite

1. Al empezar, consultar la memoria: `ruflo memory retrieve --key "rewrite/estado-actual" --namespace rewrite` y `ruflo memory retrieve --key "rewrite/constraints" --namespace rewrite`.
2. Ver la tarea actual: `ruflo task list`.
3. **Antes de empezar una fase nueva (2-5): escribir su plan detallado** leyendo el Fortran real (mismo método que la optimización GPU — nunca portar a ciegas). Guardar el plan en `02 Optimizacion/` del vault.
4. Implementar la fase con UN agente/sesión, no swarm.
5. Validar en la compuerta (física 3x limpia, verificar CT901 libre antes de medir).
6. Al terminar: `ruflo memory store --key "rewrite/estado-actual" --value "<nuevo estado>" --namespace rewrite` y actualizar el estado de la tarea.

## Rough edges conocidas

- Cada comando de Ruflo imprime warnings de `onnxruntime`/`pthread_setaffinity` y a veces "Unable to add response to browser cache" — cosméticos, no rompen nada. Filtrar con `grep -v`.
- `ruflo task list --all` no muestra las tareas; usar `ruflo task list` a secas.
- El MCP server (`.mcp.json`) permite que un Claude Code corriendo en CT901 consulte la memoria de Ruflo vía herramientas MCP directamente (sin shell).
