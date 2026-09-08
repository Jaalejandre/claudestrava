> [!warning] SUPERSEDIDO 2026-09-07 (misma noche)
> Ruflo fue **reemplazado por BASE** como capa de memoria del rewrite. Ver [[(C) 2026-09-07 BASE para memoria del rewrite C++.md]]. Ruflo quedó desinstalado de CT 901 (`npm -g`), su estado local borrado (`.claude-flow`, `.swarm`, `.hive-mind`, `.mcp.json`, `ruvector.db`, `claude-flow.config.json`, `memory/`). Commit `6ffd0f8`. La sección "Enrutamiento por OmniRoute" de abajo **sigue vigente** — OmniRoute no cambió, ahora lo consume Claude Code en CT 901 en vez de Ruflo. El resto de este documento es histórico.

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

---

## Enrutamiento por OmniRoute (gestión de tokens) — 2026-09-07

Ruflo ya no llama a la API de Anthropic directo. Pasa por **OmniRoute** para tener visibilidad de tokens/costo y poder ponerle budget/límites.

| Dato | Valor |
|---|---|
| OmniRoute vive en | **claude-dev** (CT 109, `192.168.0.64:20128`), servicio systemd `omniroute` (enable + Restart on-failure), siempre encendido |
| Binding | `0.0.0.0:20128` con `REQUIRE_API_KEY=true` (LAN de casa, con key obligatoria) |
| Dashboard | `http://192.168.0.64:20128` — user `admin`, pass `11deabril5` |
| API key de Ruflo | `sk-784af7b27f4f9ca0-517c0c-b8dff9fe` (nombre `ruflo-rewrite`) |
| Ruflo provider `anthropic` | endpoint `http://192.168.0.64:20128/v1`, model `cc/claude-sonnet-4-5-20250929` |
| Backend real | proveedor `cc` = **suscripción Claude Code (OAuth)** — usa cuota de suscripción, no créditos de API pay-per-token |
| OmniRoute de la Mac | **decomisionada** (LaunchAgent → `.disabled`, config conservada en `~/.omniroute/`) |

**PENDIENTE (requiere navegador de José):** el OAuth de Claude Code en la OmniRoute de claude-dev es del 3-sep y caducó (da `404 model: Claude Sonnet 5`). Re-autorizar:
1. Abrir `http://192.168.0.64:20128` en el navegador de la Mac
2. Login con `admin` / `11deabril5`
3. Providers → reconectar/re-autorizar **Claude Code (OAuth)**
4. Verificar: `ssh root@192.168.0.52 "pct exec 901 -- su - alejandre -c 'cd ~/GromacsMexicano && ruflo providers test -p anthropic'"`

Mientras el OAuth no se renueve, los agentes de Ruflo no pueden llamar al LLM.
