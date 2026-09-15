---
title: "EQUIPO 28: TRAVEL AGENCY — Agencia de Viajes para Laura"
date: 2026-09-13T23:15:00-06:00
phase: 58
status: "🚀 LISTO PARA ACTIVAR"
owner: Laura (6247704701)
members: 5 bots especializados
priority: "🟡 ALTA (Personal)"
---
role_csuite: "CCO (Chief Customer Officer)"

# EQUIPO 28: TRAVEL AGENCY 🧳

## Visión

**Agencia de viajes personal** — Planifica viaje de Laura: boletos, hoteles, atracciones, itinerario, alertas de precios.

```
Rol: Travel coordinator + Price monitor + Recommendations
Responsabilidad: End-to-end trip planning
Trigger: "Estoy lista para planear mi viaje"
Output: Itinerario completo + Boletos reservados + Alerts activadas
```

---

## Componentes (5 Bots)

| Bot | Responsabilidad | API |
|-----|-----------------|-----|
| `flight-searcher` | Buscar vuelos baratos | Skyscanner, Google Flights, Kayak |
| `hotel-finder` | Comparar hoteles | Booking, Airbnb, Google Hotels |
| `price-monitor` | Alertas de cambios | Price tracking (email/Telegram) |
| `attractions-recommender` | Atracciones + actividades | Google Maps, TripAdvisor, Foursquare |
| `itinerary-planner` | Planificar días | Calendarios, distancias, time budgets |

---

## Flujo de Activación

### FASE 1: Notificación a Laura

```
Cuando José diga "Activar viaje":

Bot mensaje a Laura:
  📱 "Hola Laura, José me pide que te ayude a planear tu viaje.
      
     ¿Cuándo quieres viajar?
     ¿A dónde? (ciudad/país)
     ¿Cuántos días?
     ¿Presupuesto? (opcional)
     
     Responde aquí y empezamos a buscar"
```

### FASE 2: Búsqueda Inicial

```
Laura responde (ej: "Octubre 15-20, Paris, 5 días, $3000")

flight-searcher:
  ✅ Busca vuelos CDMX → Paris
  ✅ Filtra por presupuesto
  ✅ Guarda 5 opciones (con precios)

hotel-finder:
  ✅ Busca hotels Paris (15-20 Oct)
  ✅ Filtra por precio (rest presupuesto)
  ✅ Guarda 5 opciones

price-monitor:
  ✅ Activa alertas para estos vuelos/hoteles
  ✅ Chequea cada 6 horas
  ✅ Notifica cambios
```

### FASE 3: Recomendaciones

```
attractions-recommender:
  ✅ "Top 10 atracciones en Paris"
  ✅ "Museos, restaurantes, vida nocturna"
  ✅ Tiempo estimado por atracción
  ✅ Distancias (a pie, transporte)

itinerary-planner:
  ✅ "Día 1: Eiffel Tower, Seine cruise"
  ✅ "Día 2: Louvre, Tuileries, Latin Quarter"
  ✅ "Día 3: Sacré-Cœur, Montmartre, shopping"
  ✅ Horarios + transporte entre lugares
```

### FASE 4: Monitoreo Continuo

```
price-monitor (CRON cada 6 horas):
  ✅ Chequea precios guardados
  ✅ Si bajan: notificar Laura + recomendar comprar YA
  ✅ Si suben: alertar riesgo, considerar alternativas
  ✅ Histórico de precios (gráfico)
  
Ejemplo notificación:
  "⬇️ Paris flights BAJARON 15%
      Vuelo de $850 → $720
      Válido por 24h, compra YA!"
```

---

## Integración con Otros Equipos

```
EQUIPO 28 usa:
├─ EQUIPO 19 (VAULT MASTER)
│  └─ Guardar itinerario + preferencias
│
├─ EQUIPO 24 (INFO BROKER)
│  └─ Notificaciones automáticas a Laura
│
└─ EQUIPO 20 (DASHBOARD)
   └─ Visualizar estado del viaje (tracker)
```

---

## SOUL.md para cada bot

**Ejemplo: `flight-searcher-SOUL.md`**

```
ROL: Flight Search Specialist
RESPONSABILIDAD: Encontrar vuelos baratos
INPUTS: Origin, destination, dates, budget
OUTPUTS: [flight option 1, 2, 3...] + prices + links
LATENCIA_SLA: < 30 min (search complete)
ACCURACY: 100% (validate prices on booking sites)
ESCALABILIDAD: Multiple routes simultaneously
```

