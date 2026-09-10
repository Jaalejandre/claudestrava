---
tipo: deployment-plan
proyecto: miniflux-rss
estado: planificado
actualizado: 2026-09-09
---

# Deployment Plan — Miniflux RSS Reader

## Objetivo
Desplegar **Miniflux** (lector RSS self-hosted) en CT 111 `apps-prod` para leer feeds de IA, tech, noticias mundiales desde móvil (apps Fever/GReader) y web.

---

## 1. Arquitectura objetivo

```
Internet → Cloudflare Tunnel → NPM (CT 100:443) → CT 111:8080 (Miniflux)
                                         └─ news.satanzote.me
```

**Componentes:**
| Componente | Ubicación | Detalle |
|---|---|---|
| Miniflux app | CT 111 (Docker) | `miniflux/miniflux:latest` |
| PostgreSQL | CT 111 (Docker) | `postgres:16-alpine` — BD dedicada `miniflux` |
| Reverse proxy | CT 100 (NPM) | `news.satanzote.me` → `http://192.168.0.21:8080` |
| TLS | Cloudflare + NPM | Automático via Let's Encrypt |
| Firewall | CT 111 | Permitir solo CT 100 (.109) → puerto 8080 |

---

## 2. Recursos en CT 111

| Recurso | Valor |
|---|---|
| CT ID | 111 (`apps-prod`, 192.168.0.21) |
| RAM asignada | 4 GB |
| Disco | 40 GB |
| Docker | Sí (compose v2) |
| Postgres existente | `mundial-db` (puerto 5432 interno) — **NO reusar**, BD aislada |

---

## 3. Plan de pasos

### Fase A — Preparación (infra)
- [ ] Verificar espacio en disco CT 111 (`df -h /opt`)
- [ ] Confirmar puerto 8080 libre en CT 111 (`ss -tlnp | grep 8080`)
- [ ] Crear directorio `/opt/miniflux/` con permisos root:root

### Fase B — Docker Compose
- [ ] Escribir `/opt/miniflux/docker-compose.yml` con:
  - Servicio `miniflux` (puerto 8080, healthcheck)
  - Servicio `db` (PostgreSQL 16-alpine, volume `miniflux_db_data`)
  - Variables: `DATABASE_URL`, `BASE_URL=https://news.satanzote.me`, `CREATE_ADMIN=1`, `ADMIN_USERNAME=admin`, `ADMIN_PASSWORD=<seguro>`
  - `POLLING_SCHEDULER=round_robin` (válido), `POLLING_FREQUENCY=60`
- [ ] Validar sintaxis: `docker compose -f /opt/miniflux/docker-compose.yml config`

### Fase C — Despliegue
- [ ] `cd /opt/miniflux && docker compose up -d`
- [ ] Verificar health: `docker compose ps`, `docker logs miniflux --tail 20`
- [ ] Confirmar migración BD ejecutada (`RUN_MIGRATIONS=1`)

### Fase D — Exposición (NPM + Firewall)
- [ ] En **NPM (CT 100)**: crear `news.satanzote.me` → `http://192.168.0.21:8080`, SSL Let's Encrypt, force HTTPS
- [ ] En **CT 111 firewall** (iptables/ufw): permitir `192.168.0.109` (CT 100) → puerto 8080
- [ ] Probar acceso: `curl -I https://news.satanzote.me` → 200/302

### Fase E — Configuración post-deploy
- [ ] Login en `https://news.satanzote.me` con `admin` / password del compose
- [ ] Cambiar password admin vía UI
- [ ] Configurar categorías: `IA`, `Tech`, `Noticias`, `Mundo`
- [ ] Importar OPML (si hay) o agregar feeds manuales
- [ ] Probar API Fever: `https://news.satanzote.me/fever/` con credenciales

### Fase E — Móvil
- [ ] Instalar **ReadYou** (Android) / **NetNewsWire** (iOS)
- [ ] Agregar cuenta: tipo Fever, URL `https://news.satanzote.me`, user `admin`, pass
- [ ] Verificar sync y lectura offline

### Fase F — Documentación
- [ ] Actualizar `00 Notes/Servidor Proxmox/Arquitectura/CT 111 apps-prod.md` con Miniflux
- [ ] Registrar credenciales en Vaultwarden (entry: `miniflux-admin`)
- [ ] Agregar nota en `03 Projects/Infraestructura/` si aplica

---

## 4. Variables sensibles (guardar en Vaultwarden)

| Variable | Valor | Dónde |
|---|---|---|
| `ADMIN_PASSWORD` | `<generar seguro 16+ chars>` | compose + Vaultwarden |
| `POSTGRES_PASSWORD` | `<generar seguro 16+ chars>` | compose + Vaultwarden |
| `DATABASE_URL` | `postgres://miniflux:<pass>@db/miniflux?sslmode=disable` | compose |

---

## 5. Rollback

Si algo falla:
```bash
# En CT 111
cd /opt/miniflux && docker compose down -v
rm -rf /opt/miniflux
# En NPM: desactivar/borrar proxy host news.satanzote.me
# En firewall CT 111: borrar regla 8080
```

---

## 6. Criterios de aceptación

- [ ] `https://news.satanzote.me` carga UI de Miniflux con HTTPS válido
- [ ] Login `admin` funciona
- [ ] Sync con **ReadYou** / **NetNewsWire** OK
- [ ] Feeds de prueba (ej. `https://hnrss.org/newest`, `https://www.artificialintelligence-news.com/feed/`) aparecen y actualizan
- [ ] No hay errores en logs (`docker logs miniflux --tail 50`)
- [ ] Backup de BD incluido en rutina de CT 111 (rclone)

---

## 7. Próximos pasos

1. Revisar y aprobar este plan
2. Generar passwords seguros y guardarlos en Vaultwarden
3. Ejecutar Fase A → F en orden
4. Validar criterios de aceptación

---

**Notas:**
- CT 111 ya tiene Postgres para `mundial` — **no reusar esa BD**; Miniflux tiene su propia instancia `postgres:16-alpine` aislada (más limpio, evita migraciones cruzadas).
- Puerto 8080 en CT 111 **no está usado** actualmente (verificado en barrido 2026-09-08).
- Cloudflare Tunnel ya cubre `*.satanzote.me` — solo agregar host en NPM.