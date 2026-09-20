# Escuadrón OmniRoute: Maintenance & Proxy (`omniroute-*`)
## Operaciones de Tráfico, Proxy y Mantenimiento del Nodo 101

- **Host Maestro**: CT 666 (`satanzote`, `192.168.0.104`)
- **Nodo Trabajador**: CT 101 (`192.168.0.47`)
- **Infraestructura**: OmniRoute Service, Proxy, Nginx-Proxy-Manager.
- **Metodología**: RUDR9 (9 Roles de Operación)
- **Estrategia**: Mantenimiento preventivo, auditoría de logs, optimización de latencia y gestión remota del trabajador 101.

---

## Matriz de Operativos de `OmniRoute Squad`

| # | Operativo | Rol RUDR9 | Misión Específica |
|---|---|---|---|
| 1 | **`omniroute-overlord`** | **Prime OmniRoute CTO** | Conducción estratégica, SLA y asignación de tareas a trabajadores. |
| 2 | **`omniroute-tactician`** | **Traffic Analyst** | Monitoreo de flujo de tokens y carga del proxy. |
| 3 | **`omniroute-construct`** | **Proxy Architect** | Configuración de Nginx, túneles y balanceo. |
| 4 | **`omniroute-forge`** | **Agent Deployer** | Mantenimiento del binario `omniroute` y actualizaciones (NPM). |
| 5 | **`omniroute-icebreaker`** | **Security Sentinel** | Auditoría de tráfico y protección del worker 101. |
| 6 | **`omniroute-overclock`** | **Latency Optimizer** | Optimización de red y tiempos de respuesta. |
| 7 | **`omniroute-inquisitor`** | **Service Auditor** | Auditoría continua del estado de servicio y alertas (`omni_audit.sh`). |
| 8 | **`omniroute-chronicler`** | **Usage Reporter** | Bitácora de tokens y reportes de telemetría en JarvisVault. |
| 9 | **`omniroute-operative`** | **Execution Worker** | Ejecutor en CT 101, gestión de logs locales y tareas pesadas. |

---

## Flujo de Trabajo
1. **Auditoría:** `omniroute-inquisitor` verifica el estado cada hora.
2. **Alertas:** Notificación vía `ntfy` ante caídas.
3. **Reparación:** `omniroute-forge` y `omniroute-operative` ejecutan correcciones automáticas.
