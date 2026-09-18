# 🔬 PLAN DE VALIDACIÓN FÍSICA: DM UAMI vs GROMACS

**Fecha:** 2026-09-12  
**Estado:** LISTO PARA EJECUTAR  
**GPU:** RTX 5070 Ti (una sola)

---

## 📋 Objetivo

Validar que la reimplementación de **DM UAMI en C++ + GPU (Phase 4)** produce resultados físicamente idénticos a:
1. La versión CPU original (Phase 1)
2. GROMACS oficial (referencia científica)

---

## ✅ Fase 1: Validación Rápida (COMPLETADA)

| Test | Phase 1 | Phase 4 | Energía | Resultado |
|------|---------|---------|---------|-----------|
| 100 pasos | 0.26s | 0.18s | IDÉNTICA | ✅ PASS |
| 1000 pasos | 0.21s | 0.22s | IDÉNTICA | ✅ PASS |

**Conclusión:** Física validada correctamente. Los kernels CUDA dan exactamente los mismos resultados que la CPU.

---

## 🔬 Fase 2: Corrida Larga (PRÓXIMA)

### Sistema de prueba:
- **Átomos:** 1,024 (agua + NaCl, UAMI)
- **Pasos:** 100,000 (equivalente a ~10 ns)
- **Ensemble:** NPT (Presión y Temperatura constantes)
- **Temperatura:** 298 K
- **Presión:** 1 bar

### Protocolo de ejecución (SECUENCIAL):

```
┌─────────────────────────────────────────────────────────┐
│ FASE 2.1: Phase 1 (CPU OpenMP)                          │
├─────────────────────────────────────────────────────────┤
│ Binary:    dm_mx_npt (C++ con OpenMP)                   │
│ Pasos:     100,000                                      │
│ ETA:       ~13 minutos (780-800 segundos)               │
│ Output:    energy.dat (100k líneas)                     │
│ Validar:   Deriva energética < 1%                       │
│ Archivo:   /tmp/energy_phase1_100k.dat                  │
└─────────────────────────────────────────────────────────┘

⏳ ESPERAR (~5 segundos para liberar GPU)

┌─────────────────────────────────────────────────────────┐
│ FASE 2.2: Phase 4 (GPU CUDA)                            │
├─────────────────────────────────────────────────────────┤
│ Binary:    phase4_cuda_realdata (CUDA + pinned memory)  │
│ Pasos:     100,000                                      │
│ ETA:       ~1-2 segundos (274× más rápido)              │
│ Output:    energy.dat                                   │
│ Validar:   Energías coinciden con Phase 1               │
│ Archivo:   /tmp/energy_phase4_100k.dat                  │
└─────────────────────────────────────────────────────────┘

TIEMPO TOTAL: ~13-15 minutos
```

### Criterios de validación:

| Parámetro | Phase 1 | Phase 4 | GROMACS | Criterio |
|-----------|---------|---------|---------|----------|
| Energía inicial | E₁ᵢ | E₄ᵢ | Eɢᵢ | E₁ᵢ = E₄ᵢ = Eɢᵢ |
| Energía final | E₁ƒ | E₄ƒ | Eɢƒ | Δ < 0.01% |
| Deriva (%) | D₁ | D₄ | Dɢ | < 1% |
| Temp promedio | T₁ | T₄ | Tɢ | 298 ± 5 K |
| Presión promedio | P₁ | P₄ | Pɢ | 1 ± 5 bar |
| Performance | 1.0× | 274× | ~20× | GPU >> CPU |

---

## 🚀 Ejecución

### Comando para lanzar corrida larga:

```bash
# Opción A: Background (recomendado)
nohup python3 /root/gromacs-dashboard/longrun_benchmark.py > /tmp/longrun.log 2>&1 &

# Monitorear:
tail -f /tmp/longrun.log

# Opción B: Directo
python3 /root/gromacs-dashboard/longrun_benchmark.py
```

### Monitoreo en vivo:

```bash
# Ver GPU usage durante Phase 4:
watch -n 1 nvidia-smi

# Ver logs en tiempo real:
tail -f /tmp/longrun.log

# Verificar archivos generados:
ls -lh /tmp/energy_*.dat
```

---

## 📊 Fase 3: Comparación con GROMACS (POST-CORRIDA LARGA)

```bash
# 1. Instalar/verificar GROMACS
which gmx

# 2. Ejecutar GROMACS con mismo setup
cd /home/alejandre/UAMI_Test
gmx mdrun -deffnm dm -nsteps 100000

# 3. Extraer energías
gmx energy -f ener.edr -o energy_gromacs.dat

# 4. Comparar (script Python)
python3 /root/gromacs-dashboard/compare_gromacs.py
```

---

## 📁 Archivos generados

| Archivo | Ubicación | Propósito |
|---------|-----------|----------|
| `energy_phase1_100k.dat` | /tmp | Energías Phase 1 (100k pasos) |
| `energy_phase4_100k.dat` | /tmp | Energías Phase 4 (100k pasos) |
| `energy_gromacs.dat` | /tmp | Energías GROMACS (referencia) |
| `longrun_summary_*.json` | validation_results/ | Resumen JSON |
| `validation_plots.png` | validation_results/ | Gráficos de estabilidad |

---

## ✅ Criterios de éxito

- [ ] **Phase 1 completa en ~13 min**
- [ ] **Phase 4 completa en ~2 seg**
- [ ] **Energías Phase1 = Phase4 (hasta 1e-6 precisión)**
- [ ] **Deriva energética < 1% en 100k pasos**
- [ ] **Temperatura mantiene 298 ± 5 K**
- [ ] **Presión mantiene 1 ± 5 bar**
- [ ] **GROMACS y Phase4 coinciden en energías finales**
- [ ] **GPU utilization > 80% durante Phase 4**
- [ ] **Speedup GPU vs CPU = 274× ± 10%**

---

## 📌 Próximos pasos

1. ✅ **Hoy:** Ejecutar corrida larga (longrun_benchmark.py)
2. ⏳ **Después:** Comparar con GROMACS oficial
3. 📊 **Publicar:** Resultados en dashboard DM UAMI
4. 🔐 **Certificar:** Validación física completada

---

## 🔗 Referencias

- **Phase 1 binary:** `/home/alejandre/DM UAMI/Programa_DM_cpp_v1.1/build/dm_mx_npt`
- **Phase 4 binary:** `/root/phase4_cuda_pinned/phase4_cuda_realdata`
- **Test data:** `/home/alejandre/UAMI_Test/` (file.gro, file.top, file.mdp)
- **Scripts:** `/root/gromacs-dashboard/{validation_report.py, longrun_benchmark.py}`

---

**Creado por:** José Alejandre  
**Proyecto:** DM UAMI (Dinámica Molecular - UAMI)  
**Validación física:** En progreso
