# Cloudflare Worker: Gromacs Analysis Pipeline

> **Objetivo:** Worker que lee logs de Gromacs → analiza con LLaMA 2 → guarda en R2
> **Status:** En construcción
> **Fecha:** 2026-09-12

---

## 🎯 ARQUITECTURA

```
┌─────────────────────────────────────────────────────┐
│         GROMACS EN CT 901                           │
│  /home/alejandre/GromacsMexicano/Programa_DM_cpp/  │
│              dm.log (output)                        │
└────────────────────┬────────────────────────────────┘
                     │
                     │ (SSH fetch o mount)
                     ↓
┌─────────────────────────────────────────────────────┐
│    CLOUDFLARE WORKER (gromacs-analyzer)             │
│  ┌─────────────────────────────────────────────────┐│
│  │ 1. Fetch log desde CT 901                       ││
│  │ 2. Parsear: Energy, RMSD, Pressure, etc.       ││
│  │ 3. Llamar Workers AI (LLaMA 2)                 ││
│  │    "¿Está convergida? ¿Errores?"              ││
│  │ 4. Guardar análisis en R2                      ││
│  └─────────────────────────────────────────────────┘│
└────────────────────┬────────────────────────────────┘
                     │
                     ↓
        ┌────────────────────────┐
        │   R2 BUCKET            │
        │ /gromacs/2026-09-12/   │
        │ ├── raw/               │
        │ │   └── dm.log         │
        │ └── analysis/          │
        │     └── analysis.json  │
        └────────────────────────┘
```

---

## 📋 ARCHIVOS QUE VAS A NECESITAR

### Paso 1: Crear proyecto Worker
```bash
npm create cloudflare@latest gromacs-analyzer -- --type="hello-world"
cd gromacs-analyzer
```

### Paso 2: Instalar dependencias
```bash
npm install @cloudflare/ai
npm install dotenv
```

### Paso 3: Configurar `wrangler.toml`
```toml
name = "gromacs-analyzer"
main = "src/index.js"
compatibility_date = "2026-09-12"

# KV para almacenar credenciales
kv_namespaces = [
  { binding = "KV", id = "..." }
]

# R2 para guardar logs y análisis
[[r2_buckets]]
binding = "R2_BUCKET"
bucket_name = "gromacs-storage"

# Workers AI
[env.production]
vars = { AI_MODEL = "@cf/meta/llama-2-7b-chat-int8" }

# Tracing (observabilidad)
[observability.traces]
enabled = true
head_sampling_rate = 1
```

### Paso 4: Variables de entorno
```bash
wrangler secret put CT901_HOST  # ej: 192.168.0.230
wrangler secret put CT901_USER  # ej: alejandre
wrangler secret put CT901_SSH_KEY  # contenido de ~/.ssh/id_rsa
```

---

## 💻 CÓDIGO DEL WORKER

### `src/index.js`

```javascript
import { Ai } from '@cloudflare/ai';

export default {
  async fetch(request, env) {
    try {
      // PASO 1: Fetch log desde CT 901
      console.log('📥 Fetching Gromacs log...');
      const logContent = await fetchGromacsMDLog(env);
      
      if (!logContent) {
        return json({ error: 'Log not found' }, 404);
      }

      // PASO 2: Parsear log
      console.log('🔍 Parsing log...');
      const metrics = parseGromacLog(logContent);
      
      // PASO 3: Analizar con LLaMA 2 (Workers AI)
      console.log('🤖 Analyzing with LLaMA 2...');
      const ai = new Ai(env.AI);
      const analysis = await ai.run('@cf/meta/llama-2-7b-chat-int8', {
        prompt: buildAnalysisPrompt(metrics, logContent)
      });

      // PASO 4: Guardar en R2
      console.log('💾 Saving to R2...');
      const timestamp = new Date().toISOString().split('T')[0];
      
      // Guardar log original
      await env.R2_BUCKET.put(
        `gromacs/${timestamp}/raw/dm.log`,
        logContent,
        { httpMetadata: { contentType: 'text/plain' } }
      );

      // Guardar análisis
      const analysisResult = {
        timestamp: new Date().toISOString(),
        metrics,
        llama_analysis: analysis.response,
        status: determineStatus(metrics, analysis.response)
      };

      await env.R2_BUCKET.put(
        `gromacs/${timestamp}/analysis/analysis.json`,
        JSON.stringify(analysisResult, null, 2),
        { httpMetadata: { contentType: 'application/json' } }
      );

      console.log('✅ Analysis complete');
      return json(analysisResult);

    } catch (error) {
      console.error('❌ Error:', error);
      return json({ error: error.message }, 500);
    }
  },

  async scheduled(event, env) {
    // Cron: ejecutar análisis cada 6 horas
    console.log('⏰ Scheduled run started');
    await this.fetch(new Request('http://example.com'), env);
  }
};

// ============= HELPER FUNCTIONS =============

async function fetchGromacsMDLog(env) {
  // TODO: Implementar SSH fetch desde CT 901
  // Opción 1: Via SSH (requiere SSH key)
  // Opción 2: Via HTTP si CT 901 expone endpoint
  // Opción 3: Via Tailscale (si tienes IP Tailscale)
  
  const ct901Host = env.CT901_HOST;
  const logPath = '/home/alejandre/GromacsMexicano/Programa_DM_cpp_v2/dm.log';
  
  try {
    // Usar SSH via Cloudflare Tunnel o ejecutor remoto
    // Por ahora, simular lectura
    return `[SIMULATION] Log from ${logPath}...`;
  } catch (error) {
    console.error('SSH fetch failed:', error);
    return null;
  }
}

function parseGromacLog(logContent) {
  // Extraer métricas del log
  const metrics = {
    atoms: extractValue(logContent, 'Numero de atomos'),
    cellSize: extractValue(logContent, 'lados de la celda'),
    system: extractValue(logContent, 'Sistema'),
    potential: extractValue(logContent, 'Potencial'),
    // TODO: Extraer Energy, RMSD, Pressure del log
  };
  
  return metrics;
}

function extractValue(text, pattern) {
  const regex = new RegExp(`${pattern}\\s*=?\\s*([\\w\\s\\.\\-]+)`, 'i');
  const match = text.match(regex);
  return match ? match[1].trim() : null;
}

function buildAnalysisPrompt(metrics, logContent) {
  return `Eres un experto en dinámica molecular (GROMACS). Analiza este log de simulación:

