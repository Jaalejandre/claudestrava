# 1. Qué hace y cómo (visión general)

El proyecto **airbnb‑dashboard** es una aplicación web que muestra el estado de las reservas de varios alojamientos de Airbnb y envía alertas de limpieza a través de Telegram.  
- **Backend**: FastAPI + uvicorn, sin base de datos (JSON en disco).  
- **Frontend**: Jinja2 templates + CSS.  
- **Datos**: Se descargan calendarios iCal (configurados en `data/calendar_sources.json`), se guardan en `cache/reservations_cache.json`.  
- **Alertas**:  
  - `cleaning_alerts.py` envía planeaciones diarias y diffs de limpieza.  
  - `telegram_daily_summary.py` envía un resumen de limpieza de mañana a suscriptores.  
  - Los usuarios se suscriben a través de `/telegram/connect` y el webhook `/telegram/webhook`.  

El flujo típico es:  
1. `fetch_calendars.py` se ejecuta (cron / manual) → actualiza el cache.  
2. Los endpoints `/` y `/departamento/{key}` leen el cache y renderizan la vista.  
3. `cleaning_alerts.py` se ejecuta a las 9 h y 18 h → envía mensajes de planeación y cambios.  
4. `telegram_daily_summary.py` se ejecuta manualmente → envía el resumen de mañana.  

---

# 2. Arquitectura y flujo de datos

```
┌──────────────────────┐
│  iCal Sources (URL)  │
└───────┬──────────────┘
        │ fetch_calendars.py
        ▼
┌──────────────────────┐
│  cache/reservations_cache.json  │
└───────┬──────────────┘
        │ app.py / endpoints
        ▼
┌──────────────────────┐
│  Templates (index.html, detail.html)  │
└───────┬──────────────┘
        │
        ▼
┌──────────────────────┐
│  Browser (Dashboard) │
└───────┬──────────────┘
        │
        ▼
┌──────────────────────┐
│  Telegram Bot (bot_token) │
└───────┬──────────────┘
        │ telegram_connect → /telegram/connect
        │ telegram_webhook → /telegram/webhook
        ▼
┌──────────────────────┐
│  state/telegram_subscribers.json │
└───────┬──────────────┘
        │
        ▼
┌──────────────────────┐
│  cleaning_alerts.py / telegram_daily_summary.py │
└───────┬──────────────┘
        │
        ▼
┌──────────────────────┐
│  Telegram Chats (chat_id) │
└──────────────────────┘
```

- **iCal → cache**: `fetch_calendars.py` descarga, parsea y escribe el cache.  
- **Cache → dashboard**: `app.py` lee el cache y genera las vistas.  
- **Telegram**:  
  - `/telegram/connect` genera un código de enlace y redirige al bot.  
  - `/telegram/webhook` recibe `/start <code>` y registra el chat.  
  - `cleaning_alerts.py` y `telegram_daily_summary.py` leen el cache y envían mensajes a los chats registrados.  

---

# 3. Cada archivo (1‑2 líneas)

| Archivo | Descripción breve |
|---------|-------------------|
| `requirements.txt` | Dependencias de Python. |
| `Dockerfile` | Imagen base, instalación de dependencias, copia de código y creación de directorios. |
| `docker-compose.yml` | Servicio `airbnb-dashboard`, volúmenes y puertos. |
| `app.py` | FastAPI app, endpoints `/`, `/departamento/{key}`, `/telegram/connect`, `/telegram/webhook`. |
| `fetch_calendars.py` | Script que descarga iCal, parsea reservas y escribe `cache/reservations_cache.json`. |
| `cleaning_alerts.py` | Script de alertas: planeación, cambios y resumen semanal. |
| `telegram_daily_summary.py` | Script que envía el resumen de limpieza de mañana a suscriptores. |
| `templates/index.html` | Vista principal del dashboard. |
| `templates/detail.html` | Vista de detalle de un departamento. |
| `static/style.css` | Estilos CSS. |

---

# 4. Endpoints / rutas HTTP

| Método | Ruta | Qué hace |
|--------|------|----------|
| `GET` | `/` | Renderiza el dashboard principal con el estado de todas las reservas. |
| `GET` | `/departamento/{apartment_key}` | Renderiza la vista de detalle de un departamento. |
| `GET` | `/telegram/connect` | Genera un código de enlace y redirige al bot para suscribirse. |
| `POST` | `/telegram/webhook` | Webhook de Telegram que procesa `/start <code>` y registra el chat. |

