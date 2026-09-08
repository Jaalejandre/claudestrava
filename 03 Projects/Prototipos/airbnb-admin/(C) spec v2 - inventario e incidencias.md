---
tipo: spec-prototipo
fecha: 2026-09-08
proyecto: airbnb-admin
stack: FastAPI + Jinja2 + JSON files (sin DB)
modelo-objetivo: qwen2.5-coder:14b (local, CT 103)
version-app: v2
---

# Spec v2 — airbnb-admin: inventario + incidencias + bloqueo de fechas

Prototipo existente: FastAPI (`app.py`, 810 líneas) + templates `index.html`, `limpieza.html`, `config.html`, `detail.html` + `static/style.css` + datos en `data/` y `state/` (JSON). Ruta raíz `/project/prototipos/airbnb-admin/` en CT 109.

**Regla: NO romper lo existente.** El dashboard, limpieza, Telegram y configuración de calendarios siguen funcionando igual. Se AÑADEN 3 features y se preservan todos los JSON actuales (tolerar formato viejo, como ya hace `load_sources`).

---

## Feature 1 — Inventario por apartamento

**Archivo de datos:** `state/inventory.json` (crear si no existe).

Estructura (lista de items):

```json
{
  "items": [
    {
      "id": "inv-<uuid6>",
      "apartamento": "<key del apartment>",
      "nombre": "Papel de baño",
      "categoria": "consumible | mobiliario | electronica | limpieza",
      "cantidad": 6,
      "minimo": 4,
      "unidad": "piezas",
      "notas": "",
      "creado": "2026-09-08",
      "historial": [
        {"fecha": "2026-09-08", "cantidad": 6, "proveedor": "Walmart", "costo": 120}
      ]
    }
  ]
}
```

**Vistas y rutas:**
- `GET /inventario` → lista todos los items agrupados por apartamento, con badge de estado:
  - 🔴 ROJO si `cantidad <= minimo`
  - 🟡 AMARILLO si `minimo < cantidad <= minimo * 1.5`
  - 🟢 VERDE si `cantidad > minimo * 1.5`
- `GET /inventario?apartamento=<key>` → filtro por apartamento (también `<select>` en la página).
- `POST /inventario/add` → agregar item (form: apartamento, nombre, categoria, cantidad, minimo, unidad, notas).
- `POST /inventario/adjust` (form: `id`, `delta` entero + o −, proveedor, costo opcional) → ajusta cantidad y si `delta > 0` registra entrada en `historial` (proveedor/costo del form; si no hay, `proveedor: "manual"`, costo 0).
- `POST /inventario/delete` → elimina item (confirmación en JS).
- `GET /inventario/compras` → **lista de compras programada**: todos los items en estado ROJO, agrupados por apartamento, con la cantidad a comprar sugerida = `minimo * 2 - cantidad` (para cubrir el mínimo y dejar margen). Cada item con botón "Registrar compra +<cantidad>".

**Patrón de consumo (simple):** en la página de inventario, debajo de cada item mostrar "Consumo aprox: N/unidad por mes" calculado como:

```python
if len(historial) >= 2:
    span_dias = (fecha_ultima_compra - fecha_primera_compra).days
    unidades_total = sum(h["cantidad"] for h in historial)
    dias_restantes = (cantidad / (unidades_total / span_dias)) if unidades_total else 0
    "queda ~X días de stock según compras registradas"
```

Mostrar eso solo si hay al menos 2 compras; si no, no mostrar nada.

---

## Feature 2 — Incidencias

**Archivo de datos:** `state/incidencias.json` (crear si no existe).

Estructura:

```json
{
  "incidencias": [
    {
      "id": "inc-<uuid6>",
      "fecha_alta": "2026-09-08",
      "apartamento": "<key>",
      "tipo": "desperfecto | dano | robo | fuga | otro",
      "prioridad": "alta | media | baja",
      "descripcion": "...",
      "reporta": "admin | limpieza",
      "bloquea_booking": true,
      "fechas_afectadas": ["2026-09-15", "2026-09-16"],   // solo si bloquea_booking; si vacío se deriva a continuación
      "fecha_inicio": "2026-09-15",   // rango continuo
      "fecha_fin": "2026-09-16",
      "estado": "abierta | en_proceso | resuelta",
      "fecha_resolucion": null
    }
  ]
}
```

**Vistas y rutas:**
- `GET /incidencias` → lista todas, filtros por estado (`abierta|en_proceso|resuelta`) y apartamento (selects). Badge de prioridad. Botones: "En proceso", "Resolver" (cambian estado; resolver pone `fecha_resolucion = hoy`).
- `POST /incidencias/add` → form: apartamento, tipo, prioridad, descripcion, `bloquea_booking` (checkbox), `fecha_inicio`, `fecha_fin` (solo visibles si checkbox). Si `bloquea_booking` → genera `fechas_afectadas` = rango inclusive entre fecha_inicio y fecha_fin.
- `POST /incidencias/status` (form: `id`, `nuevo_estado`) → `abierta|en_proceso|resuelta`.
- `GET /incidencias/{id}` → detalle (opcional, puede ser modal).

