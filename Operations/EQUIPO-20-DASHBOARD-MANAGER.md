---
title: "EQUIPO 20: DASHBOARD MANAGER — Visualización Central"
date: 2026-09-13T21:05:00-06:00
phase: 53
status: "🚀 INICIANDO"
owner: José
members: 3 bots especializados
---

# EQUIPO 20: DASHBOARD MANAGER 📊

## Misión

**Gestionar toda visualización, reportes y exportación de datos desde una única fuente (VAULT MASTER).**

- No edita nada directamente
- Solo **CONSULTA** a VAULT MASTER
- Genera visualizaciones interactivas
- Exporta a múltiples formatos
- Mantiene dashboard en http://192.168.0.64:3000

## Composición (3 Bots)

| Bot | Rol | Responsabilidad |
|-----|-----|-----------------|
| **dashboard-renderer** | Frontend | Genera HTML/CSS/JS para visualización |
| **metrics-fetcher** | Data | Consulta Prometheus + VAULT MASTER |
| **export-manager** | Output | Exporta a satanzote.me, PDF, JSON |

## Protocolo

### 1. EQUIPO X necesita visualizar datos

```
EQUIPO X: "Necesito ver estado de todos los equipos"
   ↓
EQUIPO 20 (Dashboard Manager):
   1. Consulta VAULT MASTER: "Dame estado de todos los equipos"
   2. VAULT MASTER responde con datos
   3. Consulta Prometheus: métricas CPU/RAM/Disk
   4. Renderiza HTML + gráficos
   5. Sirve en http://192.168.0.64:3000
   ↓
EQUIPO X accede dashboard
```

### 2. Flujo de datos

```
PROMETHEUS (métricas)
    ↓
VAULT MASTER (datos operacionales)
    ↓
EQUIPO 20 (DASHBOARD MANAGER)
    ├─ dashboard-renderer: genera HTML/CSS/JS
    ├─ metrics-fetcher: actualiza datos cada 3s
    └─ export-manager: exporta a satanzote.me
    ↓
USUARIO accede http://192.168.0.64:3000
```

## Responsabilidades

### dashboard-renderer
```python
def render_dashboard():
    # Consulta VAULT MASTER
    vault_data = query_vault_master("GET /status/all-teams")
    
    # Consulta Prometheus
    metrics = query_prometheus([
        "cpu_usage",
        "memory_usage",
        "disk_usage"
    ])
    
    # Renderiza HTML
    html = generate_html(vault_data, metrics)
    return html
```

### metrics-fetcher
```python
def fetch_metrics():
    # Cada 3 segundos:
    while True:
        # 1. Consulta VAULT MASTER
        status = query_vault_master("GET /status/all-teams")
        
        # 2. Consulta Prometheus
        metrics = query_prometheus()
        
        # 3. Combina datos
        combined = merge(status, metrics)
        
        # 4. Actualiza caché
        cache.update(combined)
        
        sleep(3)
```

### export-manager
```python
def export_dashboard():
    # Exporta a múltiples formatos
    data = get_from_cache()
    
    # JSON
    export_json("dashboard-data.json")
    
    # CSV
    export_csv("dashboard-metrics.csv")
    
    # PDF (visual)
    export_pdf("dashboard-report.pdf")
    
    # Deploy a satanzote.me
    deploy_to_satanzote_me()
```

## Endpoints que VAULT MASTER debe proporcionar

```
GET /status/all-teams
  → {"teams": [{"name": "Equipo 1", "status": "✅", "bots": 4}]}

GET /status/team/{id}
  → {"team": "Equipo 1", "status": "✅", "last_activity": "2026-09-13T21:00:00"}

GET /audit/recent
  → {"changes": [{"time": "...", "equipo": "...", "accion": "..."}]}

GET /vault/file/{path}
  → {"content": "...", "last_modified": "...", "modified_by": "..."}
```

## Archivos que DASHBOARD MANAGER mantiene

```
✅ /root/dashboard-dist/
   ├─ index.html (generado dinámicamente)
   ├─ metrics-cache.json (actualizado cada 3s)
   └─ exports/
      ├─ dashboard-data.json
      ├─ dashboard-metrics.csv
      └─ dashboard-report.pdf
```

## Status Hoy

| Componente | Status |
|-----------|--------|
| dashboard-renderer | 🆕 A crear |
| metrics-fetcher | 🆕 A crear |
| export-manager | 🆕 A crear |
| API con VAULT MASTER | 🆕 A diseñar |
| Servidor HTTP | ⚠️  Issues actuales |

## Próximos Pasos

1. ✅ Crear protocolo de comunicación con VAULT MASTER
2. ✅ Implementar 3 bots
3. ✅ Conectar a Prometheus
4. ✅ Lanzar servidor HTTP en puerto 3000
5. ✅ Exportar a satanzote.me (cuando esté listo)

---

**FASE: 53 | ESTADO: 🚀 LISTO PARA CREAR**
