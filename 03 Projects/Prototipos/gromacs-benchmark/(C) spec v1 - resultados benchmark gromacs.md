# Spec: GromacsMexicano Benchmark Results

Página web estática de una sola pantalla para presentar los resultados del benchmark de GromacsMexicano a los científicos del proyecto. Muestra comparativa de tiempos entre versiones y la pregunta pendiente para los científicos.

## Stack

- HTML + CSS + JS puro (sin frameworks, sin dependencias externas)
- Un solo archivo `index.html`
- Sin backend — solo frontend estático

## Datos del benchmark (hardcoded en el HTML)

### Tiempos medidos (3 corridas, promedio):

| Versión | Corrida 1 | Corrida 2 | Corrida 3 | Promedio |
|---|---|---|---|---|
| Fortran Original (-O0 debug) | 148.5s | 157.7s | 148.1s | 151.4s |
| Fortran Optimizado (-O3 CUDA sm_120) | 97.8s | 98.2s | 97.9s | 98.0s |
| C++ actual | 137.1s | 125.9s | 118.8s | 127.3s |
| C++ objetivo (hipotético) | - | - | - | 70.0s |

### Reducción lograda: −35.3% (original → optimizado)
### Objetivo C++ : ~−50% vs original (hipotético, a validar)

## Archivos esperados

- `index.html` — toda la app en un solo archivo

## Diseño

- Fondo oscuro (#0f1117), tipografía limpia (sans-serif del sistema)
- Header con título "GromacsMexicano — Benchmark de Rendimiento" y subtítulo "Agua SPC/E + NaCl · 2544 átomos · 10,000 pasos · RTX 5070 Ti"
- **Sección 1: Gráfica de barras horizontal** comparando las 4 versiones por tiempo promedio (segundos). Las barras deben ser proporcionales al tiempo. Colores:
  - Original: rojo (#e74c3c)
  - Optimizado: verde (#2ecc71)
  - C++ actual: amarillo/naranja (#f39c12)
  - C++ objetivo: azul punteado o con patrón rayado (#3498db) — marcar claramente como "hipotético"
  - Cada barra muestra el tiempo en segundos y el % de reducción vs original
- **Sección 2: Tabla de corridas** con las 3 corridas individuales de cada versión y el promedio, con colores por fila
- **Sección 3: Pregunta para los científicos** — caja destacada con fondo amarillo/amber con el título "⚠️ Pregunta pendiente para el equipo de DM" y este texto:

  > Durante el análisis del código Fortran se identificó que en `main.f` línea 1641, la rutina `KWALD` (Ewald recíproco) se llama con el parámetro `NATQ` que nunca fue inicializado en el loop de dinámica, lo que resulta en valor 0. Esto significa que **el Ewald recíproco está efectivamente desactivado durante la dinámica**, aunque sí se calcula correctamente en la inicialización.
  >
  > **¿Esto es intencional?**
  > - Si es **intencional**: el rewrite en C++ debe replicar este comportamiento (flag `recip_in_loop = false`)
  > - Si es un **bug**: el rewrite C++ ya lo corrige por default y produce física más precisa
  >
  > Los benchmarks actuales asumen el comportamiento del Fortran original (NATQ=0 en el loop).

- Footer discreto: "GromacsMexicano · CT 901 Ubuntu · Benchmark 2026-09-10"
- Responsive (se ve bien en pantalla grande y en tablet)
- Sin animaciones innecesarias — estilo técnico/limpio

## Criterio de "funciona"

- El archivo `index.html` existe y es HTML válido
- Se puede abrir en navegador y muestra las 3 secciones
- Las barras son visualmente proporcionales (la más larga = Original)
