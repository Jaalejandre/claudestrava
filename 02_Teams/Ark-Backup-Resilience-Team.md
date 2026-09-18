# Escuadrón RUDR9: The Data Ark (`ark-*`)
## Resiliencia de Datos, Backups Multi-Cloud & Disaster Recovery

- **Host Maestro**: CT 666 (`satanzote`, `192.168.0.104`)
- **Nodos de Almacenamiento**: Proxmox Storage (`/mnt/backups`), Backblaze B2 (`PVE-BackupSatanzote`), Cloudflare R2, GitHub, Vaultwarden.
- **Metodología**: RUDR9 Estricto (9 Roles Cyberpunk)
- **Estrategia**: Regla 3-2-1 de Respaldos (3 copias, 2 medios distintos, 1 offsite inmutable).

---

## Matriz de Operativos de `The Data Ark`

| # | Operativo | Rol RUDR9 | Misión Específica |
|---|---|---|---|
| 1 | **`ark-overlord`** | **Prime Backup CTO** | Conducción estratégica de la política 3-2-1, control de RPO/RTO y asignación de tareas. |
| 2 | **`ark-tactician`** | **Retention & Policy Planner** | Diseño de esquemas de retención GFS (diario/semanal/mensual) y presupuestos de disco. |
| 3 | **`ark-construct`** | **Storage Architect** | Topología de replicación cloud, buckets de Backblaze B2, R2 y arquitectura de cifrado. |
| 4 | **`ark-forge`** | **Snapshot Builder** | Desarrollo de scripts para `vzdump`, hot-backups de SQLite y sincronizaciones a B2. |
| 5 | **`ark-icebreaker`** | **Encryption Sentinel** | Cifrado AES-256 de volcados, verificación de hashes SHA-256 e inmutabilidad (Object Lock). |
| 6 | **`ark-overclock`** | **Compression Engine** | Optimización de compresión zstd/lz4, paralelización de subidas a B2 y control de ancho de banda. |
| 7 | **`ark-inquisitor`** | **DR Gatekeeper** | Simulacros de restauración en frío, validación de integridad y auditoría de recuperabilidad. |
| 8 | **`ark-chronicler`** | **Catalog Archivist** | Manifiestos de respaldos, inventario de snapshots y bitácora en `JarvisVault`. |
| 9 | **`ark-operative`** | **Snapshot Worker** | Ejecutor de tareas pesadas, rotación de archivos temporales y depuración de volcados expirados. |

---

## Flujo de Respaldo Automatizado

```
[Datos / Contenedores Proxmox]
         │
         ▼
1. ark-forge (Genera vzdump / sqlite backup comprimido en zstd)
         │
         ▼
2. ark-icebreaker (Calcula SHA-256 y firma con clave de cifrado)
         │
         ▼
3. ark-overclock (Sube en paralelo vía backblaze-mcp a B2 / R2)
         │
         ▼
4. ark-inquisitor (Verifica tamaño y checksum en el bucket remoto)
         │
         ▼
5. ark-chronicler (Registra snapshot ID en el manifiesto de JarvisVault)
```
