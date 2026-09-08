---
tipo: analisis
proyecto: airbnb-dashboard (CT 112, /opt/airbnb-dashboard)
generado_por: gpt-oss:latest (local, CT 103) + revisión de Claude
fecha: 2026-09-08
---

# airbnb-dashboard — documentación y mejoras

> Análisis del código hecho con el modelo local (`gpt-oss:latest`) y **verificado por Claude contra el código real**. Lo que sigue es la versión corregida. El volcado crudo del modelo está en `(C) analisis crudo (gpt-oss).md`.

## 1. Qué es

Dashboard web (FastAPI + uvicorn, Jinja2, sin base de datos — JSON en disco) para gestionar reservas de varios departamentos de Airbnb. Sincroniza calendarios iCal, muestra el estado de reservas y limpiezas, y manda alertas de limpieza por Telegram. Corre en Docker en CT 112 `app-dev`, puerto **8090**.

## 2. Arquitectura y flujo de datos

```
iCal (URLs en data/calendar_sources.json)
   │  fetch_calendars.py  (requests, timeout 30s)  ← se corre por cron/manual
   ▼
cache/reservations_cache.json   (por depto: reservas con check_in/check_out, source_ok, error)
   │  app.py  lee el cache en cada request
   ▼
templates/index.html · detail.html   (Jinja2, autoescape ON)
   │
   ▼  navegador (dashboard)

Telegram:
  /telegram/connect  → crea link code (secrets.token_urlsafe(18)) → redirige a t.me/<bot>?start=<code>
  /telegram/webhook  → recibe /start <code> → registra chat_id en state/telegram_subscribers.json
  cleaning_alerts.py / telegram_daily_summary.py  → leen cache + subscribers → mandan mensajes
```

Estado en `state/`: `telegram_subscribers.json`, `telegram_link_codes.json`, `telegram_config.json`.

## 3. Archivos

| Archivo | Qué hace |
|---|---|
| `app.py` (595 líneas) | FastAPI. Endpoints, lógica de estado de reservas/limpiezas, config y webhook de Telegram. |
| `fetch_calendars.py` (138) | Descarga los iCal, parsea eventos a reservas, escribe `cache/reservations_cache.json`. |
| `cleaning_alerts.py` (562) | Alertas de limpieza a Telegram: planeación (9h), cambios/diffs (18h), resumen semanal. Estado propio para no repetir avisos. |
| `telegram_daily_summary.py` (187) | Resumen de limpiezas de mañana a los suscriptores. |
| `templates/index.html` (230) · `detail.html` (115) | Vistas. |
| `static/style.css` (627) | Estilos. |
| `Dockerfile` · `docker-compose.yml` | `python:3.13-slim`, single-stage. Compose monta `data/ cache/ state/` como volúmenes, expone 8090, **solo pasa `TZ` como env**. |

## 4. Endpoints

| Método | Ruta | Qué hace |
|---|---|---|
| GET | `/` | Dashboard principal (estado de todos los deptos, limpiezas de la semana, "atención hoy/mañana"). |
| GET | `/departamento/{apartment_key}` | Detalle de un depto con sus reservas enriquecidas. |
| GET | `/telegram/connect` | Genera un link code y redirige al bot. |
| POST | `/telegram/webhook` | Webhook de Telegram; procesa `/start <code>` y registra el chat. |

## 5. Problemas reales (verificados contra el código)

| # | Dónde | Problema | Severidad |
|---|---|---|---|
| 1 | `app.py` `load_json_file` | `except Exception: return default` — **traga TODOS los errores**. Un JSON corrupto en `cache/` o `state/` se vuelve "vacío" en silencio: el dashboard aparece sin reservas o pierde suscriptores sin avisar. | **Alta** |
| 2 | `app.py` `save_json_file` / `ensure_state_files` | Escritura **no atómica** (`open(w)` + `json.dump`). Si el proceso muere a media escritura (o dos workers uvicorn escriben a la vez), el archivo queda truncado → combina con #1 y se pierde estado. | **Alta** |
| 3 | `app.py` `telegram_webhook` | No revisa el flag `used` del link code: **un mismo código sirve para suscribir varios chats**. Necesitas el código (es un secreto de 144 bits, no adivinable), pero si se filtra la URL, se reusa sin límite. | Media |
| 4 | `app.py` `create_telegram_link_code` | Los link codes **nunca se borran ni caducan**. `telegram_link_codes.json` crece para siempre. | Media |
| 5 | `app.py` `send_telegram_message` | Usa `urllib.request` sin verificar el status de la respuesta. Si Telegram falla, el error se pierde. (`fetch_calendars.py` sí usa `requests` con timeout — inconsistente.) | Media |
| 6 | `docker-compose.yml` | **No pasa el token del bot ni los chat IDs** (`AIRBNB_BOT_TOKEN`, `AIRBNB_ALERT_CHAT_IDS`, `TELEGRAM_BOT_TOKEN`...). Si `cleaning_alerts.py` corre dentro del contenedor, no manda nada. Hoy funciona solo si esos scripts corren fuera con las env vars puestas a mano. | Media |
| 7 | `app.py` `telegram_webhook` | Sin validación de `X-Telegram-Bot-Api-Secret-Token`. El endpoint es público (vía cloudflared / `*.satanzote.me`). Mitigado por #3 (hace falta un código válido), pero deberías poner el secret token igual. | Media |
| 8 | `Dockerfile` | Single-stage, sin usuario no-root, sin healthcheck. | Baja |
| 9 | `app.py` `locale.setlocale` en bucle con `pass` | Si ningún locale español está en la imagen slim, las fechas salen en inglés sin avisar. | Baja |

