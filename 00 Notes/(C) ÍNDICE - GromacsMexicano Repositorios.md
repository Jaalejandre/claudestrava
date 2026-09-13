# 📋 ÍNDICE MAESTRO — GromacsMexicano Repositorios

**Última revisión:** 2026-09-12  
**Status:** ORGANIZACIÓN EN PROGRESO

---

## 🎯 OBJETIVO

Tener UN SOLO lugar donde saber:
- Dónde está cada versión del código
- Qué binarios están compilados y funcionan
- Cuál usar para cada tipo de simulación

---

## 📂 ESTRUCTURA ACTUAL EN CT 901

**Ubicación:** `/home/alejandre/GromacsMexicano/`  
**Tamaño total:** ~500 MB  
**Git:** Sí, hay repo local

### Versiones Principales

#### ✅ **Programa_DM_cpp_v2** (RECOMENDADO PARA VALIDACIÓN)
- **Tipo:** C++ rewrite (NEW)
- **Estado:** Compilado, funciona ✓
- **Binario:** `./build/dm_mx_npt` (existe)
- **Último test:** 2026-09-12, 3 runs × 10K steps (completó 0s — problema de entrada)
- **Potenciales:** LJ, FDR, Mie, Ewald
- **GPU:** Soporta CUDA (pero no confirmado)
- **Uso:** Validar que C++ ≈ Fortran original

#### ⚠️ **Programa_DM** (FORTRAN ORIGINAL - REFERENCIA CONGELADA)
- **Tipo:** Fortran 77/95 + CUDA (ORIGINAL CIENTÍFICOS UAM)
- **Estado:** NO TOCAR (referencia de los científicos)
- **Binario:** `dm_mx_npt` (existe)
- **Potenciales:** LJ, FDR, Mie, Ewald, Nosé-Hoover, NPT
- **GPU:** CUDA compilado ✓
- **Último test:** Unknown (baseline histórico)
- **Uso:** Comparación/Validación

#### 🔧 **UAMI_baseline** (INCOMPLETO)
- **Tipo:** Descargado de UAM Pacifico (CPU single-thread)
- **Estado:** Shell script, NO ejecutable
- **Binario:** `dm_uami_baseline_binary` (corrupto)
- **Problema:** No recompilado correctamente
- **Uso:** Pendiente (comparación histórica)

#### 📊 **Otras versiones**
- `Programa_DM_v3.2` — Versión intermedia
- `Programa_DM_v3_parallel` — OpenMP
- `Programa_DM_v4_GPU` — GPU attempt
- `Prueba_v3_Clean` — Prueba limpia (249 MB)
- `Prueba_3M` — Prueba con 3M atoms
- Demos: `Demo_AguaPura`, `Demo_NaClCaliente`

---

## 🔍 VERDAD INCÓMODA

**Tenemos ~20 directorios con código, pero FALTA:**

1. ✗ **main.f más reciente de UAM** (`Edgar/DM_NPT_v3/`)
   - Papa (Jose Luis) lo envió por correo 2026-06-10
   - Tiene mejoras en Slater, LinkCell CUDA, etc.
   - **NO está en CT 901**

2. ✗ **Organización clara** de qué usar cuándo

3. ✗ **Coordenadas reales** (archivo topol.gro con átomos)
   - C++ v2 trata de usar `coords.gro` pero está vacío

---

## ✅ QUÉ NECESITAMOS HACER

### Paso 1: TRAER CÓDIGO CORRECTO (Hoy)
```
De: pacifico.izt.uam.mx/Edgar/DM_NPT_v3/
A: /home/alejandre/GromacsMexicano/DM_NPT_v3_MASTER/ (nuevo)
├── main.f (ACTUALIZADO CON SLATER + LINKCELL CUDA)
├── *.f *.f95 (todas las rutinas)
├── *.cu (kernels CUDA)
├── compilar_gpu.sh (script compilación oficial)
└── coords.gro (COORDENADAS REALES)
```

### Paso 2: LIMPIAR CT 901
```
✓ Congelar Programa_DM/ (nunca tocar)
✓ Renombrar versiones antiguas a "ARCHIVED/"
✓ Dejar 3 versiones principales:
  - DM_NPT_v3_MASTER (la nueva, de UAM)
  - Programa_DM_cpp_v2 (rewrite C++ actual)
  - Programa_DM (original Fortran, sólo referencia)
```

### Paso 3: RECOMPILAR Y VALIDAR
```
1. Compilar DM_NPT_v3_MASTER con compilar_gpu.sh
2. Test 3 runs × 10K steps CON COORDENADAS REALES
3. Medir wall time, verificar energías
4. Comparar vs C++ rewrite
```

---

## 📍 DECISIÓN: ¿Traemos el código de UAM ahora?

**Pros:**
- Código oficial con mejoras recientes
- Scripts compilación correctos
- Coordenadas reales

**Contras:**
- Necesita acceso SSH a UAM (credenciales)
- Requiere ~30 min recompilación
- Desvía de validación C++ actual

**Recomendación:** **SÍ, ahora.** Sin código correcto, cualquier validación será inútil.

---

## 🚀 ACCIÓN INMEDIATA

```bash
# 1. Conectar a UAM y traer código
ssh jalejandre@pacifico.izt.uam.mx
ssh pacifico5
cd Verlet
# O
cd Edgar/DM_NPT_v3
# Copiar todo a CT 901

# 2. Organizar CT 901
cd ~/GromacsMexicano
mkdir -p ARCHIVED
mv Prueba* ARCHIVED/
mv Demo* ARCHIVED/
# etc.

# 3. Recompilar
cd DM_NPT_v3_MASTER
./compilar_gpu.sh

# 4. Validar
cd ~/VALIDATION_MASTER
3 runs × 10K steps
```

---

**Status:** 🔴 **BLOQUEADO EN ORGANIZACIÓN**  
**Próximo paso:** Traer código de UAM  
**Tiempo estimado:** 1 hora (descarga + compilación)

Generated: SatanZote AI | 2026-09-12
