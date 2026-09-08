# Skill: Prototipo local (agente Ollama en el server)

Generar prototipos web simples usando un modelo local en el servidor, donde **EL MODELO LOCAL HACE TODO**: genera, prueba, encuentra sus errores y se corrige a sí mismo. Claude solo escrible el spec y reporta el resultado. Barato, local, privado. Esta skill también sirve para **medir la capacidad real del modelo local** de completar una tarea de principio a fin (DRIVER: iteración por errores, log de aprendizaje).

## Cuándo usar

- El usuario pide un **prototipo simple**: landing page, app chica, demo CRUD, mockup, componente aislado, script de utilidad.
- La tarea NO necesita corrección sutil ni decisiones de arquitectura. Si sí → hazlo tú con Claude directo, no delegues.
- Ideal cuando el usuario quiere que el modelo local demuestre autonomía total (generar + testear + arreglar).

## Infraestructura

| Pieza | Dónde |
|---|---|
| Modelo | **Ollama en CT 103** (`192.168.0.99:11434`), GPU RTX 5070 Ti. Modelos en `nvme-fast` (`/opt/ollama-models`). |
| Modelos disponibles | `qwen2.5-coder:14b` (por defecto, mejor para código), `gpt-oss:latest` (20B, razonamiento), `gemma3:latest` |
| Endpoint | **Usar `http://192.168.0.99:11434/api/chat`** (nativo). El `/v1/chat/completions` (OpenAI-compat) **ignora `options.num_ctx` y trunca el contexto** → el modelo alucina. Para tareas con mucho contexto, siempre `/api/chat` con `options.num_ctx` explícito. |
| **Harness agéntico** | `/project/prototipos/harness.py` en CT 109 — el cerebro del loop. Ver "El patrón" abajo. |
| **Log de aprendizaje** | `/project/prototipos/error_log.json` — errores que el modelo cometió y corrigió. Se inyectan como "lecciones" en cada prompt nuevo → el modelo **aprende de sus errores** entre proyectos. |
| Venv compartido | `/project/prototipos/.venv-harness/` (fastapi + uvicorn) para proyectos sin venv propio. |
| Workspace del código | **CT 109** `/project/prototipos/<nombre>/` |
| Notas / specs | `03 Projects/Prototipos/<nombre>/` en el vault |

> **opencode** está instalado en CT 109 pero **NO se usa** para esto: su loop agéntico emite tool-calls como texto y se cuelga con modelos 14–20B. El loop fiable es **harness.py**: sincrónico, contexto de texto plano, sin tool-calls — probado el 2026-09-08 (genera, testea rutas reales, corrige en 1–6 iteraciones).

## El patrón (Ollama resuelve todo — Claude solo reporta)

**El harness hace el ciclo completo sin intervención:**

```bash
# En CT 109:
python3 /project/prototipos/harness.py "<ruta-spec.md>" /project/prototipos/<nombre> <puerto 8850-8899>
```

1. **Spec.** Claude escribe `03 Projects/Prototipos/<nombre>/(C) spec.md`: qué es, stack, archivos esperados, criterio de "funciona". **En proyectos EXISTENTES agregar la sección `## Archivos modificables`** con la lista de archivos que el modelo tiene permitido tocar. Este es el ÚNICO input humano/Claude.
2. **Generar.** El harness pide a Ollama todos los archivos en una llamada (`=== ruta === … === FIN ===`, `temperature 0.3`, `num_ctx 32768`, timeout 950s). Si el proyecto ya existe, le pasa el código actual (CSS/templates primero, app.py al final) y le pide MODIFICAR sin romper nada.
3. **Escribir.** El harness parsea los bloques (tolera rutas absolutas, fences, `ruta` literal) y los escribe en `/project/prototipos/<nombre>/`.
4. **Testear (el harness NUNCA se salta esto).** Corre solo:
   - `py_compile` de `app.py`
   - fences de markdown en archivos de código
   - que todos los `TemplateResponse("x.html")` apunten a templates que existen
   - helpers invocados pero sin definir (heurística `find_undefined_names` — solo warning)
   - **probes HTTP reales**: levanta uvicorn y hace GET/POST a TODAS las rutas detectadas en `app.py`, verificando 200 (y `BEGIN:VCALENDAR` en rutas `.ics`; rutas dinámicas `{apartamento}`/`{id}` usan datos reales del proyecto).
   - **INTEGRIDAD (v7+)**: compara hashes de cada archivo del proyecto contra el baseline inicial; si el spec declaró `## Archivos modificables` y el modelo tocó algo fuera de la lista → FALLA y el harness restaura por git. Esto evita que un "rediseño" borre contenido (lección del v3 de airbnb-admin).