> **No verificado a fondo** (posibles, el modelo los marcó pero requieren leer la lógica de fechas con calma): cálculo de noches con `dtend` exclusivo en `fetch_calendars.py`; clasificación `warning` vs `danger` en `build_cleaning_week` cuando hay 2 limpiezas el mismo día; duplicados entre "atención hoy" y "atención mañana". Si vas a tocar esa parte, revísalos primero.

## 6. Mejoras priorizadas

| Prioridad | Mejora | Por qué | Esfuerzo |
|---|---|---|---|
| **Alta** | Escritura atómica de JSON: `tempfile` + `os.replace()` en `save_json_file` | Mata el riesgo #2. Una función, se usa en todos lados. | Bajo |
| **Alta** | `load_json_file`: distinguir "no existe" (ok, default) de "corrupto" (log + no sobrescribir) | Mata el silencio del #1. Deja de perder estado en silencio. | Bajo |
| **Alta** | `logging` en vez de `print`, con un handler a archivo | Ahora mismo no hay forma de saber por qué falló una alerta. | Bajo |
| Media | Link codes: marcar `used`, caducar a 24 h, limpiar los viejos al crear uno | Cierra #3 y #4. | Bajo |
| Media | `docker-compose.yml`: pasar el token y chat IDs por `env_file` (`.env` gitignored) | Arregla #6 y saca el secreto del código. | Bajo |
| Media | `send_telegram_message`: pasar a `requests` con timeout, revisar `resp.ok`, devolver bool | Consistencia con `fetch_calendars.py` y errores visibles. | Bajo |
| Media | Secret token en el webhook de Telegram | Defensa en profundidad para un endpoint público. | Bajo |
| Baja | Healthcheck en Dockerfile/compose + usuario no-root | Producción más sana. | Bajo |
| Baja | Tests de la lógica de fechas (`status_for_apartment`, `build_cleaning_week`, parseo iCal) | Es la parte con más riesgo de bug sutil y la que más duele si se rompe. | Medio |
| Baja | Considerar SQLite si el estado crece o hay más de un worker | Elimina de raíz #1/#2. Solo si el volumen lo justifica. | Medio |

## 7. Quick wins (<30 min cada uno)

1. **`save_json_file` atómico:**
   ```python
   import os, tempfile
   def save_json_file(path: Path, data):
       fd, tmp = tempfile.mkstemp(dir=path.parent, suffix=".tmp")
       with os.fdopen(fd, "w", encoding="utf-8") as f:
           json.dump(data, f, ensure_ascii=False, indent=2)
       os.replace(tmp, path)
   ```
2. **`load_json_file` que no traga corrupción:**
   ```python
   def load_json_file(path: Path, default):
       if not path.exists():
           return default
       try:
           return json.loads(path.read_text("utf-8"))
       except json.JSONDecodeError:
           print(f"[WARN] JSON corrupto: {path} — usando default, NO se sobrescribe")
           return default
   ```
3. **Link code de un solo uso + caducidad** en `telegram_webhook`: `if payload not in codes or codes[payload].get("used"): <rechazar>`; y en `create_telegram_link_code`, filtrar los de más de 24 h antes de guardar.
4. **`docker-compose.yml`** → agregar `env_file: .env` con `AIRBNB_BOT_TOKEN=...` y `AIRBNB_ALERT_CHAT_IDS=...`; añadir `.env` al `.gitignore` y `.dockerignore`.
5. **`send_telegram_message`** → `requests.post(url, data=..., timeout=15)` y `return r.ok`.
6. **Healthcheck** en compose: `healthcheck: {test: ["CMD","curl","-f","http://localhost:8090/"], interval: 60s}`.
