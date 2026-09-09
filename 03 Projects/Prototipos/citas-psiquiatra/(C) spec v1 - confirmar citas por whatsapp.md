---
tipo: spec-prototipo
fecha: 2026-09-08
proyecto: citas-psiquiatra
stack: FastAPI + Jinja2 + JSON files (sin DB)
modelo-objetivo: qwen2.5-coder:14b (local, CT 103)
version-app: v1
---

# Spec v1 — citas-psiquiatra: confirmar citas por WhatsApp

Prototipo NUEVO (proyecto no existe). FastAPI + Jinja2 + archivos JSON locales (sin DB, sin login, sin servicios externos). Es un **demo**: el calendario es SIMULADO (datos de ejemplo generados localmente), pero el flujo completo debe ser real y usable.

**Contexto real que demuestra:** una psiquiatra recibe sus citas en Google Calendar y hoy confirma/cancela/reagenda a cada paciente escribiendo manualmente por WhatsApp. Esta app le muestra las citas de los próximos 3 días con 3 acciones (confirmar / cancelar / reagendar), genera el mensaje con los datos del paciente y le da un link `wa.me` que abre WhatsApp en su teléfono con el texto listo. Ella solo pega y envía. El estado de cada cita se guarda localmente (en la versión real esto escribiría de vuelta a Google Calendar).

**Usuario: una persona NO técnica, desde su teléfono.** Interfaz en español, minimalista, legible, botones GRANDES, optimizada para móvil (pero debe verse bien en desktop).

---

## Regla de oro

Nada se envía automáticamente: la psiquiatra SIEMPRE revisa el mensaje y lo manda ella desde WhatsApp. La app nunca toca el calendario sin que ella pulse un botón explícito.

---

## Archivos esperados (crear todos)

```
app.py                    # FastAPI, todo en un archivo
templates/index.html      # panel de citas
templates/preview.html    # preview del mensaje + botón wa.me + marcar como hecho
templates/mensajes.html   # editor de plantillas
templates/agenda.html     # lista de pacientes con teléfono
static/style.css          # estilos (móvil primero, botones grandes)
data/calendario.json      # SEED AUTOGENERADO (ver abajo)
data/pacientes.json       # { "pacientes": [ {"nombre": "...", "telefono": "52..."} ] }
data/mensajes.json        # plantillas editables
```

**Los 4 archivos de `data/` se crean al primer arranque si no existen** (función `ensure_data()` llamada al iniciar la app). `calendario.json` se siembra con eventos RELATIVOS a la fecha actual (hoy/mañana/pasado mañana) para que el demo siempre tenga citas visibles.

---

## Datos

### `data/calendario.json`

```json
{
  "eventos": [
    {
      "id": "cita-001",
      "paciente": "María González",
      "inicio": "2026-09-08T10:00",
      "duracion_min": 50,
      "ubicacion": "",
      "estado": "por_confirmar",
      "nueva_fecha": null
    }
  ]
}
```

- `inicio`: ISO local `YYYY-MM-DDTHH:MM`.
- `ubicacion`: vacío = presencial. Si empieza con `http` → la cita es **virtual** y ese string es el link (ej. `"https://meet.google.com/abc-defg-hij"`).
- `estado`: `por_confirmar | confirmada | cancelada | reagendada`.
- `nueva_fecha`: solo se usa cuando `estado == "reagendada"`; guarda la fecha propuesta ISO.
- **Seed demo:** 6–7 eventos repartidos entre hoy, mañana y pasado mañana (al menos 3 por_confirmar, 1 virtual, 1 ya confirmada, 1 ya cancelada). Nombres y horarios de ejemplo (horarios de consultorio, 09:00–18:00). `duracion_min` 45–60.

### `data/pacientes.json`

```json
{ "pacientes": [ {"nombre": "María González", "telefono": "5215512345678"} ] }
```

- `telefono`: formato internacional SIN `+` ni espacios, `52` + 10 dígitos.
- Este archivo empieza **VACÍO** (`pacientes: []`): la usuaria captura cada teléfono la primera vez. Excepción: incluir 1 paciente demo con teléfono (p. ej. `5215512345678`) para que el flujo completo se pueda probar sin capturar.

### `data/mensajes.json` — plantillas (editables desde la app)

```json
{
  "plantillas": {
    "confirmar": "Hola {paciente}, te confirmo tu consulta el {fecha} a las {hora}. ¡Nos vemos!",
    "cancelar": "Hola {paciente}, tu consulta del {fecha} a las {hora} queda cancelada. Te aviso cuando pueda reagendarte.",
    "reagendar": "Hola {paciente}, ¿te funciona mover tu consulta al {nueva_fecha}?",
    "linea_virtual": "Tu consulta será por videollamada: {link_meet}"
  }
}
```

- Placeholders válidos: `{paciente}`, `{fecha}`, `{hora}`, `{nueva_fecha}`, `{link_meet}`.
- `fecha` se muestra en español legible ("hoy", "mañana", o "dd/mm"). `hora` como `HH:MM`.
- En mensajes `confirmar` y `reagendar` de una cita **virtual**, el texto final = plantilla + `"\n\n"` + `linea_virtual` (con el link reemplazado). En `cancelar` nunca se agrega.

---

## Rutas y flujo

Las rutas de POST responden **200 siempre** (aunque falten parámetros: guardan lo que hay y redirigen a `/`). Las de GET renderizan template.

