title: "EQUIPO 41: MOLECULAR DYNAMICS DEVELOPMENT"
date: "2026-09-15T16:00:00-06:00"
version: "1.0"
status: "📝 PROPUESTA"
priority: "🟡 MEDIA"
owner: "Sofía (E35 Daemon-Director)"

role_csuite: "CTO (Chief Technology Officer)"

# EQUIPO 41: MOLECULAR DYNAMICS DEVELOPMENT 🧪

## Misión
Desarrollar y optimizar el código de dinámica molecular para los proyectos dm UAMI y DM UAMI, asegurando rendimiento, portabilidad y correctitud física.

## Objetivo
Crear un equipo dedicado a la implementación, pruebas y mejora de algoritmos de MD (potenciales LJ, Mie, FDR, Ewald, termostatos Nosé-Hoover, barostatos NPT) en C++/CUDA, con foco en:
- Optimización de kernels CUDA para RTX 5070 Ti.
- Validación contra resultados de referencia Fortran.
- Integración con el flujo de trabajo de dm UAMI (entrenamiento L'Étape, análisis de salud).

## Responsabilidades
1. Mantener y extender el repositorio de C++ de DM UAMI (CT 109 y CT 901).
2. Desarrollar tests unitarios y de integración para nuevos potenciales y algoritmos.
3. Realizar benchmarks de rendimiento y escalabilidad.
4. Colaborar con E39 (Benchmark Expert) para validar mejoras.
5. Documentar cambios y generar reportes de avance para E35.

## Recursos necesarios
- Acceso a CT 901 (GPU passthrough RTX 5070 Ti) y CT 109 (desarrollo).
- Licencia/acceso a compiladores CUDA y herramientas de profilado (nsight, nvvp).
- Tiempo estimado: 20h/semana (tiempo parcial de desarrolladores senior).

## Métricas de éxito
- Incremento de rendimiento ≥20% en kernels críticos vs baseline C++.
- Cero regresiones en pruebas de validación física.
- Entrega de al menos un módulo optimizado por mes.

## Timeline
- **Creación:** Inmediata tras aprobación.
- **Primer sprint:** 2 semanas (setup, revisión de código base, primer kernel optimizado).
- **Revisión:** Cada viernes con E35 (Sofía) para alinear prioridades.

## Dependencias
- E39 (Benchmark Expert) para validación de rendimiento.
- E40 (Memoria Canónica) para asegurar SSOT de configuraciones y resultados.
- E30 (Enrutador) para provisioning de contenedores y acceso GPU.

## Aprobación
Requerida: José (Alejandro) como gatekeeper para nuevos equipos.