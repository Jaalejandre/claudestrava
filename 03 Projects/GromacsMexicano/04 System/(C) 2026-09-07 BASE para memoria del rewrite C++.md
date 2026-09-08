# BASE — memoria persistente del rewrite C++ (setup 2026-09-07)

Reemplaza a Ruflo (ver [[(C) 2026-09-07 Ruflo para orquestar el rewrite C++.md]], supersedido).

**BASE** (`github.com/ChristopherKahler/base`, "Builder's Automated State Engine") es un **binario Rust único** (~20 MB, `~/.local/bin/base`, v0.14.1) que da memoria persistente + grafo de conocimiento (código vía tree-sitter, proyectos, decisiones, reglas, tareas) a Claude Code. Inyecta contexto automáticamente vía **hooks nativos** en `~/.claude/settings.json` en 4 puntos: session-start, user-prompt-submit, pre-tool-use, post-tool-use. Nada sale de la máquina.

## Por qué se cambió de Ruflo a BASE

| | Ruflo (claude-flow) | BASE |
|---|---|---|
| Runtime | Node 22 exacto (24 rompe `better-sqlite3`), onnxruntime, warnings constantes | 1 binario Rust, sin toolchain |
| Integración | consulta manual (`ruflo memory retrieve …`) | hooks automáticos, contexto se inyecta solo |
| Cabos sueltos | `ruflo start` "not initialized", probe 401 | ninguno |

Decisión registrada en el grafo: `rewrite-cpp.base-reemplaza-a-ruflo-como-sistema-de-memoria-del-rewrite`.

## Arquitectura

- **BASE vive en CT 901** (`ssh root@192.168.0.52 "pct exec 901 -- su - alejandre -c '<cmd>'"`), junto al código, workspace `/home/alejandre/GromacsMexicano/` (`.base/` + `.base-ast/`, ambos en `.gitignore`).
- Para que los hooks tengan dónde engancharse se **instaló Claude Code en CT 901** (`/usr/bin/claude` v2.1.x, npm global vía root). Antes no había ningún Claude Code ahí — el trabajo del rewrite lo hacía Claudian desde la Mac por SSH.
- **Claude Code en CT 901 enruta por OmniRoute** (`~/.claude/settings.json` → `ANTHROPIC_BASE_URL=http://192.168.0.64:20128`, `ANTHROPIC_API_KEY=sk-784af7b27f4f9ca0-…`, `ANTHROPIC_MODEL=cc/claude-sonnet-4-5-20250929`). Backend `cc` = suscripción Claude Code OAuth. Probado: `claude -p` → responde.
- Node 22 LTS (el mismo que pedía Ruflo; Claude Code también corre bien ahí).

## Qué se cargó en el grafo

**Proyectos:** `gromacsmexicano-c-rewrite` (activo, `Programa_DM_cpp`), `programa-dm-fortran-frozen-reference` (deferred, `Programa_DM`).

**Reglas (dominio `REWRITE-CPP`, se inyectan cuando el prompt/paths hacen match):**
1. No modificar el Fortran de `Programa_DM/` sin permiso (referencia congelada; excepción autorizada: guard aditivo de `fzas_lj_st_cuda.cu` idéntico en ambas copias).
2. La física manda: fuera de 1σ de `Total = -89.05846 ± 0.01195 kJ/mol` → no vale.
3. Un cambio por iteración, un commit por subsistema validado; nunca portar a ciegas (plan detallado leyendo el Fortran real antes de cada fase).
4. Verificar CT 901 libre (`who` + `ps aux | grep dm_mx_npt` + `nvidia-smi`) antes de cada benchmark.
5. Nunca lanzar agentes en background para este proyecto.
6. Cambio de kernel CUDA = protocolo completo (build release, caso real 10000 pasos 3×, 1σ, cero crashes, sin regresión de wall-time).

**Decisiones:** strangler-fig a C++; OmniRoute como gateway de tokens; BASE reemplaza a Ruflo.

**Tareas:** Fase 3 Task 2–6, Fase 4 (riesgo alto), Fase 5.

**Nota de estado (`shift`):** Fase 0/1 ✅ (`4547b7a`), Fase 2 ✅ (`ee500a3`), Fase 3 Task 1 ✅ (`6c45e64`). Sigue: Fase 3 Task 2. Ronda GPU cerrada en `ca9ef61` (−45.7%).

**AST:** 540 entidades mapeadas (Fortran + C++ + CUDA), `base ast query -c <nombre>` / `--calls <fn>` / `-f <archivo>`.

## Comandos útiles

```sh
base doctor                      # salud del grafo
base recall <palabra>            # buscar notas/decisiones
base learn --type shift --domain REWRITE-CPP --project gromacsmexicano-c-rewrite --text "…"
base decision log --domain REWRITE-CPP --decision "…" --rationale "…"
base rule add --domain REWRITE-CPP --text "…"
base task list ; base task add -p gromacsmexicano-c-rewrite -n "…"
base sync --ast --yes            # re-mapear el código
base context                     # ver qué inyectaría el hook ahora
base uninstall                   # quita hooks + binario + sección de CLAUDE.md
```

## Ruteo de modelos (2026-09-08)

- **Sonnet 5** (`cc/claude-sonnet-5`) = modelo por defecto de Claude Code en CT 901 (`~/.claude/settings.json`, `ANTHROPIC_MODEL` + `ANTHROPIC_SMALL_FAST_MODEL`). Cubre programar, documentar y git.
- **Opus 5** (`cc/claude-opus-5`) para review y pensamiento estratégico, vía subagentes en `~/GromacsMexicano/.claude/agents/`:
  - `reviewer` — code review, validación de física, auditoría de correctitud.
  - `architect` — planeación de fases, trade-offs, decisiones de diseño.
- Regla en el grafo BASE (`REWRITE-CPP`, rule 6) y en el CLAUDE.md raíz del vault.
- Ambos modelos salen por OmniRoute → suscripción Claude Code.

## Rough edges

- El hook `session-start` reescribe una sección "BASE CLI" en `~/.claude/CLAUDE.md` de `alejandre` en CT 901 (no en el vault) en cada release. Cosmético.
- Solo Linux x86_64 / macOS. CT 901 es x86_64 ✓.
- `.base/graph.nq` NO se versiona (gitignored) — si CT 901 muere se pierde; este documento + los commits son el respaldo humano. Mismo trade-off que tenía Ruflo.
