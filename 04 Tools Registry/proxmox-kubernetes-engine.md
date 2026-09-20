# Proxmox-Kubernetes-Engine (PKE)

| Campo | Valor |
|-------|-------|
| **Nombre** | Proxmox-Kubernetes-Engine |
| **URL** | https://github.com/Caprox-eu/Proxmox-Kubernetes-Engine |
| **Propósito** | Orquestación de Kubernetes sobre Proxmox VE — automatiza creación de clusters K8s multi-host usando VMs/LXCs provisionados desde PVE |
| **Decisión** | No |
| **Razón** | **Descartado.** PKE requiere un mínimo de 6-8 GB de overhead por nodo (OS + kubelet + containers runtime + workloads), y está diseñado para entornos multi-host (múltiples nodos Proxmox). En nuestro setup single-host (pve.local, i5-14600K, 31GB RAM), el overhead es prohibitivo — consumiría ~20-25GB para un cluster de 3 nods, dejando apenas 6GB para workloads reales. Además, el proyecto es relativamente joven (Caprox-eu, comunidad pequeña), lo que añade riesgo de mantenimiento. No hay necesidad actual de orquestación K8s en el ecosistema SatanZote. |
| **Casos de Uso** | • Entornos multi-host con recursos dedicados • Despliegues que requieren auto-scaling K8s nativo • Equipos que ya usan Proxmox y quieren K8s sin infra separada • Laboratorio de certificación CKA/CKAD |
| **Fecha** | 2026-09-20 |