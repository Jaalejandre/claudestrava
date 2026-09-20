# PinchTab

| Campo | Valor |
|-------|-------|
| **Nombre** | PinchTab |
| **URL** | https://github.com/pinchtab/pinchtab |
| **Propósito** | Sidecar browser especializado para auditoría de sitios web y persistencia de perfiles de navegación |
| **Decisión** | Parcialmente |
| **Razón** | Aprobado como **sidecar experimental** para tareas específicas de site audit y mantenimiento de perfiles persistentes (cookies, sesiones, localStorage). NO reemplaza `browser_exec` como driver principal de navegación automatizada — el browser pool actual (Chromium sin headless via `browser_exec`) es más flexible, está integrado con el vault de credenciales, y soporta múltiples sesiones concurrentes. PinchTab puede complementar para casos donde se requiere un perfil de navegación persistente entre ejecuciones (ej. dashboards con login que caducan). |
| **Casos de Uso** | • Auditoría periódica de sitios con sesión persistente • Monitoreo de dashboards que requieren login • Pruebas de comportamiento en perfiles de navegación realistas • Sidecar para tareas que necesitan cookies persistentes entre calls |
| **Fecha** | 2026-09-20 |