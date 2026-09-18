# Gromacs Analyzer — Cloudflare Worker + Workers AI

Análisis automático de simulaciones Gromacs con LLaMA 2, guardando en R2.

## 🚀 Setup Rápido

### 1. Crear R2 Bucket
```bash
wrangler r2 bucket create gromacs-storage
```

### 2. Configurar Secrets
```bash
# SSH key (para conectarse a CT 901)
wrangler secret put CT901_SSH_KEY < ~/.ssh/id_rsa
```

### 3. Desplegar
```bash
wrangler deploy
```

### 4. Probar
```bash
curl https://gromacs-analyzer.satanzote.workers.dev
```

## 📊 Qué hace

1. **Fetch**: Lee log de Gromacs desde CT 901
2. **Parse**: Extrae métricas (Energy, RMSD, Pressure, etc.)
3. **Analyze**: Envía a LLaMA 2 para análisis inteligente
4. **Save**: Guarda log original + análisis en R2
5. **Cron**: Ejecuta automáticamente cada 6 horas

## 📁 Estructura

```
src/index.ts          Worker código principal
wrangler.jsonc        Configuración Cloudflare
package.json          Dependencias
tsconfig.json         TypeScript config
```

## 🔧 Configuración

### Variables (en wrangler.jsonc)
- `CT901_HOST`: 192.168.0.230
- `CT901_USER`: alejandre
- `CT901_LOG_PATH`: /home/alejandre/UAMI_Test
- `AI_MODEL`: @cf/meta/llama-2-7b-chat-int8

### R2 Buckets
- `R2_BUCKET`: gromacs-storage (lee/escribe análisis)

### Triggers (Cron)
- `0 */6 * * *` (cada 6 horas)

## 📝 Output Esperado

Guardado en R2:

```
raw/2026-09-12/dm.log              # Log original
analysis/2026-09-12/analysis.json   # Análisis

# analysis.json contiene:
{
  "timestamp": "2026-09-12T10:30:00Z",
  "metrics": {
    "atoms": "2544",
    "energy": "-2345.6 kcal/mol",
    "rmsd": "0.02 nm",
    "pressure": "1.01 bar",
    "temperature": "298.5 K"
  },
  "llama_analysis": {
    "status": "OK",
    "summary": "Simulación convergida correctamente",
    "recommendations": [
      "Reducir timestep para mayor precisión",
      "Verificar presión cada 100 pasos"
    ]
  }
}
```

## 🔗 Conexión a CT 901

### Opción 1: HTTP Endpoint (recomendado)
Si CT 901 tiene un servidor HTTP exposiendo logs:
```bash
# En CT 901: python -m http.server 9999
# Worker fetch: http://192.168.0.230:9999/gromacs/latest-log
```

### Opción 2: Cloudflare Tunnel (más seguro)
```bash
# En CT 901
cloudflared tunnel create gromacs
cloudflared tunnel run --url http://localhost:9999

# En wrangler.jsonc
# CT901_HOST: https://gromacs.satanzote.workers.dev
```

### Opción 3: SSH (requiere key)
```bash
wrangler secret put CT901_SSH_KEY < ~/.ssh/alejandre.pem
# Ver src/index.ts línea ~100 para implementar
```

## 📊 Ver Resultados

### Via Cloudflare Dashboard
```
Workers → gromacs-analyzer
├── Invocations (ver historial)
├── Logs (stdout del Worker)
└── Traces (timing de cada paso)
```

### Via CLI
```bash
# Listar archivos en R2
wrangler r2 ls gromacs-storage

# Descargar análisis
wrangler r2 download gromacs-storage analysis/2026-09-12/analysis.json ./result.json
```

## 💰 Costos

- **Workers**: $0 (100K requests/día gratis)
- **Workers AI**: $0.36/mes (~120 análisis)
- **R2 Storage**: $0 (primeros 100 GB)
- **R2 Ops**: ~$0.40/mes

**Total**: ~$0.76/mes

## 🔍 Troubleshooting

### R2_BUCKET undefined
```
Error: ReferenceError: R2_BUCKET is not defined
```
→ Verificar `[[r2_buckets]]` en wrangler.jsonc

### Model not found
```
Error: Model @cf/meta/llama-2-7b-chat-int8 not found
```
→ Usar `wrangler models list` para ver modelos disponibles

### CT 901 unreachable
```
Error: fetch failed to 192.168.0.230:9999
```
→ Usar Cloudflare Tunnel o HTTP endpoint

## 📚 Referencias

- [Cloudflare Workers AI](https://developers.cloudflare.com/workers-ai/)
- [Cloudflare R2](https://developers.cloudflare.com/r2/)
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/)
- [Agent Tracing](https://developers.cloudflare.com/agent-setup/tracing/)

---

**Generated**: SatanZote AI | 2026-09-12
