# (C) HANDOFF — retoma de sesión tras corte de tokens (2026-09-11)

> **Estado:** sesión de Claudian (Mac) cortada por límite de uso a las ~12:41. Reset anunciado por el sistema: **15:40 (America/Mexico_City)**. Fecha: 2026-09-11.

## Qué se estaba haciendo

Benchmark comparativo en CT 901: binario **baseline** `dm_mx_npt` vs **optimizado** `dm_mx_npt_opt`, caso `Prueba/` (H₂O SPC/E + NaCl, 2544 átomos, 10 000 pasos NPT, copiado a `/home/alejandre/GromacsMexicano/Bench_UAMI_baseline/`).

## Evidencia ya generada (antes del corte)

| Qué | Valor |
|---|---|
| Baseline (referencia) | 181.45s — `energy_baseline.dat` md5 `add05c038cfb436153b9260a8b600437` |
| Optimizado | **157.38s → −13.3%** |
| md5 energy.dat | **DIFIERE** entre baseline y opt |
| Pregunta abierta | ¿el cambio es pura plomería (física idéntica) o el código ya era no-determinista por `atomicAdd` de CUDA (orden de suma varía entre corridas)? |

**Siguiente paso que quedó pendiente (el experimento):** correr 2× idénticas la baseline y 2× la opt, comparar md5:
- Si la baseline difiere consigo misma → no-determinismo inherente → el md5 no es métrica válida; comparar energía por paso (protocolo del proyecto).
- Si la baseline es determinista consigo misma pero difiere de la opt → el cambio alteró algo sistemáticamente → investigar.

## Qué YA corrió automáticamente (sin LLM, lanzado ~13:05)

Script `04 System/(C) continuar-determinismo.sh` (CT 109, `nohup`):
- 2 corridas `dm_mx_npt` (base_run2, base_run3) + 2 corridas `dm_mx_npt_opt` (opt_run1, opt_run2).
- Artefactos en `Bench_UAMI_baseline/`: `run_<tag>.log`, `<tag>.time`, `energy_<tag>.dat`, `<tag>.md5`, `<tag>.head`.
- Resumen factual escrito en `(C) 2026-09-11 determinismo md5 - resultados brutos.md`.
- Avisos por Telegram de progreso (0/4 → 4/4).

**Resultado parcial (clave):** las 2 corridas baseline dan md5 DISTINTOS entre sí y vs la referencia (`07595ecd...` vs `4b96ddb3...` vs ref `add05c03...`) → **la baseline NO es determinista consigo misma** (atomicAdd, orden de suma variable). Eso anticipa que el md5 no es métrica válida: la validación va por comparación numérica por paso.

Script `04 System/(C) comparar-determinismo.sh` (en cadena, ~13:15): compara los 4 energy.dat por pares (campos bit-iguales vs distintos, max abs/rel delta por columna) → `(C) 2026-09-11 determinismo - comparación numérica por paso.md`.

## Pipeline de retoma automático (15:45, timer systemd `retoma-tokens.timer` en CT 109)

1. `02/retoma_tokens.sh` hace probe `claude -p "ok"` con reintentos cada 2 min (15:45→16:15) hasta que el límite se restablezca.
2. Al pasar el probe → análisis autónomo headless: `claude -p` (máx 30 turns, allowedTools Read/Grep/Glob/Write/Bash) lee el handoff + resultados brutos + comparación numérica y escribe **SOLO** `(C) 2026-09-11 determinismo - CONCLUSIÓN (borrador autónomo).md` — marcado BORRADOR PRELIMINAR NO VALIDADO, prohibido tocar otro archivo.
3. Telegram al terminar (rc + ruta) o aviso de fallo si no pudo.

> ⚠️ El análisis autónomo consume un trozo del presupuesto recién restablecido (sonnet, ~30 turns). Si José llega manual antes de que termine, puede matar el proceso: en CT 109, `pct exec 109` no aplica — directamente `kill $(pgrep -f "claude -p")` y retomar manual.

## Trabajo pendiente para la sesión de retoma (15:40+)

1. Leer `(C) 2026-09-11 determinismo md5 - resultados brutos.md` **y** este handoff.
2. Interpretar los md5 (determinismo intra-baseline, intra-opt, inter).
3. Si la física no se puede validar bit a bit → comparar `energy.dat` por paso (columna a columna) entre baseline y opt; si difieren dentro del error de máquina/no-determinismo, confirmar física con promedios (T, P, ΔE) como en la nota del benchmark del 11-09.
4. Documentar conclusión en `03 Benchmarks/` con prefijo `(C)`.
5. Los archivos del dir son de `root` (pct exec) — si hay problemas de permisos usar `chown alejandre` o seguir con root, consistente con la sesión previa.

## Pipelines verificados del entorno (no re-investigar)

- CT 901 libre antes de medir: `ssh root@192.168.0.52 "pct exec 901 -- bash -c 'ps aux | grep -E \"dm_mx_npt|gmx_mexicano\" | grep -v grep'"`.
- Telegram: `ssh root@192.168.0.52 "pct exec 901 -- su - alejandre -c './notify_telegram.sh \"msg\"'"`.
- Dashboard vivo: `http://192.168.0.64:8851`.