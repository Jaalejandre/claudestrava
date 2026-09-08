---
tipo: log-prototipo
fecha: 2026-09-08
proyecto: airbnb-admin
modelo: qwen2.5-coder:14b (CT 103)
estado: ✅ funcionando (baseline v2 + hotfixes, commit c79f10d) — rediseño EN PAUSA
---

# (C) Log — airbnb-admin

## Línea de tiempo de commits (estado actual)

| Commit | Qué | Estado |
|---|---|---|
| `58f1396` | Copia base de airbnb-dashboard (CT112) | base |
| `fa8cab3` | **v2**: inventario + incidencias + bloqueo iCal (spec v2) | ✅ entregado |
| `110c2e4` | **hotfix v2**: quitar fences markdown de 3 templates + crear `incidencia_detail.html` (bugs que encontró el harness) | ✅ aplicado |
| `d34fce0` | **v3 rediseño visual** (harness, 1 iteración) | ❌ **REGREGIÓN — revertido** |
| `c79f10d` | **revert v3** + state limpio | ✅ **ESTE ES EL BUENO (actual)** |

## ✅ Estado actual (tras revertir la regresión)

- **App 100% funcional v2 + hotfixes.** Servicio `proto-airbnb` corriendo en puerto 8877 → `http://192.168.0.64:8877/`.
- **Features:** dashboard con estados, limpieza, config iCal, inventario (badges 🔴🟡🟢 + compras), incidencias (prioridad/estado/bloqueo), bloqueos (`/api/bloqueos/<key>.ics`), Telegram.
- `state/incidencias.json` e `state/inventory.json` = `{}` (limpios).

## ❌ Lección v3 — el rediseño de Ollama fue REGRESIÓN (no mejora)

- **Qué pasó:** el harness validó "rutas 200 + compile + templates existen" pero el modelo **eliminó 1,132 líneas de contenido** en los templates (index pasó de 8,982 → 2,904 chars). Todo seguía respondiendo 200 = harness dijo PASS con un producto vaciado. **La validación no medía preservación de contenido.**
- **Error mío adicional:** antes de relanzar el rediseño reinicié `state/*.json` a `{}` (data de pruebas perdida — no había datos reales del usuario, pero no debí borrar así).
- **Fix de raíz (harness v7/v8):** nueva sección en specs `## Archivos modificables` → el harness **bloquea y revierte por git** cualquier archivo modificado fuera de esa lista. Si el spec dice `static/style.css`, los templates NO se pueden tocar → regresión imposible.
- **Siguiente intento en curso (spec v4):** rediseño **solo CSS** (`static/style.css` es el único archivo modificable) que estilice las clases EXISTENTES de los templates. Spec listo en vault; el run se quedó pendiente porque el usuario pidió pausar y actualizar memoria. **Continuar = correr:**
  ```
  python3 /project/prototipos/harness.py "/root/JarvisVault/03 Projects/Prototipos/airbnb-admin/(C) spec v4 - rediseño solo css.md" /project/prototipos/airbnb-admin 8877 6
  ```

## Historia (resumen)

- **v2 (fa8cab3):** inventario + incidencias + bloqueo iCal generados por qwen2.5-coder:14b en 2 llamadas (app.py 1,032 líneas + 4 templates). 15/15 chequeos manuales ✓. Errores silenciosos del modelo corregidos por mi (8): KeyError con JSON vacío, `NameError: date_range`, `inventory` no pasado al template, Jinja2 `inventory.items`→método, template inexistente `inventario_compras.html`, fechas ISO→iCal básico, fence en bloqueos.html, checkbox requerido.
- **Hotfix (110c2e4):** el harness v1 encontró 2 bugs que mi review manual no vio: fences markdown ` ```html ` en index/inventario/incidencias (se renderizaban como texto en el navegador) y `incidencia_detail.html` referenciado pero nunca generado (ruta `/incidencias/{id}` fallaba).
- **v3 (d34fce0):** rediseño por harness → regresión → revertido (ver arriba).

## Harness (`/project/prototipos/harness.py` — copia versionada en `03 Projects/Prototipos/harness.py`)

Evolución en esta sesión: v1 (loop base) → v2 (rutas absolutas, mapeo `ruta`) → v4 (async def, marcadores `-----`, guarda anti-repetición) → v6 (keywords, rutas `{id}`, snapshots) → **v7/v8 (regla `## Archivos modificables` + integridad con revert por git + orden CSS/HTML primero en contexto)** → v8.1 (fix import hashlib).

Funciones: genera → escribe → valida (compile, fences, templates existentes, probes HTTP a todas las rutas con datos reales para `{apartamento}`/`{id}`) → corrige con el modelo (max 6-8 iteraciones) → `systemd-run` → imprime URL. Aprende vía `error_log.json` (lecciones inyectadas al inicio del prompt).

**Limite conocido (IMPORTANTE):** el harness valida funcionamiento y ahora integridad de archivos, pero NO render visual. Un diseño puede "pasar" y verse mal. Para diseño: usar specs CSS-only (v4) o revisión visual humana después del PASS.

## Datos de estado

- `error_log.json` en `/project/prototipos/` = `[]` (se limpió: los errores registrados eran bugs del harness, no del modelo).
- Specs en vault: v2 (inventario/incidencias), v3 (rediseño ❌), v4 (rediseño solo CSS, pendiente de correr).
- Skills: [[prototipo-local.md]] actualizada con filosofía "Ollama hace TODO" + sección de integridad.