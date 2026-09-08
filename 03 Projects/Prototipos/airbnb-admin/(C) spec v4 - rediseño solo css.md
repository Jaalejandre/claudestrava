---
tipo: spec-prototipo
fecha: 2026-09-08
proyecto: airbnb-admin
tarea: rediseño solo CSS (preservando TODO el contenido)
modelo-objetivo: qwen2.5-coder:14b (CT 103)
---

# Spec v4 — Rediseño de airbnb-admin SOLO vía CSS

## REGLA DE ORO (integridad)

**NO toques NADA excepto `static/style.css`.** No modifiques templates, ni app.py, ni datos. El contenido, la estructura HTML y todos los formularios quedan EXACTAMENTE como están. Todo el rediseño se logra escribiendo un `style.css` completo que estilice las clases Y etiquetas EXISTENTES de los templates.

## Archivos modificables

- static/style.css

## Qué es esto

La app (FastAPI + Jinja2) está 100% funcional con templates ya estructurados: dashboard de apartamentos, limpieza, config, inventario, incidencias, bloqueos, detalle. Escribe un `style.css` moderno y profesional que haga brillar ESA estructura sin tocar una sola línea de HTML.

## Dirección de diseño

- Panel de administración moderno (referencia: Linear/Stripe/Notion). Fondo suave `#f1f5f9`, tarjetas blancas `#ffffff` con shadow suave (`0 8px 24px rgba(15,23,42,.08)`), bordes redondeados 12–16px, radios consistentes.
- Tipografía: fuente del sistema / Inter, títulos `#0f172a`, texto secundario `#64748b`, números/badges claros.
- Selector de clases: **usa los selectores que YA existen en los templates.** Para estilos genéricos usa etiquetas (`body`, `h1`…) y atributos (`input[type=text]`, `button`).
- Badges de estado: classes que ya existen tipo `.free`, `.occupied` (u otras que veas en los templates) con colores claros (verde Libre, índigo Ocupado, ámbar transiciones).
- Nav: el header tiene enlaces (a /limpieza, /inventario, /incidencias, /bloqueos, /config). Estilízalos como botones/pestañas claros; resalta visualmente la página actual (si no hay class activa, usa `:has` o el estilo de botones consistente).
- Botones: primarios con acento (índigo `#4f46e5` o emerald `#059669`), hover suave, `cursor:pointer`, focus visible para accesibilidad.
- Formularios: inputs con bordes `#e2e8f0`, focus ring sutil, espaciado cómodo.
- Responsive: a 375px las tarjetas pasan a una columna, la navegación queda usable (flex-wrap), tablas no se desbordan.
- Mantener/mejorar el scroll suave; sin animaciones molestas (solo transiciones 0.15-0.2s).

## Para saber qué clases usan los templates

Revisa el contenido de `templates/*.html` que se te pasa en contexto. Tu CSS debe cubrir LAS CLASES Y ETIQUETAS QUE APARECEN ahí. Si un template usa algo raro (ej. `style=""` inline), respétalo y estiliza alrededor.

## Criterio de "funciona"

1. `static/style.css` es el ÚNICO archivo que cambia.
2. Todas las páginas siguen 200 y el contenido HTML es idéntico al actual.
3. El CSS cubre: tarjetas, header/nav, badges de apartamento, badges de inventario, badges de incidencia, forms, botones, tablas (si existen), responsive mobile.
4. Sin `TODO`, sin fences, sin placeholders.
5. El auto-refresh del dashboard meta queda intacto (vive en el template, no lo tocas).