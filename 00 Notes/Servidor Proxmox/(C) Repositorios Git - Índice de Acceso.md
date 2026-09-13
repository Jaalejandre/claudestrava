# Repositorios Git — Índice de Acceso Centralizado

> **Última actualización:** 2026-09-12 07:15 CDMX
> **Generado por:** SatanZote AI
> **Propósito:** Acceso rápido a todos los proyectos construidos

---

## 🎯 ACCESO RÁPIDO

### GromacsMexicano
- **Ubicación:** `/home/alejandre/GromacsMexicano/` (CT 901)
- **Tamaño:** 464 MB
- **Estado Git:** 30+ commits, master branch
- **SSH:** `ssh alejandre@192.168.0.230` → `cd GromacsMexicano`
- **O directo:** `ssh root@192.168.0.52 "pct exec 901 -- ..."`

**Estructura Principal:**
```
Programa_DM/                    ← REFERENCIA CONGELADA (Fortran original científicos)
Programa_DM_cpp_v*/            ← C++ rewrites (v0, v1, v1.1, v2)
Programa_DM_v3_*/              ← Variantes v3 (OpenMP, parallel, GPU, v4_GPU)
Prueba/, Prueba_3M/, etc.      ← Directorios de test
Benchmark_2026-09-11/          ← Benchmarks recientes
Bench_UAMI_baseline/           ← UAMI baseline tests
Demo_AguaPura/, Demo_NaClCaliente/  ← Sistemas de demo
data/                          ← Datos de entrada
```

**Commits Recientes (últimos 10):**
1. 308867f: cpp: dihedral + 1-5 pair forces (fzas_diedro / fzas_15) + MTS cases A/D
2. ed417d9: cpp: Phase 4.8 - per-step output writers (energy.dat / dm.log / movie.gro / confout.gro)
3. 53b8dd0: cpp: Phase 6 (lean) - hardware detection, --help, installable
4. a69c111: cpp: Phase 4.7 perf - selective MTS force eval (bit-identical)
5. a2fb576: cpp: Phase 4.8 (lean) + 4.9 - MD driver main.cpp + running-average accumulator
6. 1065408: cpp: Phase 4.7 - default to correct reciprocal-Ewald physics + validate vs patched Fortran
7. 22b5791: cpp: Phase 4.7 - MTS r-RESPA velocity-Verlet + Nose-Hoover NPT integrator
8. c4d3d63: cpp: Phase 4.2/4.3 - Nose-Hoover Trotter propagation (thermo + baros)
9. 475be68: cpp: Phase 4.4 - Nose-Hoover chain state + init + reservoir energies
10. bad440a: cpp: Phase 4.5 - box_factors + remove_vcofm + shift_cofm_z

**Archivos Críticos:**
- `Programa_DM/` — referencia, nunca editar
- `Programa_DM_cpp_v2/CMakeLists.txt` — build C++
- `Benchmark_2026-09-11/` — último benchmark exitoso (−45.7% wall time)
- `UAMI_baseline/` — nuevos tests UAMI (2026-09-11)

---

### EntrenadorLEtape
- **Ubicación:** `/home/alejandre/EntrenadorLEtape/` (CT 901)
- **Tamaño:** 101 MB
- **Estado Git:** 6+ commits, master branch, **sin remote configurado**
- **Dashboard:** http://192.168.0.230:8003 (activo)
- **SSH:** `ssh alejandre@192.168.0.230` → `cd EntrenadorLEtape`
- **O directo:** `ssh root@192.168.0.52 "pct exec 901 -- ..."`

**Estructura:**
```
src/                    ← Source code (Python, web, API)
web/                    ← Frontend (mobile-first)
data/                   ← Strava, Zwift, Garmin data
tests/                  ← Test suite (49 tests, fases 1-5 done)
specs/                  ← Especificaciones
tasks/                  ← Task tracking (todo.md)
```

