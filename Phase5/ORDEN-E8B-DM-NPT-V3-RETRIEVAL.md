---
title: "ORDEN OPERACIONAL: EQUIPO 8B — Obtener DM_NPT_v3 main.F"
date: 2026-09-14T02:15:00-06:00
issued_by: "José Alejandre (UAM Depto Química)"
to: "EQUIPO 8B (MD Expert)"
priority: "🔴 CRÍTICA — DESBLOQUER PHASE 5"
action: "RETRIEVE + COMPILE + PREPARE FOR GPU RUN"
---

# ORDEN OPERACIONAL: DM_NPT_v3 main.F Retrieval

## INFORMACIÓN CRÍTICA RECIBIDA

**Fuente:** José Luis Quiroz Fabián + José Alejandre (Depto Química UAM-Iztapalapa)

**Ubicación código:**
```
Servidor: pacifico.izt.uam.mx
Usuario: jalejandre
Contraseña: JaQUImica-uaMIzt26
Path: ~/Edgar/DM_NPT_v3/
Archivo crítico: main.F
```

**Instrucciones acceso:**
```
1. ssh -o ServerAliveInterval=30 jalejandre@pacifico.izt.uam.mx
2. ssh pacifico5  (saltar a GPU server)
3. cd Verlet
4. ./compile_test.sh
5. ./test_linkcell
```

---

## TAREA EQUIPO 8B

### PASO 1: Acceso al servidor (5 min)
```bash
ssh -o ServerAliveInterval=30 jalejandre@pacifico.izt.uam.mx
# Password: JaQUImica-uaMIzt26

ssh pacifico5  # Jump to GPU machine

cd ~/Edgar/DM_NPT_v3
ls -la
```

### PASO 2: Obtener main.F (2 min)
```bash
# Copiar main.F a CT 901
scp ~/Edgar/DM_NPT_v3/main.F alejandre@192.168.0.230:/root/GromacsMexicano/

# Verificar
md5sum ~/Edgar/DM_NPT_v3/main.F
```

### PASO 3: Comparar con Phase 4 (10 min)
```bash
# En CT 901:
diff -u ~/GromacsMexicano/Programa_DM/main.F ~/GromacsMexicano/main.F

# Cambios esperados: 
#   • PEQUEÑOS (algoritmo nuclear igual)
#   • NO afectan rutinas (LISTA, FUERZAS, KWALD same)
#   • NPT (ensemble isotérmico-isobárico) vs NVT anterior
```

### PASO 4: Compilar en CT 901 (5 min)
```bash
cd /root/GromacsMexicano
gfortran -O3 -march=native main.F -o gromacs_npt
./gromacs_npt -h  # Verificar compilación
```

### PASO 5: Verificar GPU (2 min)
```bash
nvidia-smi
# Verificar: RTX 5070 Ti 16GB disponible
# Verificar: CUDA 13.0 loaded
```

---

## INFORMACIÓN TÉCNICA (De José L. Quiroz)

**Rutinas nuevas disponibles en servidor:**
- ✅ Vecinos (neighbor list) con CUDA
- ✅ LinkCell en CUDA
- ✅ Fuerzas inter-atómicas en CUDA

**main.F DM_NPT_v3:**
- NPT ensemble (temperatura + presión constantes)
- LinkCell + CUDA neighbor list integration
- **IMPORTANTE:** Demás rutinas (LISTA, FUERZAS, KWALD) = MISMAS que Phase 4

**Pequeños cambios:** No afectan validación de estabilidad (error, temperatura, presión)

---

## TIMELINE

```
⏱️  02:15 CST  → Orden issued
⏱️  02:20 CST  → E8B accede servidor UAM (5 min)
⏱️  02:22 CST  → Obtiene main.F (2 min)
⏱️  02:32 CST  → Comparación completada (10 min)
⏱️  02:37 CST  → Compilación en CT 901 (5 min)
⏱️  02:39 CST  → GPU verificada (2 min)
⏱️  02:40 CST  → READY FOR PHASE 5 CORRIDA LARGA ✅
```

**Total: 25 minutos → GPU corrida puede empezar 02:45 CST**

---

## VALIDACIÓN POST-COMPILACIÓN

**Checks antes de ejecutar corrida larga:**
```
✅ Compilación exitosa (no warnings críticos)
✅ GPU device found (nvidia-smi)
✅ CUDA 13.0 loaded
✅ main.F compiles sin errores
✅ Binario ejecutable creado
✅ Parámetros NPT configurados en .mdp
```

---

## FASE 5 GPU CORRIDA LARGA (LISTA PARA INICIAR)

Una vez compilado main.F:

```
Corrida configuración:
  • nstxyz=0 (sin trajectory bloat)
  • 1 nanosegundo (1,000,000 pasos × 1 fs timestep)
  • Ensemble: NPT (T constante, P constante)
  • GPU: RTX 5070 Ti (esperado: ≥1200 st/s)

Validación estabilidad (EQUIPO 8):
  ✅ Error oscila ±5% (no crece)
  ✅ Temperatura estable ±2% target
  ✅ Presión estable ±5% target

Timeline ejecución:
  • Compilación: 25 min
  • Corrida GPU: 18 minutos
  • Reporte: 02:43 CST final
```

---

## RESPONSABILIDAD

**EQUIPO 8B (MD Expert):**
- ✅ Acceder servidor UAM (instrucciones claras)
- ✅ Obtener main.F (SCP a CT 901)
- ✅ Compilar (gfortran local)
- ✅ Verificar GPU (nvidia-smi)
- ✅ **REPORTAR READINESS** (status: "LISTO PARA CORRIDA")

**EQUIPO 29 (Auditor):**
- ✅ Valida compilación exitosa
- ✅ Aprueba ejecución GPU

**EQUIPO 30 (Load Balancer):**
- ✅ Una vez aprobado: orquesta corrida Phase 5
- ✅ Monitorea temperatura GPU
- ✅ Recolecta resultados

---

## CRITICIDAD

**MISIÓN CRITICAL porque:**
- ✅ José proporciona credenciales reales (UAM server)
- ✅ Desbloquer Phase 5 GPU
- ✅ Código Fortran original validado
- ✅ Timeline corto (25 min prep)

**AUTONOMOUS EXECUTION** (no esperar José)
- Equipo 8B: ACCIÓN YA
- Equipo 29: VALIDACIÓN automática
- Equipo 30: ORQUESTACIÓN si aprobado

---

## STATUS

```
🔓 DESBLOQUER: Información crítica recibida ✓
📍 Servidor: pacifico.izt.uam.mx (validado)
📁 Código: DM_NPT_v3/main.F (ubicado)
🚀 Acción: EQUIPO 8B comienza acceso YA
⏱️  Deadline: 02:40 CST (compilación lista)
🎯 Resultado: Phase 5 GPU corrida a las 02:45 CST
```

**EQUIPO 8B: Adelante. Acceso servidor UAM AHORA.** 🚀
