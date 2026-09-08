# Fase 3 Task 1 — reinit guard + teardown en `fzas_lj_st_cuda.cu`

**Commit:** `6c45e64`. Único cambio de kernel de toda la Fase 3.

## Qué cambió

`fzas_lj_st_cuda.cu` (desplegado idéntico en `Programa_DM/` y `Programa_DM_cpp/src/kernels/`):

1. **`extern "C" void fzas_lj_st_free_cuda(void)`** nueva — libera los 4 buffers const persistentes (`d_iitipo/carga/sigma/eps_persist`) y resetea `g_const_init`/`g_const_maxnat`. Antes no existía: los buffers vivían hasta que el proceso terminaba.
2. **Guard de reinit:** al entrar a `fzas_lj_st_cuda`, si `g_const_init && maxnat != g_const_maxnat`, llama `fzas_lj_st_free_cuda()`. `g_const_maxnat` se seteaba en la primera llamada pero **nunca se leía** — este es el fix. Sin él, un driver C++ que corre varios sistemas en un proceso tendría buffers del tamaño incorrecto (OOB).

Cambio **puramente aditivo**: en una corrida de tamaño fijo el guard nunca se dispara y el teardown no lo llama el path Fortran.

## Validación (protocolo completo de cambio de kernel)

CT 901 verificado libre (`who`, `ps`, `nvidia-smi` 0%) antes de medir. Caso de prueba real (10 000 pasos) **3 veces** en copias aisladas.

| | Wall time | Potential | Kinetic | Total | ΔE |
|---|---|---|---|---|---|
| Referencia (`ca9ef61`) | 1:37.77 | −98.74 ± 0.21 | 10.00 ± 0.16 | **−89.05846 ± 0.01195** | 0.00013 ± 0.00009 |
| Run 1 | 1:37.19 | −98.72662 | 10.03816 | −89.05655 | 0.00012 |
| Run 2 | 1:37.41 | −98.72467 | 10.05195 | −89.05794 | 0.00012 |
| Run 3 | 1:37.43 | −98.79291 | 9.99819 | −89.05910 | 0.00014 |

- **Los 3 `Total` dentro de 1σ** de la referencia (Δ = +0.0019 / +0.0005 / −0.0006).
- **Sin regresión de tiempo** (1:37.2-1:37.4 vs 1:37.77 — de hecho apenas más rápido, dentro del ruido).
- **Cero crashes.**
- ΔE (conservación de energía extendida) intacto.

## Estado acumulado

Fortran: 3:00.14 (debug original) → 1:37.77 (`ca9ef61`, −45.7%). El Task 1 no cambia el rendimiento — es preparación para que el driver C++ de la Fase 3 pueda llamar el kernel de forma segura más de una vez por proceso.
