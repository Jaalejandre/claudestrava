---
tipo: log-prototipo
fecha: 2026-09-08
proyecto: airbnb-admin
modelo: qwen2.5-coder:14b (CT 103)
estado: ✅ funcionando v3 (rediseño)
---

# (C) Log — airbnb-admin

## v3 — Rediseño visual con harness agéntico (2026-09-08)

Con la nueva skill (Ollama hace TODO), el **harness.py** corrió el rediseño completo:
- **1 iteración** → PASS. qwen2.5-coder:14b generó `style.css` (6.7 KB) + 7 templates rediseñados (paleta moderna, tarjetas, badges, responsive).
- El harness **encontró 2 bugs reales de v2** que se me escaparon en el review manual:
  - fences ` ```html ` en 3 templates (se renderizaban como texto en pantalla)
  - `incidencia_detail.html` referenciado por una ruta pero nunca generado
- **Hotfix aplicado** (fences + template nuevo) y commit `110c2e4` antes de relanzar.
- Bugs del harness descubiertos en el camino (3 fixes a la heurística de helpers, guarda anti-repetición, rutas dinámicas `{id}`).
- Verificación post-harness: navegación completa, POSTs siguen funcionando (303), pages 200.
- Commit rediseño: `d34fce0`.

## v2 — inventario + incidencias + bloqueo iCal (2026-09-08)

…(ver sección previa)…

## Qué se pidió
- **Inventario** por apartamento con mínimos, badges de stock (🔴🟡🟢), historial de compras, patrón "queda X días de stock", y lista de compras programada (`minimo*2 - cantidad`).
- **Incidencias** reportables por admin/limpieza (tipo, prioridad, estado abierta/en_proceso/resuelta).
- **Bloqueo de calendario Airbnb** vía iCal: Airbnb no tiene API pública de hosts, pero sí importa calendarios iCal por URL → la app sirve `/api/bloqueos/<key>.ics`.

## Flujo seguido (skill prototipo-local)
1. Spec v2 escrito en vault → `(C) spec v2 - inventario e incidencias.md`
2. Generación con `qwen2.5-coder:14b` vía `/api/chat` (2 llamadas: app.py 1032 líneas + 4 templates)
3. Escritura con backup (`backup_v2_*`, luego limpiado)
4. Revisión manual + 4 rondas de fixes de errores silenciosos del modelo:
   - `KeyError: incidencias` con JSON vacío `{}` → loaders tolerantes
   - `NameError: date_range` → helper agregado
   - `inventory` no pasado al template → contexto completo
   - Jinja2 `inventory.items` resuelve al método → `items`
   - `inventario_compras` referenciaba template inexistente → reintegró a `inventario.html`
   - ICS emitía fechas `2026-09-20` (ISO) → formato básico iCal `20260920`
   - `bloqueos.html` venía envuelto en fence ```html → limpio
   - checkbox `bloquea_booking` requerido → `Form(False)`
5. Validación end-to-end: 15/15 ✓ (7 páginas 200, POSTs, ICS con fechas correctas, banner 🔒, limpieza al resolver)
6. Servicio con `systemd-run --unit=proto-airbnb` puerto 8877

## Errores que documentar para el futuro
- El modelo local **sí mete fences de markdown** a pesar de instrucciones → checker al escribir.
- Usa helpers que no define (`date_range`) → revisar nombres referenciados.
- Referencia templates que no genera → validar todos los `TemplateResponse` contra `templates/`.
- Fechea: el check de sintaxis (`py_compile`) no basta; correr prueba HTTP de todas las rutas.

## Costo aproximado
- Tokens de modelo local: ~30k (2 gen + nada de iteraciones — los fixes los hizo Claude).
- Claude: orquestación + fixes. GPU libre verificada antes de generar.

## Estado al cierre
- URL: `http://192.168.0.64:8877/`
- Datos de test limpiados. Git commit `fa8cab3`.