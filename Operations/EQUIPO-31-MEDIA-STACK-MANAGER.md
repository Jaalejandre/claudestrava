---
title: "EQUIPO 31: MEDIA STACK MANAGER — Actualización, Optimización, Limpieza"
date: 2026-09-14T00:30:00-06:00
phase: 62
status: "🚀 LISTO PARA ACTIVAR"
owner: Sistema (Hermes)
members: 5 bots especializados
priority: "🟢 NORMAL"
cron: "Diario 02:00 CST (Domingo + auditoría profunda)"
---
role_csuite: "COO (Chief Operating Officer)"

# EQUIPO 31: MEDIA STACK MANAGER

## Misión
Mantener el stack de media (aplicaciones, dependencias, datos, librerías) **100% actualizado, optimizado y limpio** de residuos.

---

## 5 BOTS ESPECIALIZADOS

### 1️⃣ **stack-updater**
**Responsabilidad:** Mantener dependencias actualizadas

**Tareas:**
- Monitorea npm, pip, apt, Fortran/CUDA packages
- Ejecuta `npm audit fix`, `pip list --outdated`
- Propone upgrades menores (patch/minor)
- Versiona cambios en Git
- Escala a E29 (Auditor) si major version change

**Cron:** Diario 02:00 CST
**Reporte:** Notifica a Slack (#media-stack) si hay updates

---

### 2️⃣ **performance-optimizer**
**Responsabilidad:** Optimizar rendimiento del stack

**Tareas:**
- Perfila aplicaciones (Node, Python, Fortran)
- Identifica bottlenecks (CPU, memoria, I/O)
- Aplica: lazy-loading, caching, compression, async/await
- Compila código C++/Fortran con flags -O3
- Mide antes/después (throughput, latency, memory)

**Cron:** Dos veces por semana (Lunes 03:00, Jueves 03:00 CST)
**Reporte:** Propone cambios a E29 si mejora > 5%

**Ejemplos:**
```
✅ Compress images en dashboard
✅ Lazy-load Charts en Prometheus
✅ Cache queries en vault-index.db
✅ Parallelize GPU kernels (LISTA, FUERZAS, KWALD)
✅ Minify CSS/JS en prototipos
```

---

### 3️⃣ **garbage-collector**
**Responsabilidad:** Eliminar residuos, limpiar logs

**Tareas:**
- Borra logs > 30 días en `/root/.hermes/logs/`
- Limpia caché de browser (> 100MB)
- Elimina duplicados en vault (dedup)
- Borra archivos temporales (*.tmp, *.bak)
- Comprime archives antiguos (.tar.gz)
- Libera espacio en disco (target: 20% libre siempre)

**Cron:** Diario 04:00 CST
**Umbral:** Alerta a E21 (Server Security) si disco < 15%

**Ejemplo:**
```
/root/.hermes/logs/ → 2.3 GB → Archiva > 30d → 150 MB liberados
/root/.hermes/cache/ → Limpia browser-use > 100MB → OK
/root/JarvisVault/ → Dedup archivos idénticos → 50 archivos fusionados
```

---

### 4️⃣ **code-auditor**
**Responsabilidad:** Auditar calidad y seguridad del código

**Tareas:**
- Ejecuta linters: eslint (JS), pylint (Python), gfortran -Wall (Fortran)
- Escanea vulnerabilidades: npm audit, snyk, bandit
- Identifica código muerto (unused functions, imports)
- Propone refactoring (simplify, DRY, solid principles)
- Verifica coverage de tests
- Genera reporte de deuda técnica

**Cron:** Dos veces por semana (Martes 05:00, Viernes 05:00 CST)
**Reporte:** Propone cambios a E26 (Deployment) o E29 (Auditor)

**Ejemplo:**
```
eslint /root/dashboard-dist/ → 3 issues (unused vars, missing semicolons)
pylint /project/prototipos/harness.py → 2 warnings (line too long)
gfortran -Wall /root/dm_stability_demo.f95 → ✅ Clean
snyk check → ✅ No vulnerabilities in npm
```

---

### 5️⃣ **stack-monitor**
**Responsabilidad:** Monitorear salud general del stack

**Tareas:**
- Verifica todas las dependencias instaladas (npm ls, pip list)
- Chequea versiones de compiladores (gfortran, nvcc, cmake)
- Valida rutas de binarios (test -x programa)
- Prueba start/stop de servicios críticos (Hermes, gateway, Prometheus)
- Mide disk usage por carpeta (/root, /root/JarvisVault, /root/.hermes)
- Genera health dashboard

**Cron:** Cada 6 horas (02:00, 08:00, 14:00, 20:00 CST)
**Reporte:** Dashboard en `http://localhost:3001/media-stack` (integrado en E20 Dashboard)

**Métrica de salud:**
```
✅ GREEN:  Todas dependencias actualizadas, disk > 20%, CPU < 40%
🟡 YELLOW: Updates disponibles, disk 15-20%, CPU 40-70%
🔴 RED:    Updates críticas, disk < 15%, CPU > 70%
```

---

## INTEGRACIÓN CON OTROS EQUIPOS

| Equipo | Trigger | Acción |
|--------|---------|--------|
| E26 (Deployment) | code-auditor propone refactor | Valida + deploy si pasa tests |
| E29 (Auditor) | performance-optimizer > 5% mejora | Audita cambios, aprueba/rechaza |
| E21 (Server Security) | garbage-collector (disk < 15%) | Alerta crítica |
| E20 (Dashboard) | stack-monitor | Renderiza health en dashboard |
| E24 (Info Broker) | Diario 02:30 CST | Pub: `media-stack.daily-report` |

---

## AUTOMATIZACIONES PREDEFINIDAS

### A. Actualización de dependencias (npm)
```bash
# Lunes 02:00 CST
npm audit fix --audit-level=moderate
npm update --save
git commit -m "deps: update npm packages $(date +%Y-%m-%d)"
git push
```

### B. Limpiar logs
```bash
# Diario 04:00 CST
find /root/.hermes/logs/ -mtime +30 -type f -exec rm {} \;
tar -czf /root/.hermes/logs/archive-$(date +%Y%m).tar.gz /root/.hermes/logs/*.log
du -sh /root/.hermes/logs/
```

### C. Escanear vulnerabilidades (Python)
```bash
# Martes 05:00 CST
pip list --outdated
bandit -r /project/prototipos/ -f json > /tmp/bandit-report.json
```

### D. Validar compiladores
```bash
# Cada 6 horas
which gfortran && gfortran --version
which nvcc && nvcc --version
which cmake && cmake --version
test -x /root/dm_demo && echo "✅ Fortran binary OK"
```

---

## ESCALADO Y AUDITORÍA

**Cambios menores** (patches, cache cleanup):
- stack-updater/garbage-collector ejecutan autónomamente
- Notifican post-ejecución a Slack

**Cambios mayores** (major version upgrade, refactor):
- Escalan a E29 (Auditor) para revisión
- E29 aprueba/rechaza en 24h
- Si aprobado → E26 (Deployment) ejecuta + tests

**Estado crítico** (disk full, vulnerabilidad crítica):
- Escalan inmediatamente a E21 (Server Security)
- E21 ejecuta acción de emergencia

---

## DASHBOARD DE SALUD (integrado en E20)

```
MEDIA STACK HEALTH — Actual 2026-09-14 00:30

Dependencies:        ✅ GREEN
  npm:               30 packages, 0 outdated
  pip:               15 packages, 1 outdated (pandas)
  system (apt):      Ubuntu 22.04 LTS, 2 security updates available

Disk Usage:          ✅ GREEN
  Total:             1.2 TB / 2 TB (60%)
  /root/:            450 GB (safe)
  /root/JarvisVault: 28 GB (safe)
  /root/.hermes:     12 GB (safe)
  Logs:              1.5 GB (age: < 30 days)

Compilation:         ✅ GREEN
  gfortran:          v11.4.0 (OK)
  nvcc:              CUDA 13.0 (OK)
  cmake:             3.28 (OK)
  Binaries:          dm_demo, phase4_cuda (all OK)

Services:            ✅ GREEN
  Hermes:            running (pid 1234)
  Gateway:           running (port 20128)
  Prometheus:        running (port 9090)
  Dashboard:         running (port 3000)

Performance:         ✅ GREEN
  CPU avg (6h):      22% (target: < 40%)
  Memory avg (6h):   5.2/10 GB (target: < 80%)
  Disk I/O:          stable

Code Quality:        🟡 YELLOW
  eslint:            3 issues (unused vars)
  pylint:            2 warnings (line length)
  gfortran:          ✅ clean
  Security (snyk):   ✅ no vulnerabilities

Last Full Audit:     2026-09-13 23:00 CST
Next Run:            2026-09-14 08:00 CST
```

---

## CRON SCHEDULE

```
DAILY:
  02:00 CST  → stack-updater (npm audit fix)
  02:30 CST  → E24 (Info Broker) pub media-stack.daily-report
  03:00 CST  → performance-optimizer (Lunes + Jueves)
  04:00 CST  → garbage-collector (logs, cache)
  05:00 CST  → code-auditor (Martes + Viernes)

6-HOURLY:
  02:00, 08:00, 14:00, 20:00 CST → stack-monitor

WEEKLY:
  Domingo 08:00 CST → E29 (Auditor) revisa media-stack report
  Domingo 09:00 CST → E21 (Server Security) chequea seguridad
```

---

## INTEGRACIÓN CON VAULT

**Documentación:**
- `/root/JarvisVault/Operations/EQUIPO-31-MEDIA-STACK-MANAGER.md` (este archivo)
- `/root/JarvisVault/Operations/MEDIA-STACK-HEALTH-DASHBOARD.md` (métricas)

**Reportes guardados en:**
- `/root/.hermes/cache/media-stack/reports/` (daily, weekly)
- GitHub branch: `media-stack-updates` (commits diarios)

---

## RESPONSABILIDADES CLARAS

| Bot | Autonomía | Escalado a |
|-----|-----------|------------|
| stack-updater | ✅ Patch/minor updates | E29 si major version |
| performance-optimizer | ✅ Optimizaciones < 5% | E29 si > 5% mejora |
| garbage-collector | ✅ Limpiar residuos | E21 si disk crítico |
| code-auditor | ✅ Reportar | E26/E29 si refactor propuesto |
| stack-monitor | ✅ Monitorear | E21 si estado crítico |

---

## STATUS

```
🚀 LISTO PARA ACTIVAR

Delegado a: COORDINADOR 6 (cuando José confirme)
Integración: E20 Dashboard, E24 Broker, E26 Deployment, E29 Auditor, E21 Security
Cron: Automático (02:00 CST daily, 6h monitoring)
Vault: Documentado + GitHub sync
```