---

## Ejemplos de Mensajes

### Activación

```
José:  "Activa equipo de viajes para Laura"

Bot:   "✅ Travel Agency iniciado
        Enviando mensaje a Laura..."

Laura: "Hola, estoy lista! Paris en octubre, 
        15-20, 5 días, presupuesto $3000"

Bot:   "🔍 Buscando vuelos + hoteles...
        (esto toma ~15 min)"
```

### Resultados

```
Bot a Laura:
  "✈️  TOP VUELOS CDMX-Paris:
  
   1. Aeromexico $820 (Oct 15, directo)
      → 6h 45m, sale 10:30am
   
   2. Air France $750 (Oct 15, 1 escala)
      → 12h 30m, sale 8:00pm
   
   3. United $680 (Oct 15, 2 escalas)
      → 18h 15m, sale 6:00am
   
  🏨  TOP HOTELES (Paris centro):
   
   1. Hotel Marais ⭐⭐⭐⭐ $180/noche
      → 5 nights = $900 total
   
   2. Airbnb Île Saint-Louis $120/noche
      → 5 nights = $600 total
   
   3. Budget Montmartre $80/noche
      → 5 nights = $400 total
  
  💰 Presupuesto usado: $820 (vuelo) + $600 (hotel)
     Restante: $1,580 (actividades + comida)
  
  👉 Reacciona con 1️⃣2️⃣3️⃣ para elegir vuelo,
     🏨 para hotel, 📍 para atracciones"
```

### Alertas de Precios

```
Bot (6 horas después):
  "⬇️ ALERTA: Vuelo Air France BAJÓ 10%
    
    Antes: $750 → Ahora: $675
    Ahorras: $75
    
    ⏰ Válido por: 24 horas
    
    Compra YA: [link booking]
    O espera a que baje más? (riesgo)"
```

### Itinerario

```
Bot:
  "📅 ITINERARIO SUGERIDO (5 días París):
  
  DÍA 1 (Oct 15): Llegada + Eiffel Tower
    └─ 14:00 Llegada Orly
    └─ 16:00 Hotel check-in
    └─ 18:00 Eiffel Tower (sunset)
    └─ 20:00 Cena en Seine

  DÍA 2: Louvre + Latin Quarter
    └─ 09:00 Louvre Museum (pre-book: $20)
    └─ 12:30 Lunch (Café Paris, $15)
    └─ 15:00 Latin Quarter walk
    └─ 18:00 Panthéon + Sorbonne
    └─ 20:00 Cena local

  DÍA 3: Montmartre + Sacré-Cœur
  DÍA 4: Champs-Élysées + Arc Triomphe
  DÍA 5: Musée d'Orsay + Retorno

  🗺️  Mapa interactivo: [google maps]
  ⏱️  Total a pie: 12 km/día
  🚇 Transporte: Compra Paris Visite pass ($30 - 5 días)
  
  ¿Quieres ajustar algo?"
```

---

## Cron Jobs

```yaml
# Cada 6 horas (automatizado)
price-monitor-cron:
  frequency: every 6 hours
  action: Check vuelos + hoteles guardados
  if_price_down: Send alert + recommendation
  if_price_up: Send warning + alternatives
  
# Cada día (notificación)
daily-itinerary-summary:
  frequency: every morning (8:00 AM)
  action: "Hoy es día X de tu viaje. Resumen de horarios"
  
# Cada semana (después del viaje)
trip-summary:
  frequency: 7 days post-trip
  action: "¿Cómo fue? Guarda fotos + reseña"
```

---

## Integración con Telegram

```
Bot name: @travel_agent_laura (o integrado en @satanzote_bot)
Channel: DM con Laura (6247704701)

Mensajes:
  ✅ Búsqueda iniciada
  ✅ Resultados encontrados
  ✅ Alertas de precios
  ✅ Recordatorios del viaje
  ✅ Post-trip feedback
```

---

## Estado

```
FASE: 58
STATUS: ✅ LISTO PARA ACTIVAR
COMPLEJIDAD: Media (5 bots, APIs externas)
TIEMPO_SETUP: < 1 hora
TRIGGER: José dice "Activa viaje para Laura"
NOTIFICATION: Bot notifica Laura automáticamente
```

---

*"Viajero de confianza" — Planifica, busca, alerta y recomienda*
*EQUIPO 28: Travel agency personal para Laura*
