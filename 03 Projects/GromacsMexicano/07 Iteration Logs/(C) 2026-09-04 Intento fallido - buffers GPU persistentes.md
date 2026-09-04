# 2026-09-04 — Intento fallido: buffers GPU persistentes (cambio #2)

## Qué se intentó

1. **Agente en background** (subagent, ~30 min, 111 llamadas de herramienta): tarea de aplicar buffers GPU persistentes en `fzas_lj_st_cuda.cu` y kernels hermanos. **No entregó nada** — cero commits, corrió pruebas con parámetros incorrectos (2 segundos, 190 000 pasos en vez de 10 000), y dejó un archivo de otro proyecto (`IPA_2_gaff2_resp.itp`) sin relación. Sí dejó, sin commitear, un diseño parcial razonable (pasar una bandera `update_list` por la cadena de llamadas Fortran para saltar la resubida de la lista de vecinos cuando no cambió) pero nunca tocó el `.cu` ni lo validó. Se descartó.

2. **Intento manual** (yo, directo): parcheé `fzas_lj_st_cuda.cu` para mover los `cudaMalloc`/`cudaFree` a una inicialización única (patrón `static bool initialized`), dejando todo lo demás igual (mismo algoritmo, misma subida/bajada de datos cada llamada). Compiló limpio. Primera corrida completa (10 000 pasos): **exitosa**, física dentro de 1σ, pero **sin mejora de tiempo** (2:18.08 vs. 2:10.10 del release — empate o ligeramente peor). Segunda corrida (misma binario, inmediatamente después de otra corrida): **segfault en la primera llamada** (`SIGSEGV` dentro de `fzas_lj_st_cuda`, backtrace confirma el frame).

## Por qué se revirtió

Un kernel que crashea de forma no determinista (funcionó una vez, crasheó la siguiente con el mismo binario) es peor que uno lento y correcto. No se commiteó nada. `fzas_lj_st_cuda.cu` está de vuelta exactamente en el estado del commit `c698cc7` (release -O3, el último cambio validado).

## Lectura honesta

- El malloc/free por paso **puede no ser la causa dominante** del tiempo total para este kernel específico — la primera corrida (correcta) no mostró ganancia medible, lo cual contradice la hipótesis del análisis original (§5A). Puede que:
  - El costo real esté en otro lado (Ewald/`KWALD`, lista de vecinos, o memcpy en sí — no el malloc/free).
  - `fzas_lj_st` se llama solo 2×/paso externo (`nts1=10`, `nmts=20`) — menos frecuente de lo asumido.
- El crash no determinista sugiere un bug real en el manejo de buffers persistentes (posible: alineación/tamaño, o una condición de carrera con el contexto CUDA entre procesos consecutivos) que **no se investigó a fondo** — se revirtió por seguridad en vez de perseguir la causa raíz bajo presión de tiempo.

## Recomendación para la siguiente iteración

**No seguir adivinando.** El plan original (`01 Analisis` §2, paso "Análisis") ya decía: perfilar con `nsys`/`ncu` antes de optimizar a ciegas — ese paso se saltó. Antes de tocar más código:

1. Perfilar la corrida de release (`nsys profile` o `ncu`) para ver de verdad dónde se va el tiempo: ¿Ewald? ¿lista de vecinos? ¿malloc/free? ¿transferencias? — con datos, no con hipótesis.
2. Si se retoma el cambio de buffers persistentes, agregar chequeo de errores CUDA (`cudaGetLastError()` después de cada llamada) para que un fallo se vea como mensaje claro, no como segfault silencioso.
3. Correr cada variante **mínimo 3 veces** antes de concluir que hay/no hay ganancia — una sola corrida no es suficiente dado que ya se vio no-determinismo.
