# DASHBOARD ANIMADO — PLAN DE EJECUCIÓN
**Status:** 🚀 INICIANDO AHORA (Fase 1 comenzando)  
**Owner:** José  
**Target:** satanzote.me  
**Timeline:** 3-4 horas (serial, sin paralelo)  
**Deadline:** Hoy antes de dormir  

---

## VISIÓN

Dashboard Prometheus interactivo mostrando:
- **18 Equipos** con figuritas animadas "trabajando"
- **Métricas en tiempo real:** CPU, RAM, Disk, Network, GPU, Procesos
- **3 Hosts monitoreados:** CT 109, CT 901, VM 106 (HA)
- **Animaciones:** Equipos pulsando, barras subiendo, indicadores verdes/rojos

---

## FASES DE EJECUCIÓN (SERIAL)

### ⏳ FASE 1: SCOPE + REQUISITOS (5-10 min)
- [ ] Definir métricas exactas a monitorear
- [ ] Definir animaciones (¿qué tipo de figuritas?)
- [ ] Confirmar stack: React + Grafana panel o custom HTML?
- [ ] Confirmar dominio satanzote.me (¿ya tiene DNS?)

### ⏳ FASE 2: PROMETHEUS SETUP (20-30 min)
- [ ] Verificar Prometheus en CT 109 (¿existe?)
- [ ] Si NO existe: instalar + configurar
- [ ] Scrape targets: CT 109, CT 901, VM 106
- [ ] Verificar data: /api/v1/query_range

### ⏳ FASE 3: FRONTEND ANIMADO (90-120 min)
- [ ] Stack: React + Recharts (gráficos) + animaciones CSS/GSAP
- [ ] Componentes: 18 Team cards con figuritas
- [ ] Real-time updates: WebSocket o polling Prometheus
- [ ] Layout: Grid 4x5 o similar (18 equipos visibles)

### ⏳ FASE 4: DEPLOY satanzote.me (20-30 min)
- [ ] Build + optimizar
- [ ] Deploy: Cloudflare Workers o web server
- [ ] DNS: satanzote.me → 192.168.0.64 (CT 109) o Cloudflare
- [ ] HTTPS: certificado válido

### ⏳ FASE 5: TEST + REFINEMENTS (30-45 min)
- [ ] Probar métricas en vivo
- [ ] Ajustar animaciones
- [ ] Pulir UI/UX
- [ ] Documentar para futuros cambios

---

## EQUIPOS INVOLUCRADOS

| Equipo | Rol | Acción |
|--------|-----|--------|
| Proxmox Optimization (4) | Infraestructura | Provisionar Prometheus, asegurar acceso a métricas |
| Central Dashboard (2) | Orquestación | Coordinar fases, validar outputs |
| Home Assistant Control (3) | Integración | Exponer métricas de VM 106 (Home Assistant) |
| Deployment Orchestrator (team-coordinator) | Meta | Este plan |

---

## DECISIONES PENDIENTES

1. **Stack Frontend:** 
   - Opción A) React + Recharts + GSAP (profesional)
   - Opción B) HTML + Chart.js + CSS animations (más simple)
   - Opción C) Grafana + custom panel (integrado con Prometheus)

2. **Tipo de Figuritas:**
   - Opción A) Emojis animados (🤖, 🔧, etc.)
   - Opción B) SVG personalizados por equipo
   - Opción C) Iconos + barras de progreso

3. **Actualización de Datos:**
   - Opción A) WebSocket (real-time, pero más complejo)
   - Opción B) Polling cada 5s (simple, suficiente)

4. **Dominio satanzote.me:**
   - ¿Ya está registrado?
   - ¿DNS apunta a dónde?
   - ¿Puede ser http://satanzote.me/dashboard o debe ser subdomain?

---

## SIGUIENTE PASO

**Esperando confirmación de José en Fase 1:**
1. ¿Qué stack prefieres? (A/B/C)
2. ¿Qué tipo de figuritas? (A/B/C)
3. ¿Polling o WebSocket?
4. ¿Dominio satanzote.me — DNS status?

Una vez confirmado → **FASE 2 comienza inmediatamente.**

---

**ESTIMADO TOTAL:** 3-4 horas, completado hoy antes de dormir.
