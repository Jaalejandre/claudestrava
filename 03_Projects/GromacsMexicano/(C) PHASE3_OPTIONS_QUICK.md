# 🚀 PHASE 3 — GPU OPTIMIZATION — QUICK SUMMARY

**Hardware:** RTX 5070 Ti (CUDA 13.0) ✅  
**Current baseline:** Phase 2 (0.446s toy system)

---

## 3 OPCIONES

### **OPCIÓN A: PAIRWISE GPU (RECOMENDADO) ⭐**
- **Target:** Pairwise forces kernel (60-70% del cálculo)
- **Timeline:** 3 días
- **Speedup:** +5-10× (GPU)
- **Total cumulative:** 20-60× vs Fortran baseline
- **Risk:** LOW
- **Complejidad:** MEDIUM

### **OPCIÓN B: PAIRWISE + BONDED**
- **Target:** Pairwise + bonded forces kernels
- **Timeline:** 5 días
- **Speedup:** +8-15× (GPU)
- **Total cumulative:** 32-90× vs Fortran baseline
- **Risk:** MEDIUM
- **Complejidad:** HIGH

### **OPCIÓN C: FULL PIPELINE**
- **Target:** Pairwise + bonded + reductions (all GPU)
- **Timeline:** 6-7 días
- **Speedup:** +10-20× (GPU)
- **Total cumulative:** 40-120× vs Fortran baseline
- **Risk:** MEDIUM-HIGH
- **Complejidad:** VERY HIGH

---

## MI VOTO

**OPCIÓN A → OPCIÓN B later if needed**

**Por qué:**
- Pairwise es 60-70% del tiempo
- 3 días es razonable para CUDA
- Risk bajo
- Speedup solid (5-10×)
- Si después necesitas más, agregas bonded en 2 días

---

## ¿Cuál eliges?

**A, B, o C?**