5. **Corregir.** Si algo falla, el harness manda al modelo el error real + los archivos actuales + el spec + las **lecciones del error_log.json**. El modelo devuelve SOLO los archivos corregidos. Repite hasta 6 iteraciones.
6. **Entregar.** Con todos los chequeos verdes, el harness levanta el servicio con `systemd-run --unit=proto-<nombre>` e imprime:
   ```
   ✅ PROTOTIPO <nombre> LISTO
      URL: http://192.168.0.64:<puerto>/
      Iteraciones: N | Errores corregidos: M
   ```
7. **Aprender.** Cada fallo que el modelo corrige se registra en `error_log.json` (`{fecha, proyecto, error, fix, resuelto}`). Los próximos proyectos reciben las últimas 15 lecciones en el system prompt → evita repetirlos.

**Si se agotan las 6 iteraciones** → el harness imprime `❌ OLLAMA NO PUDO COMPLETARLO` + el último error. Claude lo reporta TAL CUAL. **Claude NO toca el código** — esa es la regla de esta skill. Si el usuario quiere que Claude sí lo arregle, se sale del flujo (cambio explícito de modo).

**Límite conocido del harness (IMPORTANTE):** valida funcionamiento técnico (compile, rutas, integridad de archivos) pero NO render visual ni calidad de diseño. Un diseño puede "pasar" y verse mal (lección v3: vació templates y respondió 200 en todo). Regla práctica:
- Para **rediseño / estética**: usar specs **solo-CSS** (`## Archivos modificables: static/style.css`) que estilicen las clases existentes, o revisión visual humana después del PASS.
- Para **features nuevas**: primar checks HTTP sobre cualquier review de código del modelo.

## Reglas

- **Verificar GPU libre antes de lanzar** (`pve-status` / `qct 103`): qwen-coder (9 GB) + un benchmark de Gromacs no caben en la RTX 5070 Ti.
- **Nunca saltar el harness.** El loop manual paralelo (Claude escribiendo/leyendo archivos) solo para inspección, no para sustituirlo.
- **Con datos viejos en el proyecto:** tolerar formato previo (loaders con default), como ya hace `load_sources`.
- **Solo prototipos.** Si crece a algo real → se promueve a proyecto propio con New Dev Project y pasa a Claude.
- Prototipos son **desechables**: `/project/prototipos/` no es sagrado. El vault solo guarda spec + log.
- **El error_log.json es sagrado** — es la memoria del modelo local. No borrarlo (solo reemplazarlo por `[]` si los errores fueron bugs del harness, no del modelo).

## Modelo por rol

| Tarea | Modelo |
|---|---|
| HTML/CSS/JS, componentes, CRUD | `qwen2.5-coder:14b` |
| Lógica que necesita razonar un poco, algoritmos | `gpt-oss:latest` |
| Respuestas rápidas triviales | `gemma3:latest` |

## Entrega al usuario (obligatorio al terminar)

Al completar el prototipo, **siempre dar la URL de acceso** (el harness la imprime, solo relayar):

```
✅ Prototipo <nombre> listo
🔗 http://192.168.0.64:<puerto>/
```

Los puertos viven en rango **8850–8899**. El servicio corre con `systemd-run --unit=proto-<nombre>` y sobrevive al cierre del SSH. Para pararlo: `ssh root@192.168.0.52 "pct exec 109 -- systemctl stop proto-<nombre>"`.