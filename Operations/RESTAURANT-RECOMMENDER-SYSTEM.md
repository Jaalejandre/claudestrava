# RESTAURANT RECOMMENDER BOT
**Status:** 🟢 OPERATIONAL  
**Type:** Conversational Assistant  
**Integration:** Research Intake + Telegram  

---

## MISSION

Help José and Laura choose the perfect restaurant in CDMX through conversational questions.

---

## HOW IT WORKS

### User sends: "¿A qué restaurante ir?"

**Bot responds with guided questions:**

```
1️⃣ ¿Qué tipo de comida te apetece?
   → User: "Sushi"

2️⃣ ¿Qué zona de CDMX?
   → User: "Polanco"

3️⃣ ¿Cuál es tu presupuesto?
   → User: "Medio-alto"

4️⃣ ¿Ambiente?
   → User: "Casual con amigos"

🍽️ BOT RESPONDS WITH TOP 3 RECOMMENDATIONS
```

---

## SEARCH STRATEGY

**Order of operations:**

1. **Vault Search** — Check saved Google Maps links in vault
   ```
   ~/JarvisVault/Research-Intake/SOCIAL/
   → Extract restaurant names + locations
   → Match against user preferences
   ```

2. **Web Search** — If vault has <2 options
   ```
   Query: "Best [cuisine] restaurants [zone] CDMX 2026"
   Filter by: Budget, Ambiance, Rating
   ```

3. **Combine** — Merge vault findings + web research
   ```
   Return: Top 3 recommendations with:
   • Name + Location
   • Budget level
   • Why it's good for them
   • Google Maps link (if available)
   ```

---

## RESPONSE FORMAT

```
🍽️ RECOMENDACIONES PARA TI

Tipo: Sushi
Zona: Polanco
Presupuesto: Medio-Alto
Ambiente: Casual con amigos

TOP 3 OPCIONES:

1️⃣ Hiroto Sushi
   📍 Ubicación: Polanco
   💰 Presupuesto: $$$
   ⭐ Razón: Excelente sushi, ambiente casual, perfecto para grupos
   🔗 Maps: [link]

2️⃣ Enso Sushi
   📍 Ubicación: Polanco
   💰 Presupuesto: $$$
   ⭐ Razón: Rolls creativos, buena relación precio-calidad
   🔗 Maps: [link]

3️⃣ Osaka
   📍 Ubicación: Polanco
   💰 Presupuesto: $$$
   ⭐ Razón: Clásico, ambiente amigable, múltiples opciones
   🔗 Maps: [link]

¿Te gusta alguno? ¿Quieres otra opción?
```

---

## FEATURES

✅ **Conversational** — Asks clarifying questions
✅ **Vault-aware** — Checks saved restaurants first
✅ **Web search** — Falls back to web if needed
✅ **Personalized** — Filters by cuisine, zone, budget, ambiance
✅ **Integrated** — Can save new finds to Research Intake vault
✅ **Dual user** — Works for both José and Laura

---

## FOLLOW-UP FLOWS

### User likes recommendation:
```
User: "Me gusta Hiroto Sushi"
Bot: "¡Excelente! ¿Quieres que guarde el link en tu vault de restaurantes?"
User: "Sí"
Bot: [Saves Google Maps link to Research Intake/SOCIAL/]
     [Updates indices]
     "✅ Guardado en tu Research Intake"
```

### User wants more options:
```
User: "¿Hay más opciones?"
Bot: "Claro! ¿Qué más te gustaría? ¿Otra zona? ¿Otro presupuesto?"
User: "Más económico"
Bot: [Re-searches with new budget filter]
     [Returns 3 new options]
```

### User provides new restaurant:
```
User: "Encontré este restaurante: https://maps.app.goo.gl/..."
Bot: [Analyzes link]
     "¿Te gustaría que lo guarde en tu Research Intake?"
     [Stores with proper categorization]
```

---

## VAULT INTEGRATION

**Saves restaurant links to:**
```
~/JarvisVault/Research-Intake/SOCIAL/
  └── [timestamp]-[contributor]-google-maps-restaurant.md
```

**Metadata tracked:**
```yaml
type: "LOCATION"
category: "Restaurante"
cuisine: "Sushi"
zone: "Polanco"
budget: "Medio-Alto"
ambiance: "Casual"
contributor: "José" or "Laura"
saved_via: "Recommendation" or "Direct link"
```

**Indexed in:**
- `Intake-Log.md` (chronological)
- `Category-Index.md` (by cuisine)
- `Relevance-Index.md` (by rating/frequency)

---

## DEPLOYMENT

### Activation:
1. Bot SOUL configured ✅
2. Plugin integrated ✅
3. Cron monitor deployed ✅
4. Telegram detection ready ✅

### How to use:
- Laura or José: Send message to @satanzote_bot
- Keywords: "restaurante", "comer", "ir a cenar", etc.
- Bot: Detects + routes to Restaurant Recommender
- Bot: Asks clarifying questions
- Bot: Returns personalized recommendations

---

## EXAMPLES

**Example 1: Laura wants sushi**
```
Laura: "¿Dónde puedo comer sushi?"
Bot: "¡Sushi! ¿Qué zona prefieres? (Polanco, Condesa, Roma, otra?)"
Laura: "Condesa"
Bot: "Excelente. ¿Presupuesto?"
Laura: "Medio"
Bot: "¿Ambiente casual o romántico?"
Laura: "Casual"
Bot: [Returns 3 sushi options in Condesa, medium budget, casual]
```

**Example 2: José wants something traditional**
```
José: "Comida mexicana tradicional en Centro"
Bot: "¡Mexicana! ¿Especifica...?"
José: "Mole y tamales, presupuesto económico"
Bot: [Searches vault + web]
     [Returns 3 options in Centro]
     [All have traditional mole/tamales]
```

**Example 3: Laura adds a find**
```
Laura: "Encontré este lugar: https://maps.app.goo.gl/..."
Bot: "¿De qué tipo de comida?"
Laura: "Tailandesa, Polanco"
Bot: "✅ Guardado como restaurante tailandés en Polanco"
     [Auto-tags and indexes]
```

---

## NOTES

- Restaurant data periodically updated from vault
- Web search uses current 2026 data
- Rating/review data from Google Maps, Yelp, local sources
- Budget levels: $ (< $200), $$ ($200-500), $$$ ($500-1000), $$$$ (> $1000)
- Ambiance options: Casual, Romantic, Business, Group/Social, Family
- Zones: Polanco, Condesa, Roma, San Ángel, Coyoacán, Centro, Reforma, Lomas, etc.

---

**Version:** 1.0  
**Created:** 2026-09-13  
**Status:** Production-ready
