---
date: 2026-09-13T23:35:00-06:00
to: "EQUIPO 8 (DM UAMI Coordination)"
from: "José"
priority: "🔴 CRÍTICA"
topic: "Validación de Estabilidad - Corridas Largas"
---

# VALIDACIÓN DE ESTABILIDAD - EQUIPO 8 (DM UAMI)

## Mensaje para EQUIPO 8

```
📊 VALIDACIÓN REQUERIDA PARA CORRIDAS LARGAS

Cuando ejecuten corrida larga (1 ns, 1M steps):

CHECAR ESTOS 3 PARÁMETROS:
├─ ✅ ERROR TOTAL
│  └─ Debe OSCILAR (varía ± 2-5%)
│  └─ ❌ NUNCA debe CRECER constantemente
│  └─ Indicador: energy_error en archivo.log
│
├─ ✅ TEMPERATURA
│  └─ Debe mantenerse ESTABLE (300 K ± 2 K)
│  └─ ❌ NO puede divergir o crecer
│  └─ Indicador: temp en archivo.edr (cada 100 fs)
│
└─ ✅ PRESIÓN
   └─ Debe mantenerse ESTABLE (1.0 bar ± 0.1 bar)
   └─ ❌ NO puede oscilar descontroladamente
   └─ Indicador: pressure en archivo.edr

SI ESTOS 3 ESTÁN BIEN:
└─ Algoritmo es ESTABLE ✅
└─ El resto del sistema funciona correctamente
└─ Kernel optimization es válida

SI ALGUNO FALLA:
├─ Error crece → Problema de integración
├─ Temp diverge → Termostato mal acoplado
└─ Presión inestable → Barostato defectuoso
```

## Checks Automáticos para EQUIPO 8B (MD EXPERT)

```
DENTRO DE archivo.log, buscar:

1. ERROR OSCILATION CHECK
   Línea: "TOTAL ENERGY ERROR"
   Pattern: Valores (paso 0, 100, 200, 300...)
   Criterio: 
     ✅ error(step 1000) / error(step 0) ≈ 1.0 ± 5%
     ❌ error(step 1000) / error(step 0) > 1.5 → FAIL

2. TEMPERATURE STABILITY CHECK
   Línea: "Temperature" (cada 100 fs)
   Pattern: [300.1, 299.8, 300.3, 299.9...]
   Criterio:
     ✅ std(temp) < 2 K
     ❌ std(temp) > 5 K → FAIL

3. PRESSURE STABILITY CHECK
   Línea: "Pressure" (cada 100 fs)
   Pattern: [1.00, 1.02, 0.99, 1.01...]
   Criterio:
     ✅ std(pressure) < 0.15 bar
     ❌ std(pressure) > 0.5 bar → FAIL
```

## Flujo de Validación (EQUIPO 8B automático)

```python
def validate_long_run(archivo_log):
    # Parse log
    errors = parse_energy_errors(archivo_log)
    temps = parse_temperatures(archivo_log)
    pressures = parse_pressures(archivo_log)
    
    # Check 1: Error no crece
    error_ratio = errors[-1] / errors[0]
    if error_ratio > 1.05:
        return FAIL("Energy error growing: {:.2%}".format(error_ratio))
    
    # Check 2: Temperatura estable
    temp_std = np.std(temps)
    if temp_std > 2.0:
        return FAIL("Temperature unstable: std={:.2f}K".format(temp_std))
    
    # Check 3: Presión estable
    pressure_std = np.std(pressures)
    if pressure_std > 0.15:
        return FAIL("Pressure unstable: std={:.4f}bar".format(pressure_std))
    
    # All green
    return PASS("Algorithm stable ✅")
        → Kernel optimization VALID
        → Proceed to next phase
```

## Documentación de Resultados

Después de cada corrida larga:

```yaml
validation_timestamp: 2026-09-13T23:40:00-06:00
simulation_params:
  duration: 1000 ps
  steps: 1000000
  timestep: 1 fs
  ensemble: NVT (Nosé-Hoover)

checks:
  energy_error:
    initial: 0.0125 kcal/mol
    final: 0.0131 kcal/mol
    ratio: 1.048 (104.8%)
    threshold: < 105%
    status: ✅ PASS

  temperature:
    target: 300.0 K
    mean: 300.04 K
    std: 1.23 K
    threshold: < 2.0 K
    status: ✅ PASS

  pressure:
    target: 1.0 bar
    mean: 1.002 bar
    std: 0.082 bar
    threshold: < 0.15 bar
    status: ✅ PASS

result: ✅ ALGORITHM STABLE
next_step: Proceed to Phase 5 GPU optimization
```

## Integración con INFO BROKER (E24)

```
EQUIPO 8B → Termina validación
           → Publica en INFO BROKER
           → Topic: "dm.validation.stable"
           → Payload: {status, error_ratio, temp_std, pressure_std}

INFO BROKER → Notifica a:
            ├─ EQUIPO 8 (coordinator)
            ├─ EQUIPO 27 (evaluation board)
            ├─ VAULT MASTER (E19)
            └─ José (resumen)
```

## Notificación a José

```
SI ✅ VALIDACIÓN PASA:
  "DM UAMI corrida larga ✅ ESTABLE
   • Error oscila (no crece): 104.8%
   • Temperatura: 300.04 K ± 1.23 K
   • Presión: 1.002 bar ± 0.082 bar
   
   Algoritmo LISTO para Phase 5 GPU optimization"

SI ❌ VALIDACIÓN FALLA:
  "⚠️ DM UAMI corrida larga INESTABLE
   • Error creciendo: {X}%
   • Temperatura divergiendo: std={Y}K
   
   EQUIPO 8B analizando causa..."
```

---

*Validación de estabilidad: Core check para corridas largas*
*Si esto funciona → El algoritmo es sólido*
