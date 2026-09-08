# Skill: Prototipo local (agente Ollama en el server)

Generar prototipos web simples usando un modelo local en el servidor, con Claude como orquestador/revisor. Barato, local, privado. Ahorra cuota de Claude en trabajo desechable.

## Cuándo usar

- El usuario pide un **prototipo simple**: landing page, app chica, demo CRUD, mockup, componente aislado, script de utilidad.
- La tarea NO necesita corrección sutil ni decisiones de arquitectura. Si sí → hazlo tú con Claude directo, no delegues.

## Infraestructura

| Pieza | Dónde |
|---|---|
| Modelo | **Ollama en CT 103** (`192.168.0.99:11434`), GPU RTX 5070 Ti. Modelos en `nvme-fast` (`/opt/ollama-models`). |
| Modelos disponibles | `qwen2.5-coder:14b` (por defecto, mejor para código), `gpt-oss:latest` (20B, razonamiento), `gemma3:latest` |
| Endpoint OpenAI-compat | `http://192.168.0.99:11434/v1/chat/completions` |
| También vía OmniRoute | `http://192.168.0.64:20128/v1` con modelo `ollama/qwen2.5-coder:14b` (key `sk-784af7b27f4f9ca0-3cf66f-a8d20cce`) |
| Workspace del código | **CT 109** `/project/prototipos/<nombre>/` |
| Notas / specs | `03 Projects/Prototipos/<nombre>/` en el vault |

> **opencode** está instalado en CT 109 pero **NO se usa** para esto: su loop agéntico es poco fiable con modelos locales de 14–20B (emite tool-calls como texto, se cuelga). El patrón fiable es orquestación directa (abajo).

## El patrón (Claude orquesta)

1. **Spec.** Claude escribe `03 Projects/Prototipos/<nombre>/(C) spec.md`: qué es, stack, archivos esperados, criterio de "funciona".
2. **Generar.** Claude llama al modelo directo (una llamada = todos los archivos) con este system prompt:
   > Eres un generador de código. Responde SOLO con los archivos pedidos, cada uno como:
   > `=== ruta/archivo.ext ===` en su línea, luego el contenido completo, luego `=== FIN ===`.
   > Sin explicaciones ni markdown extra.
   - `temperature: 0.3`, `stream: false`, timeout 120s. Payload como archivo `.json` + `curl -d @archivo` (evita el infierno de comillas por SSH).
3. **Escribir.** Claude parsea los bloques `=== ruta ===` … `=== FIN ===` y escribe los archivos en `/project/prototipos/<nombre>/` por SSH.
4. **Revisar.** Claude LEE cada archivo generado. Verifica sintaxis, que haga lo del spec, que no tenga placeholders (`/path/to/...`, `TODO`, `...`). **Nunca dar por bueno sin revisar** — el modelo local se equivoca en silencio.
5. **Probar.** Servir y hacer `curl` / revisar. Para servir sin colgar el SSH:
   ```bash
   ssh root@192.168.0.64 "systemd-run --unit=proto-<nombre> --working-directory=/project/prototipos/<nombre> python3 -m http.server <puerto> --bind 0.0.0.0"
   # parar: ssh root@192.168.0.64 "systemctl stop proto-<nombre>"
   ```
   Acceso LAN: `http://192.168.0.64:<puerto>`. Puertos sugeridos: 8850–8899.
6. **Iterar.** Para arreglos, mandar al modelo el archivo actual + la instrucción puntual, pedir el archivo completo de vuelta. No conversación larga: prompts cerrados.
7. **Log.** Breve entrada en `03 Projects/Prototipos/<nombre>/(C) log.md`: qué se pidió, qué modelo, qué falló, estado.

## Reglas

- **Antes de generar, verificar que la GPU esté libre de GromacsMexicano.** `qwen-coder` (9 GB) + un benchmark de Gromacs no caben juntos en 16 GB. Chequear: `ssh root@192.168.0.52 "nvidia-smi --query-gpu=memory.used --format=csv,noheader"` — si hay >6 GB en uso o CT 901 tiene un `dm_mx` corriendo, esperar o avisar al usuario.
- **Claude siempre revisa antes de entregar.** El punto ciego del usuario son los bucles de errores; código local sin revisar los dispara.
- **Solo prototipos.** Si crece a algo real → se promueve a proyecto propio con New Dev Project y pasa a Claude.
- Prototipos son **desechables**: `/project/prototipos/` no es sagrado. El vault solo guarda spec + log, no el código (a menos que el usuario lo pida).

## Modelo por rol

| Tarea | Modelo |
|---|---|
| HTML/CSS/JS, componentes, CRUD | `qwen2.5-coder:14b` |
| Lógica que necesita razonar un poco, algoritmos | `gpt-oss:latest` |
| Respuestas rápidas triviales | `gemma3:latest` |
