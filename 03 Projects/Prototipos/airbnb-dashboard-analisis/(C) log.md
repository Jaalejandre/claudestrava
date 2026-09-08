---
tipo: log
---

# Log — análisis airbnb-dashboard

## 2026-09-08

- **Pedido:** documentar el proyecto `airbnb-dashboard` (CT 112, `/opt/airbnb-dashboard`) con el modelo local y devolver info para mejorarlo.
- **Fuente:** 10 archivos, ~66 KB (`app.py`, `fetch_calendars.py`, `cleaning_alerts.py`, `telegram_daily_summary.py`, templates, css, Docker). Volcado a `/tmp/airbnb-src.txt` en CT 109.
- **Modelo:** `gpt-oss:latest` (20B) en Ollama CT 103. `qwen2.5-coder` es mejor escribiendo código; para análisis/razonamiento gana gpt-oss.
- **Corrida:** `/api/chat` con `num_ctx: 40960`, temperature 0.2. 68 s, prompt_eval 17 395 tokens, eval 6 868. GPU libre confirmada antes.
- **Tropiezo:** el endpoint `/v1/chat/completions` (OpenAI-compat) **ignora `options.num_ctx`** y truncó el contexto a ~2 k tokens → el modelo alucinó otro proyecto. Con `/api/chat` (nativo) sí respeta `num_ctx`. → anotado en el skill.
- **Tropiezo 2:** el `OLLAMA_MODELS` override no había tomado efecto (drop-in vacío por quoting en SSH); ollama seguía en `/root/.ollama`. Reparado: drop-in correcto, modelos consolidados en `/opt/ollama-models` (nvme-fast), `systemctl restart`. Los 3 modelos listan bien.
- **Revisión de Claude:** leí `app.py` (config, `load/save_json_file`, `telegram_webhook`, link codes) y el inicio de `fetch_calendars.py`. El análisis de gpt-oss es ~85% correcto. Corregí: la seguridad del webhook (los link codes SÍ son secretos no adivinables, no "cualquier atacante"), y marqué como "no verificado" los claims sobre lógica de fechas.
- **Entregable:** `(C) analisis y mejoras (revisado).md` (versión buena). `(C) analisis crudo (gpt-oss).md` (volcado original).
- **Estado:** cerrado. No se tocó código del proyecto.
