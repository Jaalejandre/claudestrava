# Escuadrones BELSEBU Oficiales de Satanzote

| Escuadrón | Dominio Principal | Overlord (CTO) | Host / Nodo de Cómputo |
|---|---|---|---|
| **Squad 1: Satanzote** | Core Infra, Proxmox & Redes | `satanzote-overlord` | CT 666 (`satanzote`, `192.168.0.104`) |
| **Squad 2: Daemon** | HPC, CUDA & Dinámica Molecular | `daemon-overlord` | CT 901 (`192.168.0.52`) |
| **Squad 3: Sentinel** | SRE, Auditoría Continua & Tokens | `sentinel-overlord` | CT 666 (`satanzote`) |

---

## Estructura de Roles Cyberpunk por Escuadrón

Cada escuadrón cuenta con la matriz de 9 roles especializados:

1. **`*-overlord`** (Prime Orchestrator / CTO): Conducción global y gates.
2. **`*-tactician`** (Planner): Descomposición y especificaciones.
3. **`*-construct`** (Architect): Topología, diseño y arquitectura de memoria/red.
4. **`*-forge`** (Builder): Implementación de código y despliegues.
5. **`*-icebreaker`** (Security): Hardening, Vaultwarden y zero-trust.
6. **`*-overclock`** (Performance): Benchmarks, telemetría GPU y optimización de tokens.
7. **`*-inquisitor`** (Reviewer): QA pre-producción y validación de paridad.
8. **`*-chronicler`** (VCM): Git, backups a R2/B2 y documentación.
9. **`*-operative`** (Worker): Ejecución pesada, cronjobs y mantenimiento.