**Commits Recientes:**
1. adf64d5: feat: fase 5 web-dashboard — página local mobile-first en CT 901:8003
2. ee40e91: feat: fase 4 zwift-recommender — catálogo curado + mapeo sesión→workout/ruta
3. 8a62bc2: feat: fase 3 plan-engine — builder + motor de ajustes heurísticos + API
4. 93e70bc: test: T1.5/T2.3 tests mock (22 green) + fixes realidad API
5. 75dc328: chore: dependencias Python + ignore src/data
6. 9df45ee: chore: setup inicial del proyecto (gitignore + specs + plan)

**Status:**
- ✅ Fase 1-5 completadas
- ✅ 49 tests implementados
- 🚫 **Bloqueado:** Garmin auth (rate limit 429/403)
- 🚫 **Pendiente:** Git backup (sin remote GitHub)

---

## 📋 MATRIZ DE ACCESO

| Proyecto | Local Primaria | Backup | Remote | Protocolo |
|----------|-----------------|--------|--------|-----------|
| **GromacsMexicano** | CT 901 `/home/alejandre/GromacsMexicano/` | `/project/backups/REPO_INDEX.txt` | ❌ No | SSH + pct exec |
| **EntrenadorLEtape** | CT 901 `/home/alejandre/EntrenadorLEtape/` | `/project/backups/REPO_INDEX.txt` | ❌ No | SSH + pct exec |
| **Vault (claudestrava)** | CT 109 `/root/JarvisVault/` | GitHub ✅ | `git@github.com:Jaalejandre/claudestrava.git` | Git + Samba |

---

## 🔧 CÓMO NAVEGAR

### Listar commits recientes (GromacsMexicano)
```bash
ssh alejandre@192.168.0.230
cd GromacsMexicano
git log --oneline -20
git status
```

### Revisar cambios específicos
```bash
git show 308867f        # Ver commit
git diff <hash1> <hash2>  # Comparar commits
```

### Acceso desde CT 109 (Hermes)
```bash
ssh root@192.168.0.52 "pct exec 901 -- git -C /home/alejandre/GromacsMexicano log --oneline -20"
ssh root@192.168.0.52 "pct exec 901 -- git -C /home/alejandre/EntrenadorLEtape status"
```

### Copiar archivo específico a CT 109
```bash
scp alejandre@192.168.0.230:/home/alejandre/GromacsMexicano/Programa_DM_cpp_v2/CMakeLists.txt /tmp/
```

---

## ⚠️ PROBLEMAS CONOCIDOS

1. **GromacsMexicano**: Ownership caído (root vs alejandre) — **REPARADO 2026-09-12**
2. **EntrenadorLEtape**: Ownership caído (root vs alejandre) — **REPARADO 2026-09-12**
3. **Ambos**: Sin remote GitHub configurado
   - **Solución:** Crear repos públicos en GitHub + conectar SSH keys desde CT 901
   - **Prioridad:** Media (data está segura localmente + en vault)

---

## 📅 PRÓXIMOS PASOS

- [ ] Crear GitHub repos: `Jaalejandre/GromacsMexicano` y `Jaalejandre/EntrenadorLEtape`
- [ ] Conectar SSH keys en CT 901 para push
- [ ] Configurar CI/CD (GitHub Actions) para tests automáticos
- [ ] Sincronizar EntrenadorLEtape code a repo privado (Garmin creds no públicos)

---

## 📞 REFERENCIAS RÁPIDAS

**Ver todo lo que se construyó en GromacsMexicano:**
```
git log --all --graph --decorate --oneline
```

**Buscar commits por mensaje:**
```
git log --grep="Phase" --oneline
git log --grep="Ewald" --oneline
```

**Contar commits por autor:**
```
git shortlog -sn
```

---

**Generated:** SatanZote AI (Hermes) | **Platform:** Claude-dev (CT 109) | **Last sync:** 2026-09-12 07:15 CDMX
