# 🏆 PLAN DE BENCHMARKS — DM-UAMI vs GROMACS

**Objetivo:** Comparar performance real en 3 escenarios representativos  
**Metodología:** 3 runs cada, promediar, reportar

---

## 📊 Sistemas de Prueba

| Nombre | Atoms | Steps | Tiempo Est. | Descripción |
|--------|-------|-------|-------------|-------------|
| **RÁPIDO** | 102 | 100 | 0.1s | Agua UAMI (test actual) |
| **MEDIANO** | 1024 | 1000 | 1-2s | Sistema agua escalado 10x |
| **LARGO** | 10000+ | 10000 | 30-60s | Sistema realista MD |

---

## 🔧 Herramientas

- **DM-UAMI:** `/root/phase4_cuda_pinned/build/phase4_cuda`
- **GROMACS:** `/home/alejandre/gromacs-2025.3/bin/gmx`
- **Test Data:** `/home/alejandre/UAMI_Test/`

---

## 📋 Ejecución

```bash
FOR each system (RÁPIDO, MEDIANO, LARGO):
  FOR i=1 to 3:
    # DM-UAMI
    time dm-uami < system.gro > output_$i.txt
    extract: time_elapsed, pasos/s, energy
    
    # GROMACS
    time gmx mdrun -s system.tpr > gromacs_$i.txt
    extract: time_elapsed, pasos/s, energy
    
REPORT: Tabla comparativa (tiempo, velocidad, energía)
```

---

## 🎯 Deliverables

1. **Tabla de resultados** (3 runs promedios)
2. **Gráfico comparativo** (barras: DM-UAMI vs GROMACS)
3. **Reporte ejecutivo** con speedups
4. **CSV con datos crudos** (para análisis posterior)
