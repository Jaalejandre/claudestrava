# UAMI SIMULATOR TEAM — PAPÁ (FATHER) ACCESS
**Status:** 🟢 OPERATIONAL (awaiting papá's Telegram ID)  
**Created:** 2026-09-13  
**Users:** Papá (read-only status + simulator control)  
**Project:** UAMI DM Phase 5 (GPU-accelerated molecular dynamics)  

---

## **EQUIPO 17: UAMI SIMULATOR TEAM (3 bots)**

| Bot | Purpose | Trigger |
|---|---|---|
| **uami-simulator-bot** | Execute GPU simulations (papá provides parameters) | On-demand (user request) |
| **uami-status-bot** | Query Phase 5 progress + benchmarks | On-demand (user questions) |
| **uami-orchestrator-supervisor** | Monitor queue, log activity, alert José | Continuous + per-run |

---

## **PAPÁ'S CAPABILITIES**

### **1. Run Simulations**

Papá can send:
```
"Correr sim: steps=10000, temp=298, ensemble=NVE, potential=LJ"
```

Bot validates → asks confirmation → executes on CT 901 GPU → returns results:
```
✅ Steps completed: 10000/10000
Wall time: 245 seconds
Throughput: 40.8 st/s
GPU utilization: 85%
Status: SUCCESS
```

**Valid parameters:**
```
steps: 1000-100000
temperature: 100-500 K
ensemble: NVE, NPT, NVT
potential: LJ, Mie, FDR, Ewald
```

---

### **2. Query Status**

Papá can ask:
```
"¿Cómo va Phase 5?"
"¿Cuántos st/s?"
"¿Hay errores?"
"¿Cuándo termina?"
"¿Benchmarks?"
"¿Error log?"
```

Bot returns real-time info from vault + benchmarks.

---

## **SECURITY & GOVERNANCE**

```
✅ Parameter validation (no invalid values)
✅ Max 1 concurrent simulation (queue others)
✅ Timeout: 2 hours max
✅ Confirmation required before execution
✅ Full audit trail (all runs logged)
✅ José alerted on errors
✅ No access to other projects (read-only UAMI)
```

---

## **WELCOME MESSAGE TEMPLATE (for papá)**

When papá's Telegram ID is provided, send this:

```
👋 ¡Hola papá!

Te doy la bienvenida al equipo UAMI.

Ahora puedes:
✅ Ver progreso de Phase 5 en tiempo real
✅ Correr simulaciones GPU (mandas parámetros, yo ejecuto)
✅ Ver benchmarks, errores, logs

El proyecto tiene:
🤖 16+ equipos inteligentes trabajando 24/7
🤖 57+ agentes coordinados
🤖 Monitoreo automático de infra, seguridad, benchmarks

PREGUNTAS QUE PUEDES HACER:
"¿Cómo va Phase 5?"
"¿Cuántos st/s vamos?"
"¿Hay errores?"
"¿Cuándo termina?"

SIMULAR:
"Correr sim: steps=10000, temp=298, ensemble=NVE, potential=LJ"
Yo valido parámetros → te pido confirmación → ejecuto en GPU → te doy resultados

✅ Todo seguro, validado, auditado.

¿Preguntas?
```

---

## **INTEGRATION WITH GOVERNANCE + SECURITY**

- **Governance Team:** Validates all simulation parameters (no exploits)
- **Security Team:** Monitors access (only papá's Telegram ID can trigger)
- **Benchmark Team:** Captures results (adds to historical trending)
- **Proxmox Team:** Monitors CT 901 GPU health during sims
- **José (Owner):** Receives daily activity summary

---

## **AUDIT TRAIL**

Every simulation logged to: `~/.hermes/logs/uami-simulator-activity.log`

```
[2026-09-14 10:30] Papá: steps=10000, temp=298, ensemble=NVE → EXECUTED
  Result: 40.8 st/s, wall_time=245s, status=SUCCESS
  
[2026-09-14 11:00] Papá: "¿Cuántos st/s?" → STATUS_QUERY
  Response: 7d-avg=41.2 st/s, trend=stable
```

---

## **STATUS: READY**

Awaiting: Papá's Telegram ID

When received:
1. Add to whitelist (security)
2. Activate 3 bots (simulator, status, supervisor)
3. Send welcome message
4. Papá can start using immediately

---

**Next step:** Get papá's Telegram ID (@userinfobot /start)
