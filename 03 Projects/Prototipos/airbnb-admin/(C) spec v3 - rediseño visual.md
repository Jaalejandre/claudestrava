---
tipo: spec-prototipo
fecha: 2026-09-08
proyecto: airbnb-admin
tarea: rediseño visual (UI/UX)
modelo-objetivo: qwen2.5-coder:14b (CT 103)
---

# Spec — Rediseño visual de airbnb-admin

Proyecto existente en `/project/prototipos/airbnb-admin/` (FastAPI + Jinja2 + JSON). Está FUNCIONAL con estas páginas y rutas — **NO toques la lógica, solo el diseño**:

- `/` — dashboard con tarjetas de apartamentos (estado Libre/Ocupado, entradas/salidas)
- `/limpieza` — checklist de limpieza + toggle
- `/config` — calendarios iCal
- `/inventario` — inventario con badges 🔴🟡🟢 y lista de compras
- `/incidencias` — incidencias con prioridad y estado
- `/bloqueos` — URLs `.ics` para sincronizar Airbnb
- `/api/bloqueos/<key>.ics` — endpoint iCal
- Telegram webhook y botón de conexión

## Qué es esto

La app funciona pero el diseño es básico. Vuélvela **moderna, limpia y profesional** sin cambiar ninguna ruta, dato, formulario ni el comportamiento. Los cambios van en `templates/*.html` y `static/style.css` (y `app.py` SOLO si es estrictamente necesario — preferiblemente no).

## Dirección de diseño

- **Estética:** panel de administración moderno (referencia: Linear, Stripe, Notion). Fondo suave `#f1f5f9`-ish, tarjetas blancas con sombra sutil y bordes redondeados (12–16px), sin ruido.
- **Header:** barra con el título y navegación clara (botones/pestañas: Dashboard, Limpiezas, Inventario, Incidencias, Bloqueos, Config). Activo/actual resaltado.
- **Tipografía:** sistema (Inter/sans-serif stack), jerarquía clara, títulos negros `#0f172a`, texto secundario `#64748b`.
- **Badges de estado del apartamento:** Libre = verde, Ocupado = azul/índigo, Sale/Entra = ámbar, con chips redondeados. Búsqueda de "Sale hoy" / "Entra hoy" visibles de un vistazo.
- **Inventario:** badges de stock (rojo si ≤ mínimo, amarillo si ≤ 1.5×min, verde si más) claros; lista de compras distinguible con un panel suave.
- **Incidencias:** prioridad alta = rojo, media = ámbar, baja = slate; estado abierta/en_proceso/resuelta con badges de color; banner 🔒 en dashboard cuando hay incidencia bloqueante.
- **Responsive:** en móvil (el personal de limpieza lo usa en el celular), las tarjetas pasan a una columna y la navegación queda usable.
- **Botones:** primarios con color de acento (index 6/600), hover sutil, `cursor:pointer`.
- Mantén el `meta http-equiv="refresh" content="120">` (auto-refresh del dashboard).

## Archivos

- `static/style.css` — reescrito completo (es la base del rediseño)
- `templates/index.html`, `templates/limpieza.html`, `templates/config.html`, `templates/inventario.html`, `templates/incidencias.html`, `templates/bloqueos.html`, `templates/detail.html` — usar las clases del nuevo CSS
- NO cambiar IDs/nombres de inputs ni acciones de los forms (la lógica POST depende de ellos)

## Criterio de "funciona"

1. Todas las páginas responden 200 y sus formularios siguen funcionando (mismos names de campos).
2. `py_compile app.py` pasa (aunque idealmente app.py no cambia).
3. Sin fences de markdown, sin placeholders, sin `TODO`.
4. En móvil (viewport 375px) la navegación y las tarjetas se ven bien.
5. El auto-refresh del dashboard sigue activo.
6. Las clases nuevas del CSS están todas definidas en `style.css` (sin clases huérfanas).