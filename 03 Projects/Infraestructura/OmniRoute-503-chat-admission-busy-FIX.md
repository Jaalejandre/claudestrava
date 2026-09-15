---
tipo: incidente-resuelto
titulo: "OmniRoute 503 chat_admission_busy - causa raiz y fix (admission capacity)"
fecha: 2026-09-14
servicio: omniroute.service (CT 109 claude-dev)
puerto: 20128
estado: RESUELTO
---

# OmniRoute :20128 — 503 `chat_admission_busy` resuelto

## Síntoma
Hermes recibía `HTTP 503` con `code=chat_admission_busy` ("Chat admission capacity is temporarily unavailable. Retry shortly") en ráfagas de requests a `http://localhost:20128/v1/chat/completions` (cron, delegaciones, tool loops simultáneos).

## CAUSA RAÍZ (evidencia)
El límite NO vive en `omniroute.config.yaml` ni en `storage.sqlite`. Vive en el código del paquete npm `omniroute` (`/usr/lib/node_modules/omniroute/dist/.build/next/server/chunks/src_shared_middleware_chatBodyAdmission_ts_13jn9ov._.js`), controlado por variables de entorno con **defaults duros**:

| Variable | Default | Rol |
|---|---|---|
| `OMNIROUTE_CHAT_MAX_HEAVY_IN_FLIGHT` | **1** | In-flight pesados máximos admitidos (limite de concurrencia dura) |
| `OMNIROUTE_CHAT_ADMISSION_QUEUE_MS` | **2000** | Máx. espera en cola antes de rechazar |
| `OMNIROUTE_CHAT_ADMISSION_MAX_QUEUED_BYTES` | 4194304 | Bytes máx. en cola |
| `OMNIROUTE_CHAT_LARGE_BODY_BYTES` | 262144 | Body ≥256KB se trata como "heavy" |
| `OMNIROUTE_CHAT_ADMISSION_HEAP_SHED_RATIO` | 0.75 | Shed por heap si ratio ≥75% |

**Pruebas reales** (pid 724, `environ` = sin overrides → todos defaults):
- `maxHeavyInFlight=1` ⇒ solo 1 request pesado en vuelo; los demás entran a cola y, si no hay slot en 2s, se rechazan con 503.
- Ráfaga de 3 requests con body ~300KB (>256KB = heavy) concurrentes ⇒ **los 3 → 503** `chat_admission_busy`, timeout de cola exacto ~2.006s.
- Heap a ~26% (1.1GB RSS / 4.2GB heap_size_limit) ⇒ **no** es shed por heap.

Los requests reales de Hermes (system prompt + tools + contexto) superan 256KB, por eso disparaban el 503 en ráfagas.

## CAMBIO APLICADO
Drop-in de systemd: `/etc/systemd/system/omniroute.service.d/override.conf` (antes: unset ⇒ defaults)
```ini
[Service]
Environment=OMNIROUTE_CHAT_MAX_HEAVY_IN_FLIGHT=8
Environment=OMNIROUTE_CHAT_ADMISSION_QUEUE_MS=15000
Environment=OMNIROUTE_CHAT_ADMISSION_MAX_QUEUED_BYTES=16777216
```
- `maxHeavyInFlight` **1 → 8** (absorbe ráfagas de hasta 8 requests pesados concurrentes; Hermes usa hasta 6 delegaciones)
- `ADMISSION_QUEUE_MS` **2000 → 15000** (más margen en cola antes de rechazar)
- `MAX_QUEUED_BYTES` **4MB → 16MB**

Aplicado con `systemctl daemon-reload && systemctl restart omniroute.service`. Confirmado en nuevo proceso (pid 62290) vía `/proc/62290/environ`.

## VERIFICACIÓN
- `systemctl is-active omniroute.service` → **active**
- `:20128/v1/models` → **200**
- Ráfaga 5 concurrentes ~300KB post-fix: **4×200, 1×000** (timeout del curl 60s por cola; **0 errores 503**). Pre-fix las mismas daban 503.

## Notas
- El 503 de Hermes venía del SIDE OmniRoute, no de Hermes: `~/.hermes/config.yaml` ya tenía `delegations_limit=6` y `max_concurrent_children=6`, pero eso no afectaba la admisión del gateway.
- Para robots/CLI pequeños el 503 era menos visible porque bodies <256KB no entran al admission scheduler si ya hay slot.
- 82 hits de `chat_admission_busy` en `app.log` son históricos (pre-fix).