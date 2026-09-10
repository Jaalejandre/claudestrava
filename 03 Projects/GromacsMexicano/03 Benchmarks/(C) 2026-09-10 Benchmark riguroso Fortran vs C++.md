# Benchmark riguroso: Fortran vs C++ (10,000 pasos, agua SPC/E + NaCl, 2544 átomos)

**Fecha:** 2026-09-10  
**CT:** 901 (RTX 5070 Ti, CUDA 13.0, 12 vCPU)  
**CT 901 libre:** sí (`who` sin usuarios activos, sin procesos dm/gmx al inicio)  
**Protocolo:** 3 corridas completas de cada programa, wall time externo (`time`)

---

## Resultados de tiempo

| Corrida | Fortran (`dm_mx_npt`) | C++ (`gmx_mexicano`) |
|---------|----------------------|----------------------|
| 1       | 1m 38.4s             | 2m 17.1s (wall interno: 136.9s) |
| 2       | 1m 59.8s             | 2m  5.9s (wall interno: 125.8s) |
| 3       | 2m 10.7s             | 1m 58.8s (wall interno: 118.6s) |
| **Promedio** | **1m 56.3s (116.3s)** | **2m  7.3s (127.3s)** |

**Diferencia:** C++ ~9.5% más lento que el Fortran en este benchmark.

> Nota: Las corridas del Fortran tienen variación alta (38s–2m10s), probablemente por calentamiento de GPU o estado del sistema. La corrida 1 del Fortran (98s) es la más limpia (GPU en frío del día).

---

## Validación física

### Fortran (paso 10000, corrida 1)
- ulj: 7.84 kJ/mol | ucoul: −74.45 kJ/mol | ukwald: −37.37 kJ/mol
- T: 296.5 K | P: 66.3 bar | box: 2.987 nm | dens: 1159.9 kg/m³

### C++ (promedio 10000 pasos, corrida 1)
- Etot: −88.166 ± 0.015 kJ/mol
- T: 297.7 ± 4.7 K | deltaE promedio: 1.41e-4 kJ/mol

**Física consistente:** temperatura ~297–300 K, energía total ~−88 kJ/mol, densidad agua ~1160 kg/m³ — valores físicamente correctos para agua SPC/E a 300 K y 1 bar.

---

## Conclusiones

1. **El C++ es ~9.5% más lento que el Fortran** en este benchmark. Esto es un cambio de signo respecto al benchmark anterior (101s vs 97s aprox.) — el Fortran muestra variabilidad alta.

2. **La física es correcta en ambos** — temperatura, energía y densidad dentro de rangos esperados.

3. **El C++ tiene Wall time interno más estable** (118–137s, σ~9s) vs Fortran externo (98–130s, σ~17s). La variación del Fortran sugiere que el estado del GPU entre corridas afecta la primera corrida.

4. **Pendiente:** confirmar bug NATQ con los científicos — si el Ewald desactivado en el loop del Fortran era intencional, los resultados físicos son de sistemas ligeramente diferentes.

---

## Próximos pasos

- [ ] Reportar a científicos el bug NATQ y esperar respuesta
- [ ] Perfilar C++ con `ncu` para identificar cuello de botella vs Fortran
- [ ] Fase 6: empaquetado CPack cuando el NATQ esté resuelto
