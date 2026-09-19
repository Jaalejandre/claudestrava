# POST-MORTEM: I/O Collapse
Causas: 1. Desincronización Repo/Fs. 2. I/O Error Fortran. 3. Ausencia de persistencia.
Corrección: Persistence SystemD + Pre-flight File Validation.
