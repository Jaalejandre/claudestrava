# Skill: Pre-prod tests (validación antes de deploy a prod)

Gate de validación sistemática antes de promover un servicio de **TEST (CT 112)** a **PROD (CT 111)**. Cubre: seguridad, links rotos, health endpoints, dependencias con CVEs, y estado del contenedor.

## Cuándo usar

- El usuario dice "vamos a pasar a prod" o "hay que probar antes de prod"
- Antes de tocar NPM/firewall en CT 111 para exponer un servicio
- El checklist manual del `DEPLOYMENT_PLAN.md` (gate TEST→PROD) pide "validar"

## Prerrequisito

El servicio ya debe correr en **CT 112 (TEST)** accesible en la LAN, p.ej. `http://192.168.0.21:8097`.

## El script

Vive en **CT 112**: `/opt/scripts/pre-prod-tests.sh`. Se corre así:

```bash
# En CT 112 (o al CT que corra el servicio)
bash /opt/scripts/pre-prod-tests.sh http://<IP-test>:<puerto> <minutos_smoke>
```

Ejemplo con airbnb-admin:
```bash
bash /opt/scripts/pre-prod-tests.sh http://192.168.0.21:8097 10
```

## Qué valida (en orden)

### 1. Healthcheck del contenedor
```bash
docker inspect --format '{{.State.Health.Status}}' <container>
# Debe decir: healthy (no starting, no unhealthy)
```
Fallos: si el healthcheck no está definido en el compose → **FALLO** (requisito del estándar).

### 2. Seguridad de headers HTTP
Para `/` y `/health`:
- `X-Content-Type-Options: nosniff` presente
- `X-Frame-Options: DENY` o `SAMEORIGIN` presente (evita clickjacking)
- `Content-Security-Policy` presente (recomendado, warning si falta)
- `Strict-Transport-Security` presente (solo aplica detrás de HTTPS)

### 3. Links rotos (crawler)
- Crawlea todas las rutas `GET` de la app desde la raíz (profundidad 2, límite 50 URLs)
- Marca como **FALLO**: `4xx` (que no sea 404 de ruta legítima), `5xx`, timeouts
- Marca como **WARNING**: links externos que fallan (puede ser firewall/proxy del CT)

### 4. Dependencias del contenedor (CVEs)
Escaneo de la imagen con **Trivy** (si está instalado en el CT):
```bash
trivy image --severity HIGH,CRITICAL --no-progress <imagen>
```
- **FALLO**: vulnerabilidad CRITICAL explotable directamente
- **WARNING**: HIGH con fix disponible, CRITICAL no explotable
- Si Trivy no está: AVISO de que el escaneo no se hizo (no bloquea)

### 5. Puertos y exposición
- Solo debe escuchar el puerto declarado en el compose
- **FALLO**: puertos extra en `ss -tlnp` del contenedor
- Verificar que el contenedor NO corre como root si es posible (`docker inspect | jq '.Config.User'`)

### 6. Smoke test (loop)
Durante `N` minutos, cada 30s:
- `GET /health` → 200 y body `ok`
- `GET /` → 200
- Contador de peticiones fallidas; **FALLO** si > 0

### 7. Logs limpios
```bash
docker logs <container> --since <minutos_smoke>m | grep -iE "error|traceback|exception"
```
- **FALLO**: cualquier `traceback` o `Exception` no manejada
- **WARNING**: errores HTTP esperados (404s legítimos, 401s)

## Salida

El script imprime:
```
📋 PRE-PROD TESTS — <servicio> @ <url>
✅ 1. Healthcheck del contenedor: healthy
✅ 2. Headers de seguridad: 3/4 presentes (CSP falta — WARNING)
❌ 3. Links rotos: /api/foo → 500
⚠️ 4. CVEs: 2 HIGH con fix (recomendado actualizar)
✅ 5. Puertos: solo APP_PORT expuesto
✅ 6. Smoke test: 0 fallos en 10 min
✅ 7. Logs: limpios

RESULTADO: 🔴 NO LISTO PARA PROD (fallos: 1)
```

**Criterio de aprobación**: 0 fallos críticos. Con solo warnings se puede pasar a prod documentando el riesgo. Con 1+ fallo → NO.

## Instalación de Trivy en CT 112 (una vez)

```bash
apt-get install -y wget apt-transport-https gnupg
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" > /etc/apt/sources.list.d/trivy.list
apt-get update && apt-get install -y trivy
```

## Checklist gate TEST→PROD (referencia rápida)

- [ ] `pre-prod-tests.sh` pasa sin fallos críticos
- [ ] 24h de uptime en TEST sin reinicios (`docker inspect --format '{{.RestartCount}}'`)
- [ ] Backup/restore de BD probado (si aplica)
- [ ] `.env.prod` creado en Vaultwarden (distinto de test)
- [ ] NPM: host `app.satanzote.me` → IP:puerto, SSL Let's Encrypt
- [ ] Firewall CT 111: permitir solo CT 100 (NPM)
- [ ] Etiqueta `autoheal=true` en el compose (auto-recovery en prod)
- [ ] Tag de release: `git tag prod-v<semver>`

## Regla de oro

**Si falla en TEST, fallará en PROD.** Nunca promociones con un fallo no resuelto de los puntos 1/3/5/6/7. Los puntos 2/4 (headers/CVEs) admiten warnings documentados.