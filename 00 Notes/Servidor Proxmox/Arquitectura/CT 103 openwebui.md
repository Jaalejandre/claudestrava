---
contenedor: 103
nombre: openwebui
ip: 192.168.0.99
so: Debian 13 (trixie)
servicios: Ollama + Open WebUI
puertos: 8080, 11434
proyectos: LLM local (GPU)
gpu: RTX 5070 Ti (passthrough)
actualizado: 2026-09-08
---

# CT 103 — openwebui

**LLM local con GPU** — Ollama + Open WebUI.

## Qué corre
| Servicio | Puerto | Nota |
|---|---|---|
| **Ollama** | :11434 | carga modelos bajo demanda |
| **Open WebUI** | :8080 | frontend chat |

## Modelos
- `qwen2.5-coder:14b`, `gpt-oss:latest`, `gemma3`
- Modelos movidos a `nvme-fast` (`/opt/ollama-models`, `OLLAMA_MODELS` override) el 2026-09-08 — disco raíz bajó de 97% a 63%.

## Conexiones
- **GPU**: passthrough RTX 5070 Ti (compartida con [[CT 109 claude-dev]] y [[CT 901 ubuntu]])
- Usado por el skill `prototipo-local` (harness en CT 109)
- ⚠️ Existe un `open-webui` duplicado en [[CT 111 apps-prod]] (Docker) — redundancia a eliminar

## Notas
- ⚠️ Disco al 93% antes del movimiento; vigilar crecimiento de modelos en `nvme-fast`.