### `GET /` — panel de citas (`index.html`)
- 3 secciones: **Hoy · Mañana · Pasado mañana** (fechas relativas a `datetime.now()`).
- Cada cita = tarjeta con:
  - Nombre del paciente, fecha y hora.
  - Badge `🖥 Virtual` si `ubicacion` empieza con http, si no `🏢 Presencial`.
  - Badge de estado: `por_confirmar` (naranja), `confirmada` (verde), `cancelada` (gris, tarjeta atenuada), `reagendada` (azul, mostrando "Propuesta: {nueva_fecha}").
- Botones (SOLO si no está cancelada):
  - **Confirmar** → `GET /preview?id=<id>&tipo=confirmar`
  - **Cancelar** → `GET /preview?id=<id>&tipo=cancelar`
  - **Reagendar** → form GET con input `datetime-local` (oculto hasta pulsar "Reagendar", mínimo JS) → `GET /preview?id=<id>&tipo=reagendar&nueva_fecha=<valor>`
- **Si el paciente no tiene teléfono guardado:** la tarjeta muestra solo un input "Teléfono" + botón **"Guardar teléfono"** (`POST /guardar-telefono`) y los botones de acción aparecen después de guardar. Si ya tiene teléfono, también un link pequeño "✏️ editar" que reabre el input.

### `GET /preview?id=&tipo=&nueva_fecha=` — `preview.html`
- Monta el mensaje final con la plantilla correspondiente (sustituyendo placeholders; agrega `linea_virtual` si la cita es virtual y tipo es confirmar/reagendar).
- Calcula el link de WhatsApp: `https://wa.me/<telefono>?text=<texto url-encoded>`.
- Muestra: resumen de la cita (nombre, fecha/hora, virtual/presencial), el **mensaje completo en un cuadro editable** (`<textarea>`), y el link actualizado en vivo con JS.
- Botón verde GRANDE **"Abrir WhatsApp"** (href al link wa.me, `target="_blank"`).
  - Nota: `wa.me` con `text` SIEMPRE abre WhatsApp con el texto precargado (terminal o teléfono).
- Botón secundario **"✓ Ya lo envié — marcar {tipo}"** → `POST /confirmar` | `/cancelar` | `/reagendar` (con `id` y `nueva_fecha` si aplica) → redirige a `/`.
- Botón "← Volver" → `/`.
- Si falta `id` o `tipo` inválido → renderiza igual con aviso "Cita no encontrada" (200).

### `POST /confirmar` (form: `id`) → estado = `confirmada`
### `POST /cancelar` (form: `id`) → estado = `cancelada`
### `POST /reagendar` (form: `id`, `nueva_fecha`) → estado = `reagendada` + guarda `nueva_fecha`
### `POST /guardar-telefono` (form: `nombre`, `telefono`)
- Normaliza: solo dígitos (`re.sub(r"\D", "", telefono)`); si quedan 10 dígitos → antepone `52`; si 12 y empieza con `52` → deja igual.
- Guarda en `pacientes.json` (sobrescribe si el nombre ya existe — así "guardar" también sirve para editar). Redirige a `/`.

### `GET /mensajes` — `mensajes.html`
- Un `<textarea>` por plantilla (confirmar, cancelar, reagendar, linea_virtual) + leyenda de placeholders disponibles.
- Botón **"Guardar"** → `POST /guardar-plantilla` → redirige a `/mensajes`.
- Mini live preview con datos demo en JS (opcional).

### `POST /guardar-plantilla` (form: `clave`, `texto`) → redirige a `/mensajes`

### `GET /agenda` — `agenda.html`
- Tabla simple: nombre, teléfono (legible `52 55 1234 5678`), link "WhatsApp" (wa.me con vacío o mensaje corto "Hola"), botón "Editar" (reabre form con input).
- **Reusar** `POST /guardar-telefono` para la edición (mismo form).

---

## Diseño (estético — el harness no lo valida, hay que cuidarlo)

- Móvil primero: ancho máximo 560px centrado, padding cómodo, fuente legible.
- Tarjetas con borde suave, esquinas redondeadas, estados con color claro de fondo (verde/gris/azul/naranja).
- Botones grandes (mín. 44px de alto), texto en español, contraste claro.
- Encabezado con el nombre de la app ("Mis citas") y links: Citas · Mensajes · Agenda.

---

## Criterio de "funciona" (validación del harness)

- `py_compile` sin errores.
- Todos los `TemplateResponse(...)` apuntan a templates existentes.
- Probes HTTP con 200 en: `GET /`, `GET /preview` (sin parámetros), `GET /mensajes`, `GET /agenda`, `POST /confirmar`, `POST /cancelar`, `POST /reagendar`, `POST /guardar-telefono`, `POST /guardar-plantilla`.
- No romper archivos existentes (integridad; proyecto nuevo, baseline = archivos generados).
- Fecha de las secciones "Hoy/Mañana/Pasado mañana" calculada con `datetime.now()` (no fechas hardcodeadas).

## Fuera de alcance (NO implementar)

- Integración real con Google Calendar / OAuth (el seed local lo simula).
- Envío automático de WhatsApp (siempre link wa.me manual).
- Login/usuarios, base de datos, frameworks de frontend/bundlers.
- Recordatorios automáticos previos a la cita.