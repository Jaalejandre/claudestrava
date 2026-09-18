# Escuadrón BELSEBU: OmniMind (`omnimind-*`)
## Optimización, Ruteo Inteligente e Inferencia LLM

- **Host Maestro**: CT 666 (`satanzote`, `192.168.0.104`)
- **Gateway**: OmniRoute (`http://127.0.0.1:20128`)
- **Metodología**: BELSEBU (9 Roles)

### Misión
Asegurar que cada solicitud de inferencia tome la ruta óptima:
1. **Calidad**: Maximizar fidelity de ruteo (AGY tier).
2. **Costo**: Minimizar burn rate de tokens mediante ruteo dinámico.
3. **Latencia**: Priorizar rutas con mayor throughput inferido.

### Matriz de Roles Dinámicos
- `omnimind-overlord`: Coordina la estrategia de ruteo.
- `omnimind-tactician`: Define qué modelo es "mejor" (`best-coding` vs `best-reasoning`).
- `omnimind-overclock`: Ejecuta el script de auditoría de costos (`/root/scripts/omni_audit.sh`).
