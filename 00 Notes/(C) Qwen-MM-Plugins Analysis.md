# Qwen-MM-Plugins: Native Multimodal Agent Capabilities
## ⚡ ANÁLISIS RÁPIDO PARA JOSÉ

### REPOSITORIO OVERVIEW
**QwenLM/Qwen-MM-Plugins** (2.1K ⭐, MIT license)

**Tagline:** "Make any agent harness multimodal-native"
**Propósito:** Plugin marketplace para agentes LLM → agregar capacidades multimodales (imagen, video, audio, documentos)

### ARQUITECTURA
```
┌──────────────────────────────────────────────────────────────┐
│              MULTIMODAL PLUGIN ARCHITECTURE                  │
└──────────────────────────────────────────────────────────────┘

Instalador Universal (install.sh)
  ↓
Soporta múltiples harnesses:
  ├─ Claude Code (native)
  ├─ Hermes Agent (manual setup)
  ├─ OpenCode
  ├─ Gemini CLI
  └─ Qwen Code / DeepSeek Harness

Cada plugin = Skill + optional MCP server
  ├─ core (imagen, video, archivos nativo)
  ├─ api (integración APIs externas)
  ├─ search (búsqueda web)
  ├─ video-edit (editar videos)
  ├─ blender (3D automation)
  ├─ freecad (CAD automation)
  ├─ video-memory (recordar vídeos)
  └─ omni-* (multimodal workflows)

Instalación: curl | bash → ~/.qwen-mm-plugins/config
```

### PLUGINS DISPONIBLES

| Plugin | Tipo | ROI | Estado |
|--------|------|-----|--------|
| **core** | Multimodal nativo | 🟢 ALTO | Essential |
| **api** | Integración APIs | 🟡 MEDIO | Útil |
| **search** | Web search | 🟡 MEDIO | Similar a Memento |
| **video-edit** | Video manipulation | 🟠 BAJO | Specialized |
| **video-memory** | Video recall | 🟡 MEDIO | Interesante |
| **blender** | 3D automation | 🔴 N/A | Para 3D solo |
| **freecad** | CAD design | 🔴 N/A | Para CAD solo |
| **omni-chatcut** | Video chatbot | 🟠 BAJO | Specialized |

### 🎯 APLICABILIDAD A TU SETUP (Hermes)

**¿Qué ganas con Qwen-MM-Plugins?**

✅ **USEFUL:**
- Core plugin: Claude/Qwen leen imágenes nativas (benchmark plots, error screenshots)
- Video-memory: Recordar outputs de visualización Phase 4
- Search plugin: Similar a Memento pero más lightweight

❌ **NOT USEFUL:**
- Blender / FreeCAD: No aplica a scientific computing
- Video-edit: Not needed for benchmarks
- Omni-chatcut: Overkill for Phase 4

### RELACIÓN CON TUS OTRAS HERRAMIENTAS

| Herramienta | Qwen-MM | Relación |
|-------------|---------|----------|
| self-improving | ✓ Compatible | Monitoring skills |
| claude-code-best | ✓ Compatible | Skills definitions |
| Memento | ⚠️ Overlapping | Both add memory, different approach |

**Verdict:** Qwen-MM es COMPLEMENTARIO a Memento, no reemplazo.
- Memento = memoria de ERRORES + SOLUCIONES
- Qwen-MM = capacidades NATIVAS (leer imágenes, vídeos, archivos)

### INSTALACIÓN EN HERMES

```bash
# Instalador universal
curl -fsSL https://raw.githubusercontent.com/QwenLM/Qwen-MM-Plugins/main/install.sh | bash

# Manual setup para Hermes (según docs/en/manual_harnesses.md):
# ~/.hermes/plugins/qwen-mm-plugins/
# + config en ~/.qwen-mm-plugins/config
```

**Tiempo:** ~10 min setup
**Risk:** MÍNIMO (plugin-based, aislado)

### 🔴 CUÁNDO INSTALAR: NO HOY

**Razón:** Qwen-MM es para Qwen models (local LLM en CT 103).
Tu Hermes está configurado con Gemini Flash (Google provider).

**Aplicaría IF:**
- Cambias Hermes a usar Qwen como modelo principal
- Quieres agregar capacidades de video/imagen nativas

**Para Hermes + Gemini:** NO hay valor immediatamente.

### 💡 FUTURO: POST-PHASE-4

Si decides **migrar Hermes a Qwen 32B** (local LLM):
- Qwen-MM + core plugin → leer imágenes nativas
- Memento + Qwen-MM → memory + multimodal = potente combo
- Timeline: 2-3 semanas después Phase 4 stable

### SCORECARD: ¿VALE LA PENA?

| Criterio | Score |
|----------|-------|
| Instalabilidad | 🟢 5/5 (curl \| bash) |
| Utilidad para Phase 4 | 🟠 2/5 (Gemini ya multimodal) |
| Utilidad para Hermes | 🟡 3/5 (mejor con Qwen local) |
| ROI | 🟠 3/5 (futuro, no presente) |
| **RECOMENDACIÓN** | ⏳ NEXT MONTH (cuando Qwen activo) |

---

## CONCLUSIÓN

**Qwen-MM-Plugins** es excelente para agents basados en Qwen, pero:
- Hermes usa Gemini (ya multimodal nativo)
- Plugins son para capacidades específicas (video, blender, freecad)
- Value = 0 hasta que cambies LLM

**Instalabilidad: 95%** — súper fácil, casi trivial.
**Aplicabilidad: 20%** — no aplica a tu stack actual.

**Espera:** Hasta que Phase 4 esté 100% done + Hermes sea stable.
**Luego:** Considera migrar a Qwen local + activar Qwen-MM para multimodal nativa.