---

# 5. Problemas y riesgos

| Archivo | Zona | Problema / Riesgo |
|---------|------|-------------------|
| `app.py` | `load_json_file` | Silencia cualquier excepción y devuelve `default`; errores de JSON se ocultan. |
| `app.py` | `save_json_file` | No hay manejo de errores; fallos de escritura no se reportan. |
| `app.py` | `send_telegram_message` | No verifica respuesta HTTP; fallos de Telegram no se manejan. |
| `app.py` | `telegram_webhook` | No valida la firma de Telegram; cualquier POST puede registrar chats. |
| `app.py` | `telegram_webhook` | No comprueba el flag `used` en `TELEGRAM_LINK_CODES_FILE`; el mismo código puede usarse varias veces. |
| `app.py` | `telegram_webhook` | No evita suscripciones duplicadas (mismo `chat_id`). |
| `app.py` | `ensure_state_files` | Crea archivos vacíos sin validación; si el proceso se interrumpe, archivos pueden quedar corruptos. |
| `fetch_calendars.py` | `build_cache` | Si una fuente falla, el script termina sin actualizar el cache; no hay reintentos. |
| `fetch_calendars.py` | `parse_calendar` | No maneja eventos con `dtend` exclusivo; puede contar noches incorrectamente. |
| `cleaning_alerts.py` | `load_state` | No captura errores de JSON; un archivo corrupto hace que el script falle. |
| `cleaning_alerts.py` | `send_telegram_message` | No maneja códigos de error de Telegram; puede lanzar excepciones no capturadas. |
| `cleaning_alerts.py` | `run_planning` / `run_change_check` | Si el cache cambia entre la lectura y la escritura del estado, se pueden perder notificaciones. |
| `cleaning_alerts.py` | `build_target_cleanings` | Si hay reservas con el mismo `check_out`, solo la primera se considera; puede perder alertas. |
| `telegram_daily_summary.py` | `send_telegram_message` | No verifica respuesta; errores silenciosos. |
| `telegram_daily_summary.py` | `load_json` | Silencia errores de JSON; datos corruptos se ignoran. |
| `templates/*.html` | N/A | No hay sanitización de datos; riesgo de XSS si los datos de reserva contienen HTML. |
| `Dockerfile` | N/A | Usa `python:3.13-slim`; no hay multi‑stage build, lo que aumenta el tamaño de la imagen. |
| `docker-compose.yml` | N/A | No define variables de entorno para secretos; se espera que el host las proporcione. |
| `app.py` | `BASE_DIR` | Asume que el script se ejecuta en `/app`; si se cambia la ruta, fallará. |
| `app.py` | `locale.setlocale` | Si el locale no está disponible en la imagen, fallará silenciosamente. |
| `app.py` | `parse_date` | Si el formato no es `YYYY‑MM‑DD`, lanza `ValueError`. |
| `app.py` | `human_time` | Usa `datetime.now()` sin zona; puede dar resultados incorrectos si el servidor cambia de zona. |
| `cleaning_alerts.py` | `TZ = ZoneInfo("America/Mexico_City")` | Si la zona no está instalada, lanzará excepción. |
| `cleaning_alerts.py` | `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_IDS` | Se leen de variables de entorno; si están mal configuradas, el script no envía nada. |
| `telegram_daily_summary.py` | `get_bot_token` | Lee token de archivo sin validación; si el archivo está vacío, los mensajes no se envían. |
| `app.py` | `telegram_enabled` | Se basa en la presencia de `bot_token` y `bot_username`; no verifica que el bot esté activo. |
| `app.py` | `create_telegram_link_code` | No elimina códigos expirados; el archivo puede crecer indefinidamente. |
| `app.py` | `load_cached_apartments` | Si el cache está corrupto, devuelve valores nulos que pueden romper la lógica de la vista. |
| `app.py` | `status_for_apartment` | Lógica compleja; posibles errores de cálculo de fechas (ej. `check_out` inclusive). |
| `app.py` | `build_cleaning_week` | Clasifica por número de limpiezas; si hay 2 limpiezas el mismo día, se marca como `warning` aunque puede ser `danger`. |
| `app.py` | `build_attention_today` / `build_attention_tomorrow` | No filtra duplicados; un mismo departamento puede aparecer en varias listas. |
| `app.py` | `enrich_reservations_for_detail` | Si la reserva está en el pasado, se omite; puede ocultar reservas que aún no se han completado. |
| `app.py` | `templates` | No escapa variables; riesgo XSS si los nombres de departamentos contienen HTML. |
| `static/style.css` | N/A | No hay minificación; aumenta el tamaño de la respuesta. |

