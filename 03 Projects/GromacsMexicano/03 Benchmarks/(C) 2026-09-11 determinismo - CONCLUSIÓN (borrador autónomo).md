# (C) 2026-09-11 determinismo — CONCLUSIÓN (análisis de SatanZote AI)

> **Estado:** análisis completado por SatanZote AI (sesión Copilot del 11-09 ~13:15), ANTES del reset de tokens. No es un borrador autónomo: es el análisis de la sesión principal con toda la evidencia. **Pendiente de validación por José.**

## Pregunta original

El md5 de `energy.dat` difería entre baseline y opt (−13.3%). ¿Era el cambio de plomería alterando la física, o el código ya era no-determinista?

## Experimentos corridos (automáticos, sin LLM — scripts `04 System/`)

| corrida | binario | time (s) | etot media (kJ/mol) | T media (K) | P media (bar) | ΔE |
|---|---|---|---|---|---|---|
| base1 (previo) | `dm_mx_npt` | ~182 | — | — | — | 0.00144 |
| base2 (previo) | `dm_mx_npt` | ~182 | — | — | — | 0.00024 |
| base3 (previo, = ref) | `dm_mx_npt` | 181.45 | −89.043 | 298.555 | 6.20 | 0.00030 |
| base_run2 | `dm_mx_npt` | 181.90 | −89.913 | 298.427 | 2.05 | 0.00036 |
| base_run3 | `dm_mx_npt` | 181.95 | −89.143 | 297.867 | −1.84 | 0.00062 |
| opt_run1 | `dm_mx_npt_opt` | 157.28 | −89.809 | 298.541 | 9.39 | 0.00037 |
| opt_run2 | `dm_mx_npt_opt` | 157.52 | −89.289 | 298.322 | 0.68 | 0.00043 |

Speedup reproducido: **181.9s → 157.4s = −13.5%** (3 corridas baseline 181.45–181.95, 2 opt 157.28–157.52; cero solapamiento entre familias).

## Hallazgos

### 1. El código NO es determinista entre corridas — pero NO por `atomicAdd`

Dos corridas idénticas del mismo binario (`base_run2` vs `base_run3`) difieren en promedios estadísticos completos: T en 0.56 K, etot en 0.77 kJ/mol (0.9%), P en 3.9 bar (hasta cambiar de signo). Eso es **muchísimo más** que el ruido de redondeo de una suma atómica (~1e-15): es variación estadística de ensamble.

**Causa raíz: condiciones iniciales aleatorias.** El paso 0 (`energy.dat`) muestra cajas iniciales distintas entre corridas: `lx = 2.966444…` (base_run2) vs `2.957583…` (opt_run1). Cada corrida arranca con posiciones/velocidades distintas → trayectorias independientes → promedios que fluctúan con magnitud estadística normal (en NPT de 2544 átomos, la presión converge lentísimo: P media ±4 bar entre corridas de 2 ps es esperado).

### 2. El md5 era doblemente inválido

- (a) El código no es determinista → el md5 del archivo de salida **no se repite ni entre corridas idénticas del mismo binario** (3 corridas baseline → 3 md5 distintos: `07595ecd`, `4b96ddb3`, `add05c03`).
- (b) Por tanto, la comparación `md5 baseline vs md5 opt` no tiene poder de decisión: siempre diferirá.

### 3. La opt difiere de la baseline EN LA MISMA magnitud que la baseline difiere consigo misma

| métrica | dispersión baseline (σ, n=3) | Δ baseline→opt | ¿dentro de σ? |
|---|---|---|---|
| T (K) | 0.37 | 0.15 | ✅ (~0.4σ) |
| etot (kJ/mol) | 0.49 | 0.18 | ✅ (~0.4σ) |
| P (bar) | 4.05 | 2.90 | ✅ (~0.7σ) |
| ΔE (deriva) | 0.0002–0.0014 | 0.00037–0.00043 | ✅ dentro del rango |

**No hay evidencia de que el cambio de plomería haya alterado la física.** La opt produce promedios indistinguibles de la baseline dentro de la fluctuación corrida-a-corrida del propio código. La comparación numérica por paso (`(C) determinismo - comparación numérica por paso.md`) confirma que las 23/28 columnas que varían varían igual en pares intra-baseline e inter, y las únicas bit-idénticas son `step`, `time_ps` y los términos nulos del sistema (diederos, 1-5).

## Veredicto preliminar

- **Speedup −13.5% real y reproducible** (sin solapamiento de tiempos, física estadísticamente equivalente).
- Validación formal de "la física no cambió" **no puede ser bit a bit** (seeds aleatorios): hay que hacerla con el protocolo estadístico del proyecto (medias ± σ). Con n=3 vs n=2, todo dentro de 1σ.

## Qué falta para cerrar / dejaría propuesto

1. **(Recomendado)** Correr `opt_run3` para igualar n=3 y comparar medias formales T/P/etot (z-test rápido). Es 1 corrida de ~160s, mecánica.
2. **Opcional y de fondo:** buscar en el código la semilla del generador aleatorio de velocidades/posiciones iniciales. Si existe flag para fijarla, el benchmark "plomería pura" podría validarse bit a bit (solo ahí el md5 tendría sentido). Pregunta para los científicos/dashboard si la semilla es fija o del reloj.
3. El dashboard (`.64:8851`) puede actualizarse con la fila opt si José la valida: **181.9s → 157.4s (−13.5%)** con física equivalente.

## Evidencia cruda

- `(C) 2026-09-11 determinismo md5 - resultados brutos.md` — 4 md5 + tiempos.
- `(C) 2026-09-11 determinismo - comparación numérica por paso.md` — cabeceras + tabla por pares.
- Artefactos en CT 901 `Bench_UAMI_baseline/`: `run_*.log`, `*.time`, `energy_*.dat`, `*.md5`, `*.head`.
- `04 System/(C) continuar-determinismo.sh` y `(C) comparar-determinismo.sh` (reproducibles).