# (C) Physics-Lock Checklist — Pre-flight antes de optimizar

**Source:** `03_Projects/GromacsMexicano/(C) physics-lock-checklist.md`
**Applies to:** GromacsMexicano C++/CUDA, DM-UAMI, cualquier simulación MD
**Rule:** Physics-lock es **mandatorio** — no se optimiza sin validación física primero

---

## Pre-flight checklist

### [ ] 1. Resultado de referencia existe y está congelado

- [ ] Ejecución de referencia completa con `Programa_DM/` (Fortran) o build estable
- [ ] Output de referencia guardado en `ref_run/`
- [ ] Commit congelado en git (tag o hash)
- [ ] Parámetros documentados: dt, nsteps, cutoff, kappa, kmax, etc.

```bash
# Verificar referencia congelada
cd /root/JarvisVault
git log --oneline -1 -- 03_Projects/GromacsMexicano/ref_run/
```

### [ ] 2. Test suite corre antes del cambio

- [ ] `make test` o script de test pasa completo
- [ ] Compilación limpia (sin warnings nuevos)
- [ ] Tests unitarios de kernels individuales (LJ, bonds, angles, kwald)
- [ ] Test de integración: 1000 pasos → no crash

```bash
cd /root/phase4_cuda_pinned
make clean && make -j$(nproc)
./test_suite
```

### [ ] 3. GPU libre

- [ ] RTX 5070 Ti sin procesos de cómputo ajenos
- [ ] Lock file `/tmp/gpu_lock/` no tiene owner activo
- [ ] GPU Orchestrator no tiene jobs running para esta GPU (si aplica)
- [ ] UAM-I no está usando remotamente

```bash
# Verificar GPU
pct exec 901 -- nvidia-smi --query-compute-apps=pid,name --format=csv
pct exec 901 -- who
pct exec 901 -- ps aux | grep -E "(gromacs|mdrun|python.*sim)"

# Verificar lock
check_gpu_free()  # definido en GPU-RESERVATION-PROTOCOL.md

# Si todo ok, adquirir lock
acquire_gpu_lock "daemon-moldyn" 86400  # reservar 24h
```

### [ ] 4. Physics invariants verificados

Después de cada cambio de código (no de parámetros de simulación):

- [ ] **Energía total** = energía cinética + potencial (dentro de tolerancia)
- [ ] **Conservación de energía** en microcanónico (NVE): dE/dt ≈ 0
- [ ] **Temperatura** en NVT se mantiene alrededor del setpoint (Berendsen)
- [ ] **Presión** en NPT no diverge
- [ ] **Posiciones/velocidades** no divergen (sin NaN, sin overflow)
- [ ] **kwald**: energía electrostática Ewald coincide con referencia Fortran (tolerancia < 1e-6)

```bash
# Comparar output con referencia
./compare_output --ref ref_run/output_ref.dat --new output_test.dat --tolerance 1e-6
```

### [ ] 5. Log entry escrito

```json
{
  "ts": "<ISO timestamp>",
  "team": "cientificos",
  "task": "<nombre tarea>",
  "worker_id": "<quién ejecuta>",
  "status": "started|done|failed",
  "duration_s": <segundos>,
  "gpu_used": "rtx5070|a5000|none",
  "commit": "<git hash>",
  "result": "qué se hizo y resultado"
}
```

```bash
# Append al log central
echo '{"ts":"'$(date -Iseconds)'","team":"cientificos","task":"physics-lock-preflight","worker_id":"daemon","status":"done","duration_s":120,"gpu_used":"none","commit":"'$(cd /root/JarvisVault && git rev-parse --short HEAD)'","result":"pre-flight OK, checklist completo"}' >> /root/JarvisVault/00_System/logs/$(date +%Y-%m-%d).jsonl
```

---

## Post-flight checklist (después de optimizar)

### [ ] 6. Resultados idénticos a referencia

- [ ] Comparar energía, temperatura, presión contra referencia
- [ ] Desviación máxima < 1e-6 (precisión single) o < 1e-12 (double)
- [ ] Trayectoria reproduce (misma semilla aleatoria)

### [ ] 7. Git commit del resultado

```bash
cd /root/JarvisVault
git add 03_Projects/GromacsMexicano/(C)*.md
git add 00_System/logs/*.jsonl
git commit -m "cientificos: <descripción del cambio>"
git push
```

### [ ] 8. Liberar GPU

```bash
release_gpu_lock
```

---

## Qué NO hacer

- ❌ Optimizar antes de tener referencia congelada
- ❌ Cambiar dt, cutoff, o parámetros físicos sin re-validar
- ❌ Ignorar divergencia de energía ("después lo veo")
- ❌ Usar reaction-field (instrucción explícita del científico)
- ❌ Editar `Programa_DM/` (referencia congelada, no tocar)

---

## Referencias

- Skill: `physics-lock-swarm`
- Skill: `gromacs-simulation-validation`
- Skill: `daemon-moldyn`
- Protocolo GPU: `00_Infra/(C) GPU-RESERVATION-PROTOCOL.md`
- SOUL equipo: `02_Teams/Cientificos-SOUL.md`