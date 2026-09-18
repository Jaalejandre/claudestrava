# Escuadrón BELSEBU: NetRunner (`net-*`)
## Arquitectura de Red, Mapeo de Infraestructura & Estabilidad DHCP/DNS

- **Host Maestro**: CT 666 (`satanzote`, `192.168.0.104`)
- **DNS Primario**: AdGuard Home (`192.168.0.10:53`, CT 104)
- **DNS Recursivo**: Unbound (`192.168.0.11:5335`, CT 105)
- **Túnel WAN**: Cloudflared (`192.168.0.12`, CT 108)
- **Reverse Proxy**: Nginx Proxy Manager (`192.168.0.109`, CT 100)
- **Metodología**: BELSEBU (9 Roles Especializados)

---

### Misión
1. **Mapeo Activo y Topología**: Monitorear los hosts y contenedores de la subred `192.168.0.0/24`.
2. **Estabilidad DHCP y Reservas**: Evitar colisiones de IP en Proxmox y garantizar que cada servicio crítico conserve su IP asignada.
3. **Auditoría DNS**: Validar que las resoluciones locales y globales fluyan limpiamente vía `AdGuard -> Unbound -> Internet`.
4. **Seguridad Perimetral**: Monitorear el túnel Zero-Trust y los proxies de entrada.

---

### Matriz de Roles (Metodología BELSEBU)

| # | Operativo | Rol BELSEBU | Misión Específica |
| :--- | :--- | :--- | :--- |
| 1 | **`net-overlord`** | **Chief Network Architect** | Estrategia integral de ruteo, segmentación de subred y orquestación LAN. |
| 2 | **`net-tactician`** | **IP Allocation Planner** | Planeación de rangos DHCP vs estáticos y prevención de colisiones. |
| 3 | **`net-construct`** | **DNS/DHCP Engineer** | Gestión y configuración de AdGuard Home (CT 104) y Unbound (CT 105). |
| 4 | **`net-forge`** | **Firewall & Routing Builder** | Reglas iptables, políticas de forward y rutas estáticas. |
| 5 | **`net-icebreaker`** | **Network Security Sentinel** | Escaneo de puertos no autorizados y validación de certificados TLS. |
| 6 | **`net-overclock`** | **Latency & Throughput Engine** | Optimización de tiempos de respuesta DNS y latencia entre nodos. |
| 7 | **`net-inquisitor`** | **Network QA Inspector** | Pruebas de resolución DNS, pérdida de paquetes y chequeo de gateways. |
| 8 | **`net-chronicler`** | **Topology Archivist** | Mantenimiento del documento `00_System/Network-Topology-Map.md`. |
| 9 | **`net-operative`** | **Discovery Worker** | Ejecución periódica del script de mapeo `/root/scripts/network_scanner.py`. |

---

### Automatización
- **Script de Escaneo**: `/root/scripts/network_scanner.py`
- **Crontab**: Ejecución automática cada hora para mantener la topología en tiempo real.
