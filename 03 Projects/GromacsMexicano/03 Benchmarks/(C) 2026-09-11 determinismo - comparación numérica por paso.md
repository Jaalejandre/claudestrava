# (C) Determinismo — comparación numérica por paso (2026-09-11)

Generada automáticamente por `comparar-determinismo.sh` (plomería, sin LLM).

## Cabeceras de energy.dat (para saber qué es cada columna)

### base_run2
# DMENERGY version 1
# units: energies=kJ/mol lengths=nm density=kg/m3 temperature=K pressure=bar time=ps

### base_run3
# DMENERGY version 1
# units: energies=kJ/mol lengths=nm density=kg/m3 temperature=K pressure=bar time=ps

### opt_run1
# DMENERGY version 1
# units: energies=kJ/mol lengths=nm density=kg/m3 temperature=K pressure=bar time=ps

### opt_run2
# DMENERGY version 1
# units: energies=kJ/mol lengths=nm density=kg/m3 temperature=K pressure=bar time=ps

## Comparación por pares (campos = valores individuales en el archivo)

| par | filas de datos | campos bit-iguales | campos distintos | max abs delta | max rel delta |
|---|---|---|---|---|---|
| `base_run2` vs `base_run3` | 1000 | 5000 | 23000 | 1.420e+05 (col 20) | 1.999e+00 (col 16) |
| `opt_run1` vs `opt_run2` | 1000 | 5000 | 23000 | 2.320e+05 (col 20) | 2.000e+00 (col 28) |
| `base_run2` vs `opt_run1` | 1000 | 5000 | 23000 | 1.120e+05 (col 20) | 2.000e+00 (col 21) |
| `base_run3` vs `opt_run2` | 1000 | 5000 | 23000 | 1.660e+05 (col 20) | 1.998e+00 (col 17) |
| `base_run2` vs `ref` | 1000 | 5000 | 23000 | 2.235e+05 (col 20) | 2.000e+00 (col 18) |
