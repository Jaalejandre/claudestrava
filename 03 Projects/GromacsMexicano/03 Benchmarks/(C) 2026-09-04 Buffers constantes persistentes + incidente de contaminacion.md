# Benchmark 2026-09-04 — Buffers constantes persistentes (y un incidente serio de contaminación)

**Cambio:** #4 del plan re-priorizado — solo `iitipo`, `carga`, `sigma`, `eps` (arreglos que nunca cambian durante la corrida) se suben a GPU una sola vez, en vez de en cada llamada. `rx/ry/rz/fx/fy/fz` y la lista de vecinos siguen exactamente igual que antes (malloc/free por llamada) — alcance mínimo a propósito, evitando la superficie de riesgo del intento fallido anterior (nada dimensionado por `npares`/`maxlist`).

## ⚠️ Incidente: contaminación de benchmarks por procesos concurrentes

Antes de llegar al número final, este cambio pasó por un episodio serio que vale la pena documentar como lección de proceso:

1. **Primera ronda de pruebas (3 corridas):** el binario compiló y corrió sin crash, pero la **energía total divergió catastróficamente** entre corridas (−89.058, −89.474, −88.813 — decenas de σ fuera de la referencia ±0.012). Parecía un bug grave en el cambio.
2. **Investigación:** `git status` reveló que `Programa_DM/kwald_cuda.cu` estaba modificado (88 líneas) **sin que yo lo hubiera tocado**. Un proceso del agente en background que se creía "muerto" (`TaskStop` solo mata la orquestación local, no procesos remotos ya desprendidos vía SSH) seguía vivo en CT 901: un proceso `dm_mx_npt` corriendo directo (PID 116686), una sesión SSH interactiva propia, y dos bucles `until pgrep...` huérfanos desde las 10:42/10:48 — todo editando y ejecutando en el **mismo directorio de trabajo compartido** (`~/GromacsMexicano/`) mientras yo probaba mi cambio, y compitiendo por la misma GPU física.
3. **Limpieza:** se mataron todos los procesos huérfanos, se revirtieron `kwald_cuda.cu` y `Prueba/file.gro` a su estado limpio commiteado, se repitió la prueba.
4. **Segunda ronda (ya sin el agente):** dio 1:47.21–1:47.71 — parecía una ganancia enorme (~15%). Pero antes de commitear, una corrida de verificación adicional dio 2:04.94 — inconsistente con las 3 anteriores.
5. **Causa:** una sesión SSH del propio usuario (José, `192.168.0.12`, terminal directa a CT 901) seguía activa y probablemente interfería con la medición (contención de CPU/GPU, aunque no ejecutara la simulación). José confirmó que era su sesión y pidió desconectarla.
6. **Tercera ronda, entorno verificado 100% limpio** (sin sesiones humanas, sin agentes, GPU en 0% util antes de arrancar): **2:04.87 / 2:04.71 / 2:04.78** — muy consistente. Este es el número real.

**Lección para el proyecto:** antes de aceptar cualquier benchmark, verificar `w`, `ps aux`, y `nvidia-smi --query-compute-apps` para confirmar que **nada más** está usando CPU/GPU en CT 901 — el contenedor se comparte con GromacsMexicano (código) y potencialmente con sesiones interactivas del usuario o agentes en background que no siempre terminan limpio.

## Tiempo de pared (número final, válido)

| Build | Wall time | Δ vs. anterior |
|---|---|---|
| Reducción por bloque (`978d385`, referencia) | 2:06.21 | — |
| + Buffers constantes, entorno limpio verificado | 2:04.79 (promedio 2:04.87/2:04.71/2:04.78) | **−1.4s (≈1.1%)** |

Modesto pero real — mucho menor que el (falso) 15% visto con el sistema contaminado.

## Física (3 corridas, entorno limpio)

| Cantidad | Referencia | Corrida 1 | Corrida 2 | Corrida 3 |
|---|---|---|---|---|
| Total | −89.058 ± 0.012 | −89.060 | −89.058 | −89.059 |
| ΔE | 0.00013 ± 0.00009 | 0.00013 | 0.00012 | 0.00012 |

Todas dentro de 1σ, muy consistentes entre sí.

## Acumulado total hasta ahora

3:00.14 (original) → 2:10.10 (`-O3`) → 2:06.21 (+ reducción por bloque) → **2:04.79 (+ buffers constantes) = −31.1% wall time acumulado**, física validada en cada paso.