---

# 6. Recomendaciones priorizadas

| Prioridad | Mejora | Por qué | Esfuerzo |
|-----------|--------|---------|----------|
| **Alta** | **Validar y sanitizar datos de entrada** (JSON, iCal, Telegram) | Evita corrupción de cache, XSS y errores silenciosos. | Medio |
| **Alta** | **Implementar autenticación y firma en el webhook** | Previene que cualquier atacante registre chats. | Medio |
| **Alta** | **Usar un sistema de bloqueo o escritura atómica con `tempfile` + `os.replace`** | Evita race conditions en archivos JSON cuando múltiples workers escriben. | Bajo |
| **Alta** | **Reemplazar `urllib.request` por `httpx` o `requests` con manejo de errores y logs** | Mejora la fiabilidad de los mensajes de Telegram y facilita debugging. | Bajo |
| **Media** | **Eliminar códigos expirados y limitar su vida útil** | Evita crecimiento indefinido del archivo de códigos. | Bajo |
| **Media** | **Añadir pruebas unitarias y de integración** | Garantiza que cambios futuros no rompan la lógica de reservas y alertas. | Alto |
| **Media** | **Separar la lógica de negocio en módulos y usar Pydantic** | Mejora la mantenibilidad y la validación de datos. | Medio |
| **Media** | **Migrar a un motor de base de datos ligero (SQLite)** | Evita problemas de concurrencia y corrupción de JSON. | Medio |
| **Baja** | **Minificar CSS y usar un CDN** | Reduce el tiempo de carga. | Bajo |
| **Baja** | **Añadir un health‑check y métricas Prometheus** | Facilita la monitorización en producción. | Bajo |
| **Baja** | **Usar multi‑stage Docker build** | Reduce el tamaño de la imagen. | Bajo |
| **Baja** | **Documentar variables de entorno y secretos** | Mejora la seguridad y la facilidad de despliegue. | Bajo |

---

# 7. Quick wins (<30 min)

1. **Añadir manejo de errores en `load_json_file` y `load_state`**  
   ```python
   def load_json_file(path: Path, default):
       try:
           if not path.exists():
               return default
           with open(path, "r", encoding="utf-8") as f:
               return json.load(f)
       except json.JSONDecodeError:
           logger.warning(f"JSON corrupto en {path}, usando valor por defecto")
           return default
       except Exception as e:
           logger.error(f"Error leyendo {path}: {e}")
           return default
   ```

2. **Validar el flag `used` en `telegram_webhook`**  
   ```python
   if payload not in codes or not codes[payload].get("used", False):
       # enviar mensaje de error
   ```

3. **Eliminar códigos expirados cada vez que se crea uno nuevo**  
   ```python
   def create_telegram_link_code() -> str:
       codes = load_json_file(TELEGRAM_LINK_CODES_FILE, {})
       # eliminar códigos > 24h
       now = datetime.now()
       codes = {k: v for k, v in codes.items()
                if not v["used"] and (now - datetime.fromisoformat(v["created_at"])).total_seconds() < 86400}
       ...
   ```

4. **Reemplazar `urllib.request` por `httpx` con timeout y manejo de errores**  
   ```python
   import httpx
   async def send_telegram_message(chat_id: str | int, text: str) -> bool:
       async with httpx.AsyncClient(timeout=15) as client:
           resp = await client.post(url, data=payload)
           return resp.status_code == 200
   ```

5. **Añadir encabezado `X-Forwarded-For` y `X-Real-IP` en el webhook**  
   (para registrar IPs y detectar abusos).

6. **Agregar `logging` en lugar de `print`**  
   ```python
   import logging
   logger = logging.getLogger("airbnb-dashboard")
   logger.setLevel(logging.INFO)
   ```

7. **Escapar variables en los templates**  
   Jinja2 ya escapa por defecto, pero asegurarse de que no se use `|safe` en ningún campo.

8. **Crear un script de limpieza de archivos de estado**  
   ```bash
   find /app/state -name '*.json' -mtime +7 -delete
   ```

Implementar estos cambios en menos de 30 min mejorará la robustez, la seguridad y la mantenibilidad sin requerir reescritura de la lógica principal.
