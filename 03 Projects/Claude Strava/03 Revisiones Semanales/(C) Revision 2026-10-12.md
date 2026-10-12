# Revisión — 2026-10-12

> ⚠️ Esta revisión cubre **4 semanas**, no 1. Las revisiones programadas del 20 sep, 27 sep y 4 oct no se ejecutaron — hubo un hueco de ~4 semanas en la automatización. Esta corrida (lunes 12 oct, no domingo) retoma el ciclo. Queda documentado para que se revise el disparador programado.

## Lo entrenado (últimos 7 días: 5 oct – 12 oct)

**3 actividades en Strava en esta ventana**, todas VirtualRide en Zwift:

| Actividad | Fecha | Distancia | Duración | Potencia avg | FC avg | Cadencia avg | Esfuerzo relativo |
|---|---|---|---|---|---|---|---|
| Zwift - Going Coastal | 5 oct | 16.6 km | 38 min | 121.8 W (Z3 tempo) | 131 bpm (Z2) | 86.9 rpm | 24 |
| Zwift - Going Coastal | 6 oct | 7.8 km | 17 min | 119.3 W (Z3 bajo) | 123.6 bpm (Z2) | 87.2 rpm | 7 |
| Zwift - Jungle Circuit | 9 oct | 10.6 km | 43 min | 98.3 W (Z2 resistencia) | 117.5 bpm (Z1) | 88.6 rpm | 10 |

Sin FTP test, sin fuerza, sin descanso activo registrado, sin rodada outdoor, sin sesión de cadencia dedicada (aunque la cadencia de estas 3 rodadas ya anda en 87-89 rpm — dentro del rango objetivo 85-95).

## El panorama completo (4 semanas desde la última revisión, 14 sep – 12 oct)

| Semana | Actividades | Detalle |
|---|---|---|
| 15-21 sep | 0 | — |
| 22-28 sep | 0 | — |
| 29 sep – 5 oct | 3 | Zwift 1 oct (11 km, 121 W, 73 rpm), Zwift 2 oct (14.8 km, 121 W, 82 rpm), Zwift 5 oct (ver tabla) |
| 6-12 oct | 2 | Ver tabla arriba (6 y 9 oct) |

**Total: 5 sesiones en 4 semanas, de ~20 esperadas (5/semana).** Las 5 son indoor en Zwift — **cero rodadas outdoor, cero fuerza, cero descanso activo, cero test de FTP** en todo este periodo, que corresponde a lo que debían ser las semanas 3, 4 y 5 de la Fase 1 (Base) y el arranque de la Fase 2.

**Dato positivo:** la cadencia subió de 73-82 rpm (rodadas de inicios de octubre) a 87-89 rpm (rodadas del 5 y 9 de octubre) — ya dentro del rango objetivo. Mejora real sobre el punto débil original (44-52 rpm outdoor).

**Sin señales de sobreentrenamiento:** potencia, FC y esfuerzo relativo están bajos y estables en todas las sesiones — el problema es consistencia y volumen, no exceso.

## Comparación contra el plan

Según fechas, al 12 de octubre deberíamos estar cerrando la Fase 1 (Base, terminaba 7 oct) y arrancando la Fase 2 (Construcción, intervalos Z4 + progresión a 58 km outdoor). En la práctica:

| Lo que pedía el plan (4 semanas) | ¿Se hizo? |
|---|---|
| Test de FTP real | ❌ No — 5 semanas de retraso |
| Rodadas estructuradas Z2 (45-60 min) | ⚠️ Parcial — 5 rodadas cortas (17-43 min), más en Z3 que Z2 |
| Fuerza 1x/semana | ❌ No, ninguna sesión en 4 semanas |
| Descanso activo | ❌ No registrado |
| Cadencia dedicada | ⚠️ No como sesión propia, pero la cadencia de las rodadas normales ya mejoró |
| Rodada larga outdoor (progresión 20→25→30 km) | ❌ No — cero km outdoor en todo el ciclo |

## ¿Ajuste al plan?

**Sí — ajuste de fondo, no solo de fechas.** Esta es la tercera revisión consecutiva con consistencia muy baja (semana 1: 0 sesiones; semana 2: 1 sesión; y ahora 4 semanas más con solo 5 sesiones cortas, todas indoor). La nota del 14 sep ya había anunciado el disparador: *"si la semana del 17-23 sep vuelve a mostrar consistencia muy baja, el objetivo de la carrera necesita replantearse."* Se cumplió, y con margen amplio.

Cambios hechos in-place en `02 Plan de Entrenamiento/`:

- **El objetivo de la carrera cambia de "tiempo objetivo" a "terminar dentro del límite de tiempo."**
- **Fase 1 (Base) se cierra el 7 oct** tal como estaba fechada — no se extiende de nuevo.
- **Fase 2 se redefine por completo**: deja de ser "Construcción" (intervalos Z4, progresión a 58 km) y pasa a ser "Reconstrucción" — Z2/Z3, primera rodada outdoor de todo el ciclo esta semana, progresión corta y realista (15→25→30-35→35-40 km), fuerza real por primera vez.
- **Fase 3 (Taper) se acorta de ~2.5 a ~1.5 semanas** (9-15 nov) para cederle días a la reconstrucción. Sigue protegida — no se elimina, porque llegar a la carrera sin ningún descanso es ahora el riesgo más alto.
- **Vigilar:** el FTP estimado de Strava (148 W) puede estar alto — los mejores esfuerzos de 20-30 min de las rodadas recientes rondan 104-125 W. Sin test real no se puede confirmar, pero las zonas podrían estar corridas hacia arriba.

Razón del cambio de objetivo: quedan ~34 días (≈5 semanas) para la carrera y no hay un solo kilómetro outdoor acumulado bajo este plan. Meter intensidad fuerte o una progresión agresiva de distancia ahora sería apostar a una lesión o a un mal día de carrera en vez de mejorar el resultado. La prioridad es llegar a la línea de salida y terminar, no un tiempo específico.

## InBody

No hay archivo nuevo en `01 Datos InBody/` desde la última medición (19 ago 2026). El único commit sobre `InBody.pdf` en este periodo (18 sep) es el mismo batch commit no relacionado ya identificado en la revisión del 14 sep. El resumen (`(C) Resumen InBody.md`) sigue vigente, no requiere actualización. Sigue pendiente de cruzar cuando haya medición nueva — y la pérdida de masa muscular esquelética que ya estaba marcada como riesgo sigue sin atenderse, porque no hubo ni una sesión de fuerza en 4 semanas.

## Qué toca la próxima semana (Semana 6, arranque de la Fase 2 "Reconstrucción")

- **Primera rodada outdoor del ciclo:** ~15 km, todo en Z2, sin apuro.
- **Fuerza:** sentadilla, peso muerto rumano, zancadas, plancha — 3×10-12. Primera sesión real del ciclo entero.
- **Rodada estructurada:** Z2 continuo, 30-45 min (ya no se exige la ventana de 45-60 min hasta recuperar volumen).
- **Cadencia:** seguir en 85-95 rpm — ya se está logrando en las rodadas normales de Zwift.
- **Test de FTP real:** sigue siendo prioridad #1 si hay oportunidad esta semana.

Próxima revisión: domingo 18 oct 2026 (o el próximo ciclo dominical programado — ver nota al inicio sobre el hueco de automatización).
