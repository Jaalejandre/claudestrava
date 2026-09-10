---
tipo: deployment-plan
proyecto: deployment-pipeline-dev-test-prod
estado: planificado
actualizado: 2026-09-09
---

# Deployment Pipeline — Dev → Test → Prod

## Visión general

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   CT 109        │     │   CT 112        │     │   CT 111        │
│   claude-dev    │────▶│   app-dev       │────▶│   apps-prod     │
│   (prototype)   │     │   (test)        │     │   (production)  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
      │                       │                       │
      ▼                       ▼                       ▼
  Código suelto         Docker Compose          Docker Compose
  (harness, scripts)    idéntico a prod         idéntico a test
                        Puerto local              Cloudflare + NPM
                        Solo LAN                  Dominio público
```

**Principio rector**: **Mismo `docker-compose.yml` en los 3 entornos** — solo cambia el `.env` y el tag de imagen.

---

## 1. Definición de entornos

| Aspecto | **DEV** (CT 109) | **TEST** (CT 112) | **PROD** (CT 111) |
|---|---|---|---|
| **Propósito** | Prototipado rápido, harness local | Validación completa, red local | Servicio vivo, público |
| **Infra** | Procesos systemd / harness Python | Docker Compose | Docker Compose |
| **Red** | Localhost + Samba | LAN (192.168.0.0/24) | Internet via Cloudflare |
| **Dominio** | `localhost:xxxx` | `app.test.local` o IP:port | `app.satanzote.me` |
| **Datos** | Mock / temp | Subset real / anonimizado | Reales |
| **Secrets** | `.env.local` (no commiteado) | `.env.test` (Vaultwarden) | `.env.prod` (Vaultwarden) |
| **Recursos** | Sin límites | Límites suaves | Límites duros + reservations |
| **Reinicio** | Manual | `unless-stopped` | `unless-stopped` + healthcheck |
| **Logs** | stdout / archivo local | Docker logs + Loki (futuro) | Docker logs + Loki (futuro) |

---

## 2. Estándar de despliegue — Docker Compose

### 2.1 Estructura de repositorio por servicio

```
/project/<servicio>/
├── docker-compose.yml          # ÚNICO compose (source of truth)
├── Dockerfile                  # Si build propio
├── .env.example                # Template sin secretos
├── .env.dev                    # Solo en CT 109 (gitignored)
├── .env.test                   # En Vaultwarden → CT 112
├── .env.prod                   # En Vaultwarden → CT 111
├── healthcheck.sh              # Script de validación post-deploy
└── README.md                   # Cómo deployar, puertos, deps
```

### 2.2 Reglas del compose

| Regla | Por qué |
|---|---|
| **Un solo `docker-compose.yml`** por servicio | Evita drift entre entornos |
| **Variables en `.env`** (nunca hardcodeadas) | Promoción = copiar `.env` |
| **Healthcheck obligatorio** en cada servicio | Portainer/Docker saben si está vivo |
| **`restart: unless-stopped`** siempre | Auto-recovery tras reboot/crash |
| **Límites de recursos** en prod (`deploy.resources`) | No un servicio tira otro |
| **Networks nombradas** (`frontend`, `backend`) | Aislamiento y DNS interno |
| **Volumes nombrados** (no bind mounts en prod) | Portabilidad, backups |

### 2.3 Template base `docker-compose.yml`

```yaml
version: "3.8"

services:
  app:
    image: ${IMAGE_TAG:-local/app:latest}
    build:
      context: .
      dockerfile: Dockerfile
    container_name: ${COMPOSE_PROJECT_NAME}-app
    restart: unless-stopped
    environment:
      - NODE_ENV=${NODE_ENV:-production}
      # ... otras vars desde .env
    ports:
      - "${APP_PORT:-8080}:8080"
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    deploy:
      resources:
        limits:
          cpus: '${CPU_LIMIT:-1.0}'
          memory: '${MEM_LIMIT:-512M}'
        reservations:
          cpus: '${CPU_RESERV:-0.25}'
          memory: '${MEM_RESERV:-128M}'
    networks:
      - frontend
      - backend
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    container_name: ${COMPOSE_PROJECT_NAME}-db
    restart: unless-stopped
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - ${COMPOSE_PROJECT_NAME}_db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend
    deploy:
      resources:
        limits:
          memory: '${DB_MEM_LIMIT:-256M}'

  redis:
    image: redis:7-alpine
    container_name: ${COMPOSE_PROJECT_NAME}-redis
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
    networks:
      - backend
    deploy:
      resources:
        limits:
          memory: '${REDIS_MEM_LIMIT:-64M}'

networks:
  frontend:
    name: ${COMPOSE_PROJECT_NAME}_frontend
  backend:
    name: ${COMPOSE_PROJECT_NAME}_backend
    internal: true

volumes:
  ${COMPOSE_PROJECT_NAME}_db_data:
    name: ${COMPOSE_PROJECT_NAME}_db_data
