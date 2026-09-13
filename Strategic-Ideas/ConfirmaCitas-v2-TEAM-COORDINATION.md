# TEAM COORDINATOR — CONFIRMACITAS BOT V2 COORDINATION
**Status:** 🤝 IN PROGRESS (Contacting 5 teams)  
**Initiated:** 2026-09-13 19:45 CST  
**Project:** ConfirmaCitas Bot v2 + Android Automation  
**Owner:** Laura (doctora)  
**Target Launch:** Sep 24-28, 2026  

---

## **COORDINACIÓN CON 5 EQUIPOS**

### **EQUIPO 1: RESEARCH INTAKE TEAM**
**Rol:** Monitorear Telegram, rutear queries de Laura

**Requerimientos:**
- Capturar mensajes Telegram de Laura (6247704701)
- Identificar queries: "¿Quién NO confirmó?", "¿Cuántas citas mañana?", etc.
- Rutear a API backend (nueva)
- Mantener contexto/historial

**Dependencias:**
- Bot @satanzote_bot (reutilizar)
- Nuevo handler ConfirmaCitas
- Conexión a API backend (FASE 1)

**Status:** ⏳ Awaiting confirmation

---

### **EQUIPO 2: SECURITY TEAM**
**Rol:** Validar OAuth flows, tokens, almacenamiento seguro

**Requerimientos:**
- Revisar Google Calendar OAuth2 (Laura autoriza, token secure)
- Revisar WhatsApp Business API (credentials, rate limits, audit trail)
- Revisar Android app security (no tokens en código, SSL pinning)
- Revisar Telegram integration (bot token seguro)

**Dependencias:**
- Backend API spec (FASE 1)
- Android app code (FASE 2)

**Status:** ⏳ Awaiting confirmation

---

### **EQUIPO 3: GOVERNANCE TEAM**
**Rol:** Aprobar automatizaciones + políticas

**Requerimientos:**
- Revisar automatización WhatsApp (anti-spam, confirmaciones)
- Revisar reagendamiento automático (requiere aprobación Laura)
- Revisar auditoría (logging completo)
- Aprobar nueva app Android (permisos, data retention)

**Dependencias:**
- Arquitectura finalizada (FASE 1)
- Security checklist aprobado

**Status:** ⏳ Awaiting confirmation

---

### **EQUIPO 4: PROXMOX OPTIMIZATION TEAM**
**Rol:** Verificar capacidad de CT 109

**Requerimientos:**
- Monitorear CT 109 performance (CPU, RAM, disk)
- Validar recursos para nuevo API backend
- Alertas si CPU > 80%, RAM > 85%, latency > 500ms

**Dependencias:**
- Backend API spec (FASE 1)
- Load testing (FASE 3)

**Status:** ⏳ Awaiting confirmation

---

### **EQUIPO 5: CENTRAL DASHBOARD TEAM**
**Rol:** Mostrar métricas en real-time

**Requerimientos:**
- Dashboard widgets: citas confirmadas/no-confirmadas, reagendamientos, msgs enviados
- Datos tiempo real (refresh 5min)
- Histórico/trending (opcional)

**Dependencias:**
- API endpoints (FASE 1)
- Database schema (FASE 1)

**Status:** ⏳ Awaiting confirmation

---

## **CONSOLIDADO: READINESS CHECK**

| Equipo | Status | Dependencias |
|--------|--------|---|
| 1. Research Intake | ⏳ Pending | API backend + handler |
| 2. Security | ⏳ Pending | API spec + app code |
| 3. Governance | ⏳ Pending | Architecture finalized |
| 4. Proxmox | ⏳ Pending | API load profile |
| 5. Dashboard | ⏳ Pending | API endpoints + schema |

---

## **PRÓXIMO PASO**

Una vez todos 5 equipos confirmen:
→ **deployment-orchestrator** procede con 5 FASES:
  1. Preparation (dirs, configs, profiles)
  2. Infrastructure (provision, networking, security)
  3. Deployment (deploy services, smoke tests)
  4. Validation (integration tests, security gates)
  5. Handoff (docs, approval, git, alerts)

Si hay bloqueos:
→ Reportar a José + proponer alternativas (A/B/C)

---

**STATUS:** Aguardando respuestas de los 5 equipos
