# K3s (Lightweight Kubernetes)

| Campo | Valor |
|-------|-------|
| **Nombre** | K3s |
| **URL** | https://github.com/k3s-io/k3s |
| **Propósito** | Kubernetes certificado y ligero (~60MB binary) para entornos edge/ARM/recursos limitados |
| **Decisión** | No (por ahora) |
| **Razón** | **Pospuesto.** Aunque K3s es significativamente más ligero que PKE (~3GB overhead vs 6-8GB), el análisis de recursos mostró que: (1) el swap del host CT 109 está al 90%, (2) las GPUs (RTX 5070 Ti y RTX A5000) requieren rework significativo (NVIDIA Container Toolkit + device plugins) para funcionar con K3s, (3) overhead de ~3GB en un sistema con 31GB RAM total donde ya conviven múltiples servicios es ajustado. La decisión es **reconsiderar cuando haya un segundo host dedicado** — ahí K3s tendría sentido como capa de orquestación ligera para despliegues containerizados. Por ahora, los workloads corren nativos en LXCs, que es más eficiente en recursos y más simple de mantener. |
| **Casos de Uso** | • Orquestación ligera multi-host • Edge computing / IoT • CI/CD auto-escalable con runners containerizados • Aislar servicios en namespaces sin overhead de VMs • Laboratorio K8s para aprendizaje |
| **Fecha** | 2026-09-20 |