MÉTRICAS CLAVE:
- Átomos: ${metrics.atoms}
- Tamaño celda: ${metrics.cellSize}
- Sistema: ${metrics.system}
- Potencial: ${metrics.potential}

LOG (primeras 50 líneas):
${logContent.split('\\n').slice(0, 50).join('\\n')}

PREGUNTAS:
1. ¿Está la simulación correctamente configurada?
2. ¿Hay signos de convergencia?
3. ¿Qué errores o advertencias ves?
4. ¿Recomendaciones para optimizar?

Responde en formato JSON: { "status": "OK/WARNING/ERROR", "summary": "...", "issues": [...], "recommendations": [...] }`;
}

function determineStatus(metrics, analysis) {
  // TODO: Parsear respuesta de LLaMA y extraer status
  try {
    const result = JSON.parse(analysis);
    return result.status || 'UNKNOWN';
  } catch {
    return 'UNKNOWN';
  }
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' }
  });
}
```

---

## 🔧 CONFIGURACIÓN R2 (Paso 2)

### Crear bucket en Cloudflare
```bash
wrangler r2 bucket create gromacs-storage
```

### Estructura de datos en R2
```
gromacs-storage/
├── 2026-09-12/
│   ├── raw/
│   │   └── dm.log (log original)
│   └── analysis/
│       └── analysis.json (análisis + LLaMA output)
├── 2026-09-13/
│   ├── raw/
│   │   └── dm.log
│   └── analysis/
│       └── analysis.json
└── index.json (metadata global)
```

---

## 🚀 CONEXIÓN: CT 901 → WORKER (Paso 3)

### Opción A: SSH directo (Recomendado)
```javascript
import { execSync } from 'child_process';

async function fetchGromacsMDLog(env) {
  const key = await env.KV.get('SSH_KEY');
  const host = env.CT901_HOST;
  const user = env.CT901_USER;
  
  const cmd = `ssh -i /tmp/key ${user}@${host} "cat /home/alejandre/GromacsMexicano/Programa_DM_cpp_v2/dm.log"`;
  return execSync(cmd).toString();
}
```

### Opción B: HTTP endpoint en CT 901
```javascript
async function fetchGromacsMDLog(env) {
  const response = await fetch(
    `http://${env.CT901_HOST}:9999/gromacs/log`,
    {
      headers: { 'Authorization': `Bearer ${env.CT901_TOKEN}` }
    }
  );
  return response.text();
}
```

### Opción C: Cloudflare Tunnel (Más seguro)
Usar `cloudflared` en CT 901 para exponer endpoint privado a Cloudflare.

---

## 📊 EJEMPLO DE ANÁLISIS EN R2

```json
{
  "timestamp": "2026-09-12T10:30:45Z",
  "metrics": {
    "atoms": "2544",
    "cellSize": "2.99474",
    "system": "SPC/E water with NaCl",
    "potential": "LJ-ST (truncated)"
  },
  "llama_analysis": {
    "status": "OK",
    "summary": "Simulación bien configurada, convergencia esperada en 10K pasos.",
    "issues": [],
    "recommendations": [
      "Reducir timestep de 1 fs a 0.5 fs para mayor precisión",
      "Verificar presión cada 100 pasos"
    ]
  }
}
```

---

## ⏰ CRON AUTOMÁTICO

Ejecutar análisis cada 6 horas:

```toml
# En wrangler.toml
triggers = { crons = [ "0 */6 * * *" ] }
```

---

## 📝 NEXT STEPS

1. ✅ Crear proyecto Worker (`npm create cloudflare@latest gromacs-analyzer`)
2. ✅ Copiar código a `src/index.js`
3. ✅ Configurar R2 bucket
4. ✅ Implementar SSH fetch desde CT 901
5. ✅ Desplegar: `wrangler deploy`
6. ✅ Probar: `curl https://gromacs-analyzer.<subdomain>.workers.dev`
7. ✅ Ver traces en Cloudflare UI

---

## 💰 COSTO ESTIMADO

| Servicio | Costo/mes | Para ti |
|----------|-----------|---------|
| Workers | $0.50/1M requests | ~$0.05 (2K calls/mes) |
| Workers AI | $0.50/1M tokens | ~$2 (4M tokens/mes) |
| R2 | $0.015/GB | $1.50 (100 GB) |
| **TOTAL** | | **~$3.50/mes** |

---

## 🔐 SEGURIDAD

- SSH keys en `wrangler secret put` (nunca en código)
- R2 es privado por defecto
- Cloudflare Tunnel para CT 901 (sin exponerlo a internet)

**Generado:** SatanZote AI | **Referencia:** Cloudflare Workers + R2 + Workers AI pipeline
