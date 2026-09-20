# OpenWRT

| Campo | Valor |
|-------|-------|
| **Nombre** | OpenWRT |
| **URL** | https://github.com/openwrt/openwrt |
| **Propósito** | Distribución Linux embebida para routers y redes — ofrece WireGuard, QoS, VLANs, firewall avanzado, y control granular de red |
| **Decisión** | Parcialmente |
| **Razón** | Aprobado como **VM de laboratorio en Proxmox** para experimentación con routing, QoS, WireGuard, y segmentación VLAN. NO como router principal del hogar — el hardware actual (módem/ONT + switch administrado) ya cubre el throughput necesario sin single point of failure adicional. La VM 119 (en instalación) permite validar configuraciones de red sin riesgo para la infraestructura productiva. |
| **Casos de Uso** | • Laboratorio de routing avanzado (BGP, OSPF, políticas de tráfico) • Pruebas de QoS y shaping antes de llevar a producción • Segmentación VLAN para aislar entornos (IoT, guest, prod) • Tunnel WireGuard site-to-site • Aprendizaje y certificación de redes |
| **Fecha** | 2026-09-20 |