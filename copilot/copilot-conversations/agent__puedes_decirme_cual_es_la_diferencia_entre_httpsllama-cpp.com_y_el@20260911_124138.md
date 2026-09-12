---
epoch: 1789152098774
mode: agent
backendId: opencode
sessionId: "ses_f6e39d01cffevt02NKbPBmE565"
usage: '{"usedTokens":24640,"contextWindow":200000,"updatedAt":1789152160888}'
tags:
  - copilot-conversation
---

**user**: puedes decirme cual es la diferencia entre https://llama-cpp.com/ y el que tenemos isntaldo??
[Timestamp: 2026/09/11 12:41:38]

**ai**: Déjame confirmar qué es exactamente "lo que tenemos instalado" — buscaré referencias en el vault y en el servidor.En el vault lo que tenemos para modelos locales es **Ollama en CT 103**. Déjame verificar la relación exacta entre Ollama y llama.cpp (y de paso confirmar qué hay instalado en el server).Buena pregunta, porque la respuesta corta es: **no son cosas comparables — el que tenemos usa a llama.cpp por dentro.**

## Lo que encontré en nuestro server

- En **CT 103** tenemos **Ollama v0.33.2** instalado (`/bin/ollama`, puerto `:11434`) — el que usa el harness de prototipos con `qwen2.5-coder:14b` y `gpt-oss`.
- No hay binarios de llama.cpp directos instalados en ningún CT.
- En **CT 109** tampoco (ahí solo corre OmniRoute, que es el gateway de LLM, otra cosa).

## Qué es cada cosa

**llama-cpp.com** — es simplemente un **sitio web informativo NO oficial** (fan-built, así lo declara el propio site) sobre el proyecto llama.cpp. El proyecto real vive en GitHub (`ggml-org/llama.cpp`). O sea: no es un software que se instale, es la documentación/landing de un proyecto.

**llama.cpp** — el motor de inferencia en C/C++ creado por Georgi Gerganov. Hace el cálculo pesado: carga un archivo GGUF, optimiza para tu CPU/GPU (CUDA, Metal, ROCm), y convierte prompts en tokens. Es una biblioteca + binarios.

**Ollama (lo nuestro)** — es una **capa de gestión escrita en Go que embrulja a llama.cpp**. Ollama no es un motor alternativo: usa llama.cpp como su backend de inferencia (mantiene un submódulo del repo y lo integra vía PR — la última fusión fue el 10 de agosto de 2026). Sobre el motor añade:

- Gestor de modelos (`ollama pull qwen2.5-coder` descarga el GGUF + plantilla + parámetros por ti)
- Daemon en segundo plano + API compatible con OpenAI en `:11434`
- Decisiones automáticas de cuantización, contexto, offload a GPU

## La analogía que lo resume

| | llama.cpp | Ollama (CT 103) |
| --- | --- | --- |
| Qué es | El motor (C/C++) | El vehículo completo (Go + llama.cpp adentro) |
| Modelos | Tú descargas y colocas el GGUF manualmente | `ollama pull` y listo |
| Configuración | Docenas de flags (`-c`, hilos, offload, etc.) | Defaults razonables + Modelfiles |
| API | `llama-server` manual | Servicio siempre activo en `:11434` |

En la práctica, el mismo modelo GGUF corre con rendimiento casi idéntico con ambos porque el motor es el mismo. La diferencia real es de control: llama.cpp puro te deja ajustar cada parámetro (y compilar para tu hardware exacto), Ollama te quita esa fricción a cambio de esconder las perillas.

**Para lo que hacemos en el vault** (prototipos con harness vía Ollama): quedarnos con Ollama es lo correcto. Solo tendría sentido saltar a llama.cpp directo si algún día necesitáramos algo que Ollama no expone (ej. `/slots`, `/metrics` para monitoreo fino, o un formato de cuantización nuevo antes de que llegue a Ollama).
[Timestamp: 2026/09/11 12:41:38]