```

---

## 3. Gates de promoción

### DEV → TEST (CT 109 → CT 112)

| Criterio | Validación |
|---|---|
| ✅ Código compila / build pasa | `docker compose build` sin errores |
| ✅ Tests unitarios pasan | `pytest` / `npm test` / `go test` |
| ✅ Healthcheck responde | `curl localhost:port/health` → 200 |
| ✅ Migración BD aplica limpia | `RUN_MIGRATIONS=1` sin error |
| ✅ Smoke test manual | Flujo crítico funciona (login, action, logout) |
| ✅ `.env.test` existe en Vaultwarden | Credenciales de test listas |

**Acción**: `git tag test-<fecha>` + copiar `.env.test` a CT 112 + `docker compose up -d`

### TEST → PROD (CT 112 → CT 111)

| Criterio | Validación |
|---|---|
| ✅ TEST verde 24h sin crashes | `docker compose ps` todo `Up (healthy)` |
| ✅ Carga realista superada | `hey -n 1000 -c 10 http://app.test.local/health` < 200ms p95 |
| ✅ Logs limpios (sin ERROR/WARN críticos) | `docker logs app --since 24h \| grep -iE "error|fatal" \| wc -l` = 0 |
| ✅ Backup/restore probado | `pg_dump` → restore en BD limpia OK |
| ✅ Rollback probado | `docker compose down && docker compose up -d` recupera estado |
| ✅ `.env.prod` en Vaultwarden | Credenciales prod distinctas de test |
| ✅ Dominio configurado en NPM | `app.satanzote.me` → CT 111:puerto |
| ✅ Firewall CT 111 permite solo CT 100 | `iptables -A INPUT -s 192.168.0.109 -p tcp --dport XXXX -j ACCEPT` |

**Acción**: `git tag prod-v<semver>` + copiar `.env.prod` a CT 111 + `docker compose up -d` + validar DNS/SSL

---

## 4. Observabilidad y Auto-healing (Portainer + Watchdog)

### 4.1 Portainer (ya en CT 107)

| Función | Configuración |
|---|---|
| **Agentes** | `portainer-agent` en CT 111 (puerto 9001) y CT 112 (puerto 9001) |
| **Monitoreo** | Containers status, CPU/RAM, logs, restart count |
| **Alertas** | Portainer Business (opcional) o webhook a ntfy/Telegram |
| **Acceso** | `portainer.satanzote.me` via NPM → CT 107:9443 |

### 4.2 Auto-restart nativo (Docker) — **suficiente para v1**

```yaml
# En TODOS los servicios del compose
restart: unless-stopped

# Healthcheck obligatorio (ejemplo)
healthcheck:
  test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 15s
```

**Docker hace**: si healthcheck falla 3 veces → `unhealthy` → **no reinicia solo** (eso es `restart: on-failure` que NO usamos). Para auto-restart real en unhealthy:

```yaml
# Opción A: restart policy extendido (Docker 24+)
restart: on-failure:5  # reintenta 5 veces si exit code != 0

# Opción B: watchdog externo (recomendado para prod) — ver 4.3
```

### 4.3 Watchdog externo — **auto-healing real** (para prod)

**`autoheal`** — contenedor ligero que reinicia contenedores `unhealthy`:

```yaml
# Añadir al compose de PROD (CT 111)
  autoheal:
    image: willfarrell/autoheal:latest
    container_name: autoheal
    restart: unless-stopped
    environment:
      - AUTOHEAL_CONTAINER_LABEL=all
      - AUTOHEAL_START_PERIOD=60
      - AUTOHEAL_INTERVAL=30
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    network_mode: none
```

**Etiqueta en cada servicio a vigilar**:
```yaml
labels:
  - "autoheal=true"
```

### 4.4 Stack de monitoreo mínimo (futuro v2)

| Herramienta | Qué hace | Dónde |
|---|---|---|
| **cAdvisor** | Métricas contenedores (CPU, RAM, red, disco) | CT 111 sidecar |
| **Prometheus** | Scrape + almacenamiento métricas | CT 111 o dedicado |
| **Grafana** | Dashboards + alertas | CT 111 o dedicado |
| **Alertmanager** | Ruteo alertas → ntfy/Telegram | CT 111 |

---

## 5. Secrets Management

| Entorno | Dónde viven los `.env` | Cómo se despliegan |
|---|---|---|
| **DEV** | `/project/<app>/.env.dev` (local, gitignored) | Manual / harness |
| **TEST** | Vaultwarden → entrada `app-test-env` | `bw get notes app-test-env > .env.test` |
| **PROD** | Vaultwarden → entrada `app-prod-env` | `bw get notes app-prod-env > .env.prod` |

**Regla**: **NUNCA** commitear `.env.*` reales. Solo `.env.example` en repo.

---

## 6. Rollback Procedure

