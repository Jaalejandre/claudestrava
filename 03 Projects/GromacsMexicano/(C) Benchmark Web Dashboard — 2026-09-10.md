# (C) Benchmark Web Dashboard — 2026-09-10

## Qué se construyó

Dashboard web interactivo en Flask para comparar los tres motores de GromacsMexicano en tiempo real.

- **URL**: `http://192.168.0.64:8851`
- **Código**: `/project/prototipos/gromacs-benchmark/app.py` (CT 109)
- **Motor de ejecución**: CT 901 (`192.168.0.230`) vía SSH

## Funcionalidades

- **7 casos de prueba** en dropdown dinámico (Jinja, no hardcodeado):
  - Prueba — H₂O + NaCl · 298K · 10k pasos · NPT
  - Prueba_5K — H₂O + NaCl · 298K · 5k pasos · NPT
  - Prueba_350K — H₂O + NaCl · 350K · 10k pasos · NPT
  - Demo_AguaPura — 800 H₂O sin sal
  - Demo_NaClCaliente — NaCl caliente
  - Prueba_NVE — sistema aislado (solo C++)
  - fixtures — C++ tests
- **3 modelos**: Fortran original, Fortran optimizado (-O3), C++ (CUDA)
- **Semáforo CT 901**: verifica usuarios activos, procesos dm/gmx, GPU — una sola conexión SSH (~0.3s)
- **Gráficas post-run**: Energía Total, Pot., Cin., Temperatura, Presión (leyendo `energy.dat` con índices de columna correctos)
- **Visualizador 3D**: moléculas desde `movie.gro` (si existe); falla graciosamente si no
- **Sección NVE estática**: resultados reales medidos
  - GROMACS: 393.1s, drift 0.04778%
  - C++: 127.3s, drift 0.000726% → **66× mejor conservación de energía**
- **Responsive**: colapsa a 1 columna en < 600px

## Resultados clave (medidos 2026-09-10)

| Motor | Tiempo (Prueba 10k) | Drift NVE |
|---|---|---|
| Fortran -O0 | ~151s | N/A |
| Fortran -O3 | ~98s | N/A |
| C++ (CUDA) | ~127s | 0.000726% |
| GROMACS 2025.3 | ~391s | 0.04778% |

- Optimización GPU cerrada en **−45.7%** wall time (vs Fortran -O0)
- C++ aún **~9% más lento** que Fortran -O3 (pendiente optimizar)
- C++ conserva energía **66×** mejor que GROMACS en NVE

## Columnas de energy.dat

| Columna (0-idx) | Variable |
|---|---|
| 0 | step |
| 10 | ekin |
| 11 | epot |
| 14 | etot |
| 24 | temperatura |
| 25 | presión |

## Pendiente

- [ ] C++ más rápido que Fortran -O3 (objetivo: <90s)
- [ ] Backup del código Entrenador L'Étape a GitHub
- [ ] Reconectar OAuth OmniRoute (claude + agy)
