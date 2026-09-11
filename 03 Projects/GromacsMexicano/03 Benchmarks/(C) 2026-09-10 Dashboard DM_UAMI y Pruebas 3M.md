# (C) Actualización del Dashboard DM_UAMI y Corrida de 3 Millones de Pasos — 2026-09-10

- **Proyecto:** DM_UAMI (antes GromacsMexicano)
- **Fecha:** 2026-09-10
- **Autor:** SatanZote AI / José

## Resumen de Cambios y Ajustes

1. **Nombre Oficial:** Actualizado a **DM_UAMI** en el título y headers de la aplicación web de benchmark (`app.py`).
2. **Corrección de Temperatura en Gráfica:** 
   - Se detectó que la gráfica leía la columna equivocada de `energy.dat` (~27K en lugar de 298K). 
   - Corregido al índice de columna correcto (**col 26**, dando exactamente ~298.14K conforme al `dm.log`).
3. **Nueva Gráfica de Conservación de Energía ($\Delta E$):**
   - Agregada la lectura directa de `error.dat`, reflejando la variable $\Delta E$ (comparativa de energía total con respecto al paso inicial), tal como sugirió el equipo de investigación para verificar estabilidad en simulaciones largas.
4. **Preparación de Corrida Larga (3 Millones de Pasos):**
   - Creada la carpeta aislada `Prueba_3M/` en CT 901 (`/home/alejandre/GromacsMexicano/Prueba_3M/`).
   - Modificado `file.mdp` a `nsteps = 3000000`.
   - Lanzada la simulación en background (PID 482119, 99.8% CPU / GPU) para validar estabilidad térmica, presión cercana a 1 atm y conservación de energía en trayectoria extendida.
5. **Optimización de Modelo LLM:**
   - Cambio de perfil `default` de Hermes a **`gemini-3.5-flash-lite`** para aprovechar la cuota gratuita de 500 solicitudes diarias (RPD) y evitar el bloqueo de 20 RPD que tenía la versión 3.6 Flash.