### Rollback en TEST (CT 112)
```bash
cd /opt/<app>
docker compose down
git checkout <tag-anterior>
docker compose up -d
# Validar healthcheck
```

### Rollback en PROD (CT 111) — **zero-downtime si posible**
```bash
# 1. Tag actual
CURRENT=$(git describe --tags --abbrev=0)

# 2. Desplegar versión anterior en paralelo (puerto distinto)
#    O blue/green si el compose lo soporta

# 3. Si no hay blue/green: rollback rápido
cd /opt/<app>
docker compose down
git checkout <tag-anterior>
docker compose up -d

# 4. Validar
curl -f https://app.satanzote.me/health
# 5. Notificar (ntfy/Telegram)
```

---

## 7. Checklist de Deployment por Release

### Pre-deploy (en DEV)
- [ ] `docker compose build` OK
- [ ] Tests pasan
- [ ] `docker compose config` valida sintaxis
- [ ] `.env.example` actualizado
- [ ] `CHANGELOG.md` actualizado
- [ ] Tag `dev-<fecha>` creado

### Deploy a TEST
- [ ] `.env.test` en Vaultwarden
- [ ] `git pull` en CT 112
- [ ] `cp .env.test .env` en CT 112
- [ ] `docker compose up -d --build`
- [ ] `docker compose ps` → todo `healthy`
- [ ] Smoke test automatizado (`healthcheck.sh`)
- [ ] Logs limpios 10 min
- [ ] Tag `test-<fecha>` creado

### Deploy a PROD
- [ ] TEST verde ≥ 24h
- [ ] `.env.prod` en Vaultwarden
- [ ] `git pull` en CT 111
- [ ] `cp .env.prod .env` en CT 111
- [ ] `docker compose up -d --build` (o blue/green)
- [ ] `docker compose ps` → todo `healthy`
- [ ] `curl -f https://app.satanzote.me/health`
- [ ] NPM + SSL OK
- [ ] Firewall CT 111 verificado
- [ ] Autoheal corriendo
- [ ] Tag `prod-v<semver>` creado
- [ ] Notificación deploy (ntfy/Telegram)
- [ ] Rollback probado en staging (opcional)

---

## 8. Métricas de Salud (SLOs)

| Métrica | Target TEST | Target PROD |
|---|---|---|
| Uptime | 99% | 99.9% |
| Latencia p95 /health | < 200ms | < 100ms |
| Error rate | < 1% | < 0.1% |
| Tiempo deploy | < 10 min | < 5 min (con blue/green) |
| Tiempo rollback | < 5 min | < 3 min |
| MTTR (mean time to recover) | < 30 min | < 15 min |

---

## 9. Próximos pasos inmediatos

1. **Aprobar este plan** — ajustar umbrales, nombres, puertos
2. **Crear template base** en `/project/_template/` con compose + `.env.example` + `healthcheck.sh`
3. **Piloto**: aplicar a `airbnb-admin` (ya vive en CT 109, pasar a 112 → 111)
4. **Configurar Portainer agents** en CT 111/112 (ya instalados, solo verificar)
5. **Deployar autoheal** en CT 111 (prod)
6. **Documentar** en `00 Notes/Servidor Proxmox/Arquitectura/Deployment-Pipeline.md`

## 9b. Estado del piloto (2026-09-09)

| Paso | Estado | Detalle |
|---|---|---|
| Template base | ✅ | `/project/_template/` con compose + `.env.example` + `healthcheck.sh` |
| airbnb-admin → TEST (CT 112) | ✅ | Corriendo en `:8097`, health OK, root 200 |
| Fix AppArmor build CT 109 | ✅ | Build en CT 112 (sin apparmor); CT 109 requiere legacy builder |
| Fix starlette TemplateResponse | ✅ | 9 llamadas migradas a API nueva (request, name, context) |
| autoheal CT 111 | ✅ | `willfarrell/autoheal` healthy, label `autoheal=true` |
| Portainer agents | ✅ | CT 111 y CT 112 agentes Up 5 días |
| airbnb-admin → PROD (CT 111) | ⏳ | Pendiente — esperar 24h TEST verde + `.env.prod` + NPM + firewall |

**Lecciones del piloto:**
- **AppArmor** rompe builds de Docker dentro de CT 109 (LXC unprivileged) → construir en CT 112/111
- **Starlette 1.6** rompió `TemplateResponse(name, ctx)` → migrar a `TemplateResponse(request, name, ctx)`
- La imagen se construye en el CT destino (mismo Dockerfile, sin registry)

---

## 10. Referencias

- [[(C) Mapa del servidor pve]] — IPs, puertos, CTs
- [[(C) Tecnologías y proyectos por contenedor]] — qué corre dónde
- [[05 Skills/new-dev-project.md]] — para proyectos de código nuevo
- [[03 Projects/Infraestructura/Miniflux-RSS/DEPLOYMENT_PLAN.md]] — ejemplo aplicado