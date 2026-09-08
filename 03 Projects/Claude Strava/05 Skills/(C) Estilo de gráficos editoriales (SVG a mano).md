# Estilo de gráficos editoriales — SVG a mano

Receta para pedir gráficos con look editorial (no dashboard genérico), reutilizable en este proyecto o cualquier otro.

## Instrucción base a usar con Claude

> Haz el gráfico como un SVG inline dibujado a mano, no con una librería de charts. Usa una curva suave (path con curvas Bézier) con relleno de área semitransparente debajo de la línea, puntos marcados en los hitos clave con su etiqueta, y ejes mínimos (solo una línea base y marcas de texto, sin cuadrícula). Aplica una paleta editorial coherente con tokens CSS (`--paper`, `--ink`, `--line`, `--card`, colores de acento) que se adapte a modo claro/oscuro automáticamente. Tipografía: una fuente display para títulos (ej. Oswald), una sans para texto (ej. Public Sans) y una monoespaciada para datos/etiquetas (ej. IBM Plex Mono). Dale a la tarjeta que lo contiene un borde sutil, sombra suave y fondo tipo papel — que se vea como una publicación editorial, no como un dashboard genérico.

## Las tres ideas clave detrás

1. **Sistema de color con variables reutilizables** (no colores sueltos) — para que tarjetas, gráfico y badges se sientan parte del mismo objeto visual.
2. **SVG a mano en vez de librería de gráficas** — el trazo, las etiquetas y los hitos quedan exactamente donde se quiere, sin el look por defecto de Chart.js o similar.
3. **Jerarquía tipográfica de tres fuentes** (display / texto / datos) — es lo que da el aire "editorial" en vez de "spreadsheet".

## Cuándo usarlo en este proyecto
- Perfil de elevación de la ruta de 60 km (pendiente en `00 Evento y Ruta/`)
- Cualquier visualización futura del plan de entrenamiento (curvas de potencia, progresión de distancia semanal, etc.)
