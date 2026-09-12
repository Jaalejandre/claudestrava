# Brief de programación — Sonnet headless (GromacsMexicano, 2026-09-11)

Eres el **programador** del proyecto GromacsMexicano (rol: implementar, no analizar). Corres en CT 901 como `alejandre`. Fecha: 2026-09-11.

## Contexto (resumen ejecutivo)

El código UAMI (`/home/alejandre/UAMI_Source/`, binario `dm_mx_npt`) **no es determinista entre corridas**: dos corridas idénticas dan `energy.dat` con md5 distintos, porque las **condiciones iniciales son aleatorias** (posiciones/caja y/o velocidades se generan con semilla del reloj). Esto se descubrió hoy: 3 corridas baseline → 3 md5 distintos (`07595ecd…`, `4b96ddb3…`, `add05c03…`), y la caja inicial difiere entre corridas (`lx=2.96644` vs `2.95758` — ver `energy.dat` paso 0).

Ese no-determinismo impide validar **bit a bit** un cambio de plomería que ya dio **−13.5% de speedup** (181.9s → 157.4s, física estadísticamente equivalente).

## Tarea

**Hacer la semilla del generador de condiciones iniciales CONFIGURABLE** (por defecto sigue aleatoria):

1. **Localizar** en `/home/alejandre/UAMI_Source/` cómo se generan las condiciones iniciales (posiciones y/o velocidades): buscar `random`, `rand`, `seed`, `srand`, `gen_seed`, `reloj`, `clock`, `system_clock`, `date_and_time`, números del `file.mdp`, etc. Revisar `file.mdp` del caso de prueba (¿ya hay `gen_seed`? ¿se lee?).
2. **Implementar**: una semilla fija configurable respetando el estilo del código:
   - Si `file.mdp` ya tiene (o el parser acepta) un parámetro tipo `gen_seed`, usarlo.
   - Si la semilla sale del reloj, cambiar a: `seed = constante` si está definida, si no la del reloj (comportamiento actual). Documenta cómo activarla.
   - El comportamiento **por defecto no cambia**: sin configuración → aleatorio como ahora.
3. Compilar con el flujo de build de UAMI_Source (`compilar_cuda.sh` o Makefile), **flags de producción** `-O3 -march=native` y `-arch=sm_120` en `nvcc` (¡crítico! la GPU es Blackwell `sm_120`; con `sm_86` JIT crashea en sistemas grandes — bug conocido del 11-09).

## Criterios de éxito (verificar TODOS)

1. Compila sin errores.
2. Con semilla fija: **2 corridas → `energy.dat` con md5 IDÉNTICOS**. Cero NaN/Inf (verificar `energy.dat` con el comando de abajo).
3. Sin semilla fija (default): 2 corridas → md5 distintos (sigue siendo aleatorio).
4. `cudaGetLastError()` sin errores (el binario ya lo checa o verifica exit code 0).
5. NO tocas el original de los científicos (`/home/alejandre/Programa_DM/`) ni el rewrite C++ (`/home/alejandre/GromacsMexicano/Programa_DM_cpp/`). Trabaja en `/home/alejandre/UAMI_Source/` (copia de trabajo, ya tiene git o haz `git init` antes de empezar si no lo tiene).

## Protocolo obligatorio (del proyecto)

- Antes de cada corrida: verificar CT 901 libre → `ps aux | grep -E "dm_mx_npt|gmx_mexicano" | grep -v grep` y `nvidia-smi` (GPU sin uso).
- Correr desde `/home/alejandre/GromacsMexicano/Bench_UAMI_baseline/` con `time ./<binario>` (el caso de prueba oficial, 2544 átomos, 10 000 pasos, NPT).
- Cada corrida ~2.5-3 min. Mínimo 2 corridas por configuración.
- Si una corrida supera 5 min o crashea → abortar y reportar.

Verificación de energía (sin NaN/Inf):
```
grep -v "^#" energy.dat | awk '$1 ~ /^[-+0-9]/ {if ($0 ~ /nan|inf/i) bad++} END {print "NaN/Inf:", bad+0}'
```

## Reporte

Al terminar escribe `/tmp/resumen_programador.md` con:
- Archivos tocados (rutas).
- Cómo queda configurada la semilla (dónde y cómo se fija).
- md5 de las 2 corridas con semilla fija (deben ser IGUALES) y de 2 corridas sin semilla (deben ser DISTINTOS).
- Tiempos de cada corrida.
- Cualquier cosa rara o decisión que tomaste.

**Último paso:** ejecuta en bash este comando exacto para avisar por Telegram (reemplaza `X/Y` por tu resumen de 2 líneas):
```
ssh root@192.168.0.52 "pct exec 901 -- su - alejandre -c './notify_telegram.sh \"X\"'"
```
(El token y chat ID ya están dentro de `notify_telegram.sh`; no los imprimas ni los guardes en archivos.)

## Reglas férreas

- Solo editar archivos de `/home/alejandre/UAMI_Source/` (y el binario resultante para probar). Nada más en ningún CT.
- No borrar archivos. No tocar el Fortran de `Programa_DM/` ni el C++ de `Programa_DM_cpp/`.
- No instalar paquetes ni modificar config del sistema.
- Si algo no está claro o el cambio se vuelve grande: reportar y detenerte con lo hecho.