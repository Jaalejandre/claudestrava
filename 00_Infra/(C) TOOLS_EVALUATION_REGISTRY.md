# (C) TOOLS EVALUATION REGISTRY

Evaluaciones de herramientas externas para adopción en el ecosistema SatanZote.
Formato: Fecha | Herramienta | Decisión | Resumen.

---

## 2026-09-20 | NVIDIA Container Service (NCX/NCP) + Container Toolkit

**Decisión: DESCARTAR** — No mejora nuestro manejo actual de GPU.

### Resumen
- **NCX/NCP CaaS** es una arquitectura de referencia para Cloud Partners (CSPs) que construyen plataformas AI multi-tenant con Kubernetes, Kubeflow Training Operator, y elastic scheduling. Apunta a clusters con 100+ GPUs y tenants, no a nuestro setup single-host/single-GPU.
- **NVIDIA Container Toolkit** (Apache 2.0) proporciona `nvidia-container-runtime` para que Docker/Podman/containerd expongan GPUs a contenedores — pero **CT 901 no ejecuta contenedores**. Gromacs C++ y todo workload corre nativo contra la GPU passthrough.
- **Setup actual**: RTX 5070 Ti (driver 580.105.08, 16 GB VRAM) en CT 901 (LXC). GPU drivers bind-mounteados y funcionando — solución ya documentada en `gpu-compute-workflows`.
- **CT 901 packages**: NVIDIA driver 580, CUDA Toolkit 12.0, libnvidia-ml-dev. Sin Docker, Podman ni ningún runtime de contenedores.

### Por qué no adoptar
1. **Sin contenedores → sin beneficio**. No hay multi-tenencia ni aislamiento que requiera contenedores. El GPU pasa directo a procesos nativos a velocidad bare-metal.
2. **Riesgo de regresión**. Instalar `nvidia-container-runtime` + hooks podría crear conflictos con el driver passthrough LXC personalizado. Sin beneficio que justifique el riesgo.
3. **Sobrecarga de mantenimiento**. Añadir Docker + Container Toolkit = otro runtime que actualizar, monitorear, y solucionar en fallas. Para zero ROI.
4. **Patrón documentado en `gpu-compute-workflows`** ya es el camino correcto para LXC + GPU nativa.

### Recomendación
- **NO instalar NVIDIA Container Toolkit** en CT 901.
- **NO considerar NCX/NCP** — es para hyperscale CSPs, irrelevante para nuestra escala.
- Si en futuro migramos CT 901 a KVM (full virtualization), el toolkit podría ser útil si además adoptamos contenedores para aislar workloads. En ese escenario, reconsiderar. Hasta entonces: descartado.

---

## 2026-09-20 | trycua/cua (Cua / cua.ai)

**Decisión: DESCARTAR (para contenedores GPU/CUDA en macOS)** — La premisa del caso de uso es inviable por límite de hardware. Ver nota de "Radar" limitado al final.

### Resumen técnico
- **Repo**: 25k★, 1.7k forks, MIT, creado 2025-01-31, muy activo (4758 commits, ~515 issues abiertos). Lenguaje principal reportado HTML (docs/lib-heavy).
- **Qué es hoy**: Cua (cua.ai) es una plataforma de **computer-use agents** (automatización desktop en background, sandboxes/cloud desktops, Cua Driver via CLI/MCP/SDK, Cua-Bench). De aquí, **Lume** es el subproducto relevante: "local VM manager for Apple Silicon Macs" (macOS y Linux VMs) sobre el `Virtualization.framework` de Apple.

### La pregunta clave: ¿CUDA/GPU corre en Mac (M3)?
- **CUDA NO corre en Apple Silicon — límite duro de hardware.** El GPU de la M3 es de arquitectura **Apple/Metal**, y CUDA exige hardware NVIDIA + driver NVIDIA. No existe CUDA Toolkit para macOS/Apple Silicon. **Ningún VMM ni capa de contenedores puede proporcionar CUDA en una M3.**
- Lo que SÍ ofrece Lume/Cua en Mac: **paravirtualización del GPU de Apple como dispositivo Metal** en VMs macOS/Linux guest. Acelera workloads **Metal-nativos** — sobre todo **inferencia LLM vía llama.cpp** (blog oficial: 11–16× más rápido en VMs macOS con un "Metal capability shim" que destraba kernels Metal nuevos en el guest; Gemma 4 12B y Muse Glimmer 30B validados).
- **No sirve** para Gromacs/MD-CUDA ni ningún workload científico CUDA que hoy corre en CT 901 (RTX 5070 Ti) o RTX A5000.

### Por qué no adoptar (para el caso de uso planteado)
1. **CUDA en Mac es imposible por hardware**: M3 = Metal, no NVIDIA. VMM/container GPIO no lo cambia.
2. **Sin brecha real vs stack actual**: nuestro compute CUDA es Linux/LXC con passthrough nativo bare-metal (`gpu-compute-workflows`). La M3 no es nodo de cómputo CUDA, y no lo será.
3. **Duplicaría Ollama local**: el único valor de Cua en Mac (VM con Metal para llama.cpp) ya está cubierto por Ollama en CT 103 con qwen/gpt-oss/gemma3/kimi. ROI ≈ 0.

### Nota de "Radar" (acotada, NO adoptar ahora)
- Único escenario de interés futuro: correr **VMs locales (macOS/Linux) aisladas con inferencia LLM Metal** en la M3 sin instalar nada en el host. Si en algún momento queremos aislar workloads de llm.cpp/Ollama del host Mac y usar Metal destrabado, Lume sería la vía. Sin desplegar hoy.

### Recomendación
- **Descartar** para contenedores GPU/CUDA en macOS (objetivo de esta evaluación).
- Mantener **en radar** solo la subcapacidad Lume para VMs Metal nómadas en la M3. No tocar CUDA stack actual.

---