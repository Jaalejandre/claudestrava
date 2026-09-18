# DEPLOY INSTRUCTIONS — Gromacs Worker

**Status:** Código listo, solo necesita 1 comando para desplegar

## 📍 Ubicación
```
~/JarvisVault/01 Projects/GromacsMexicano/gromacs-analyzer-worker/
```

## 🚀 DESPLEGAR (UN COMANDO)

Cuando tengas acceso a terminal en CT 109:

```bash
cd ~/JarvisVault/01\ Projects/GromacsMexicano/gromacs-analyzer-worker/

wrangler login
```

Esto:
1. Abre navegador
2. Confirmas en Cloudflare
3. Wrangler guarda el token automáticamente

Luego:

```bash
# Crear R2 bucket (si no existe)
wrangler r2 bucket create gromacs-storage || echo "Bucket ya existe"

# Desplegar
wrangler deploy
```

## ✅ Verificar que funciona

```bash
# Ver en Cloudflare Dashboard
# https://dash.cloudflare.com/workers/gromacs-analyzer

# Probar Worker
curl https://gromacs-analyzer.satanzote.workers.dev

# Ver logs en tiempo real
wrangler tail gromacs-analyzer
```

## 📊 Resultado esperado

Worker desplegado en:
```
https://gromacs-analyzer.satanzote.workers.dev
```

Cron automático cada 6 horas:
```
0 */6 * * *
```

Datos en R2:
```
gromacs-storage/
├── raw/2026-09-12/dm.log
└── analysis/2026-09-12/analysis.json
```

## ⚠️ IMPORTANTE: REVOCA EL TOKEN ANTERIOR

Una vez que `wrangler login` funcione:

1. Ve a https://dash.cloudflare.com/profile/api-tokens
2. Haz clic en el token "cfut_929..." 
3. Click "Revoke"

Eso previene que cualquiera con ese token acceda a tu cuenta.

---

**Listo. Solo espera a tener terminal y ejecuta `wrangler login`.**