**Integración con dashboard:** en `index.html`, si el apartamento tiene una incidencia `abierta` o `en_proceso` con `bloquea_booking=true`, mostrar banner rojo en la tarjeta del apartamento: `🔒 Incidencia activa: <descripcion corta> — sin reservas <fechas>`. Y link a `/incidencias`.

---

## Feature 3 — Bloqueo de calendario vía iCal (Airbnb)

Airbnb NO tiene API pública de hosts, pero **soporta importar calendarios iCal por URL** (Ajustes → Calendario → Importar). Este endpoint genera el iCal de las fechas bloqueadas; el admin pega la URL en Airbnb y el calendario se bloquea solo.

**Rutas:**
- `GET /api/bloqueos/<apartamento>.ics` → sirve `text/calendar` con events `VEVENT` para cada rango bloqueado activo (incidencias con `bloquea_booking=true` y `estado in (abierta, en_proceso)`), más un bloqueo global por incidencia activa sin fechas (usa del día actual en adelante +14 días; `DTSTART;VALUE=DATE` / `DTEND;VALUE=DATE`).

Formato de cada evento:

```
BEGIN:VEVENT
UID:airbnb-admin-<incidencia_id>-<apartamento>
DTSTAMP:<hoy en formato YYYYMMDDTHHMMSSZ>
DTSTART;VALUE=DATE:YYYYMMDD
DTEND;VALUE=DATE:YYYYMMDD   (fecha_fin + 1 día, iCal usa end-exclusive)
SUMMARY:Bloqueado (incidencia <id>)
DESCRIPTION:<descripcion corta>
BEGIN:VALARM
TRIGGER:-PT0S
ACTION:DISPLAY
DESCRIPTION:Bloqueado
END:VALARM
END:VEVENT
```

- `GET /bloqueos` → página de instrucciones: por cada apartamento muestra la URL del `.ics` (`http://192.168.0.64:<puerto>/api/bloqueos/<key>.ics`), botón "Copiar URL", y pasos textuales para pegarla en Airbnb (Ajustes → Calendario → Importar → pegar URL → Guardar). Nota: Airbnb refresca el import unas horas después; hay botón manual de refresco en Airbnb.

- Helper `collect_active_blocks() -> dict[key, list[incidencia]]`: recorre incidencias con `bloquea_booking` y estado activo → devuelve por apartamento los rangos. Reutilizar en `index.html` (banner) y en el `.ics`.

---

## Cambios a archivos existentes

- `app.py`: agregar imports (`uuid`), constantes (`INVENTORY_FILE`, `INCIDENCIAS_FILE`), helpers (`load_inventory/save_inventory`, `load_incidencias/save_incidencias`, `collect_active_blocks`, `generate_ics`), rutas nuevas (feature 1 y 2 y 3), y modificar la ruta `/` para pasar `active_blocks` al template. NO tocar lógica de calendarios/Telegram/limpieza existente.
- `templates/index.html`: agregar banner `🔒 Incidencia activa` en la tarjeta del apartamento (usar la clase por estado del apartment; es solo HTML/Jinja2), y un link `🧾 Inventario` y `🚨 Incidencias` en el header.
- **Nuevos templates:** `templates/inventario.html`, `templates/incidencias.html`, `templates/bloqueos.html`, todos consistentes con el estilo existente de `index.html` (misma paleta, botones redondeados, `style.css`).

---

## Criterio de "funciona" (validación)

1. `python3 -m py_compile app.py` OK en CT 109.
2. `/` responde 200 y muestra banners de incidencia cuando existen.
3. `/inventario` responde 200 y permite: agregar item, ajustar cantidad, ver badge de estado, ver lista de compras.
4. `/incidencias` responde 200 y permite: crear incidencia con bloqueo, cambiar estado a resuelta.
5. Crear incidencia bloqueada → `/api/bloqueos/<key>.ics` devuelve `text/calendar` con el `VEVENT` correcto (fechas inclusive, `DTEND = fecha_fin + 1`).
6. Sin errores al recargar con datos viejos (JSON existente tolerable).
7. El server sigue en puerto 8877 (o el que esté corriendo) y el botón de Telegram sigue funcionando.

## Restricciones del modelo local (importante)

- Una sola respuesta `/api/chat`, format de bloques:
  ```
  === ruta/archivo ===
  <contenido completo>
  === FIN ===
  ```
- Devolver SIEMPRE `app.py` COMPLETO (no "las líneas que cambian" — el orquestador reemplaza el archivo entero), y los 3 templates nuevos completos. `index.html` también completo.
- No usar librerías nuevas fuera de stdlib + FastAPI/Jinja2 ya instaladas.
- No placeholders (`...`, `TODO`, `/path/to`). Código real.
- `temperature: 0.3`, `num_ctx: 32768`, `num_predict: 12000`, `stream: false`, timeout 900s.