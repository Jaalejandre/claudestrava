# Cloudflare Setup — Guía Rápida

> **Completado:** 2026-09-12 09:30 CDMX
> **Status:** ✅ Skills + MCP instalados | ⏳ Credentials pendientes | ⏳ Hermes reinicio pendiente

---

## ✅ QUÉ SE HIZO

### 1. Skills Cloudflare Instaladas
```
~/.hermes/skills/
├── cloudflare/ (SKILL.md + references)
├── cloudflare-email-service/
├── cloudflare-one/
└── cloudflare-one-migrations/
```

**Total:** 14 skills Cloudflare + 5 symlinks hacia Hermes

### 2. MCP Servers Configurados
```yaml
# ~/.hermes/config.yaml
mcp:
  servers:
    - name: cloudflare
      url: https://mcp.cloudflare.com/mcp
    - name: cloudflare-docs
      url: https://docs.mcp.cloudflare.com/mcp
    - name: cloudflare-bindings
      url: https://bindings.mcp.cloudflare.com/mcp
    - name: cloudflare-builds
      url: https://builds.mcp.cloudflare.com/mcp
    - name: cloudflare-observability
      url: https://observability.mcp.cloudflare.com/mcp
```

### 3. Config File Creado
```json
# ~/.cloudflare/config.json
{
  "account_id": "",
  "api_token": "",
  "email": "",
  "api_key": "",
  "status": "pending_oauth"
}
```

---

## ⏳ PASOS PENDIENTES

### PASO 1: Reiniciar Hermes
**Desde una terminal FUERA de Hermes:**
```bash
hermes gateway restart
```

O manualmente:
```bash
systemctl restart hermes-gateway
```

**Qué hace:** Carga los 5 MCP servers nuevos en memoria

### PASO 2: Configurar Credentials Cloudflare
1. Ir a: https://dash.cloudflare.com/
2. Crear cuenta (si no tienes)
3. Generar API Token:
   - Profile (esquina superior derecha) → API Tokens
   - Click "Create Token"
   - Permisos recomendados:
     - Account.Workers
     - Account.Workers KV
     - Account.Workers Routes
     - Account.Cloudflare Pages
     - Zone.Workers Scripts
   - Crear y copiar token
4. Guardar en `~/.cloudflare/config.json`:
```bash
cat > ~/.cloudflare/config.json << EOF
{
  "api_token": "tu_token_de_cloudflare_aqui",
  "account_id": "tu_account_id_de_cloudflare"
}
EOF
```

**Account ID:** Se ve en https://dash.cloudflare.com/ (lado izquierdo, debajo del nombre)

### PASO 3: Usar Skills (Automático)
En la siguiente sesión de Hermes, los skills estarán disponibles:
- Deploy a Cloudflare Workers
- Manage Cloudflare KV
- Deploy a Cloudflare Pages
- etc.

---

## 🎯 QUÉ PUEDES HACER DESPUÉS

### Con Cloudflare Skills:
```
→ "Crea un Worker Node.js que lea datos de KV"
→ "Deploy mi Next.js app a Cloudflare Pages"
→ "Configura un Durable Object para coordinar estado"
→ "Genera un script de migración para Cloudflare ONE"
```

### Casos de Uso Relevantes para Ti:
- **Desplegar Prototipos** (airbnb-admin, etc.) en Cloudflare Pages
- **API Backends** (Entrenador L'Étape, ConfirmaCitas) en Workers
- **KV Store** para cachés, sesiones, datos de entrenamiento
- **Cron Triggers** para sincronización automática (Strava, etc.)

---

## 📍 ARCHIVOS CRÍTICOS

| Archivo | Propósito | Acción |
|---------|-----------|--------|
| `~/.hermes/config.yaml` | Config de Hermes + MCP | ✅ Configurado |
| `~/.cloudflare/config.json` | Credentials | ⏳ Espera tokens |
| `~/.agents/skills/cloudflare/` | Skills ejecutables | ✅ Instalado |

---

## 🔄 CÓMO VERIFICAR STATUS

```bash
# Ver skills instaladas
ls -la ~/.hermes/skills/cloudflare*

# Ver MCP servers en config
grep -A 20 'mcp:' ~/.hermes/config.yaml

# Ver credentials (cuando esté configurado)
cat ~/.cloudflare/config.json
```

---

## ⚠️ TROUBLESHOOTING

**Si MCP servers no carga:**
```bash
# Reiniciar Hermes desde terminal externa
hermes gateway restart

# Verificar logs
systemctl status hermes-gateway
journalctl -u hermes-gateway -n 50
```

**Si OAuth falla en primer uso:**
- Verificar que `~/.cloudflare/config.json` tenga tokens válidos
- Regenerar token en https://dash.cloudflare.com/profile/api-tokens
- Revisar permisos del token

**Si Skills no aparecen:**
```bash
# Recargar skills manualmente
skills list | grep cloudflare
```

---

## 📋 RESUMEN PARA LA PRÓXIMA SESIÓN

1. ✅ Skills instaladas → no requiere acción
2. ✅ MCP configurado → no requiere acción
3. ⏳ **Reiniciar Hermes** → `hermes gateway restart` (desde fuera)
4. ⏳ **Agregar Cloudflare token** → `~/.cloudflare/config.json`
5. ✅ Usar skills → automático (próxima sesión)

---

**Generado:** SatanZote AI | **Referencia oficial:** https://developers.cloudflare.com/agent-setup/prompt.md | **Última actualización:** 2026-09-12 09:30 CDMX
