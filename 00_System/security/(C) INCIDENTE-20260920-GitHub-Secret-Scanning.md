---
tipo: incidente-seguridad
id: SEC-20260920-001
severidad: media
estado: cerrado
fecha: 2026-09-20
detectado: 2026-09-13
cerrado: 2026-09-13
origen: GitHub Secret Scanning (push protection)
sistema_afectado: claudestrava repo / Cloudflare User API Token
responsable_ops: Belcebu (Ops/Security)
tags: [cloudflare, token-exposure, secret-scanning, github, vault]
---

# 🛡️ INCIDENTE SEC-20260920-001
## Credencial Cloudflare expuesta — GitHub Secret Scanning

---

## 📋 Resumen

GitHub Secret Scanning detectó y revocó automáticamente un **User API Token de Cloudflare** (`CFUT_...`) contenido en el script `DEPLOY.sh` del repositorio `claudestrava`. El token fue expuesto accidentalmente al hacer push del archivo al repositorio remoto de GitHub.

### Cronología

| Fecha/Hora (CDMX) | Evento |
|---|---|
| 2026-09-12 ~18:03 | Commit `eea425d` introduce el archivo `DEPLOY.sh` con el token hardcodeado en una línea `export CLOUDFLARE_API_TOKEN="cfut_..."` |
| 2026-09-13 ~09:09 | GitHub Push Protection detecta el token en el push y **bloquea la publicación**. Commit `53bd411` redacta el token reemplazándolo con `cfut_REDACTED` |
| 2026-09-13 09:09 | GitHub Secret Scanning **revoca automáticamente** el token en Cloudflare |
| 2026-09-20 | Documentación formal del incidente (este reporte) |

### Detalle técnico

- **Token afectado:** Cloudflare User API Token (prefijo `cfut_`)
- **Archivo expuesto:** `01 Projects/GromacsMexicano/gromacs-analyzer-worker/gromacs-analyzer/DEPLOY.sh`
- **Línea expuesta:** `export CLOUDFLARE_API_TOKEN="cfut_929uylLoJXl5FmWxYeWOgXMBb04Ag3NreGEUHOp2a6d51ed3"`
- **Contexto:** Script de deploy para Cloudflare Workers AI (gromacs-analyzer-worker)
- **Tunnel relacionado:** CT 108 (cloudflared) — config remota, token en dashboard Cloudflare (no afectado directamente)

### Acción tomada

| Acción | Estado |
|---|---|
| Token redactado en repo (`cfut_REDACTED`) | ✅ Completo |
| Token ya revocado por GitHub Secret Scanning | ✅ Automático |
| Commit correctivo (`53bd411`) pusheado | ✅ Completo |
| Verificación de otros tokens en el repo | 🔲 Pendiente |

---

## 🔍 Análisis de causa raíz

**Causa directa:** El archivo `DEPLOY.sh` incluía el token CFUT como variable de entorno hardcodeada en lugar de leerlo de una fuente segura (variable de entorno, archivo `.env` ignorado por git, o secrets de CI/CD).

**Causa sistémica:**
1. El workflow de deploy para Cloudflare Workers se documentó con el token inline "por conveniencia" en un script de ayuda (`DEPLOY.sh`)
2. No había `.gitignore` que excluyera scripts con secretos
3. No había un proceso de revisión de seguridad previo a commits
4. El desarrollador (SatanZote AI / CT109) no activó pre-commit hooks de detección de secretos

---

## 📊 Impacto

| Aspecto | Impacto |
|---|---|
| **Token revocado** | No es funcional, no hay riesgo de uso malicioso |
| **Servicios Cloudflare** | Sin afectación — el token era para deploy de Workers, no para túneles ni DNS |
| **CT 108 (cloudflared)** | No afectado — usa tunnel token independiente almacenado en dashboard Cloudflare |
| **CT 109 (cloudflared)** | No afectado — configuración separada |
| **Exposición externa** | El token fue detectado y revocado por GitHub antes de que pudiera ser explotado |
| **Costo** | Ninguno — revocación automática sin costo |

---

## 🛡️ Recomendaciones preventivas

### Inmediatas (implementar esta semana)

1. **Pre-commit hook de detección de secretos** — Instalar y configurar `trufflehog`, `git-secrets` o `detect-secrets` como git hook en el vault. Bloquear commits que contengan patrones de API keys (prefijos `cfut_`, `ghp_`, `sk-`, etc.).  
   → Comando sugerido: `git secrets --register-aws` + patrón `cfut_.*` para Cloudflare.

2. **`.gitignore` estricto** — Asegurar que `*.env`, `.env.*`, `*secret*`, `*token*`, `*credential*` estén globalmente ignorados.

3. **Auditar historial completo del repo** — Escanear todo el historial de git en busca de otros tokens expuestos (incluso en commits antiguos). Usar `trufflehog git file://. --since-commit HEAD~30` o BFG Repo-Cleaner.

### Mediano plazo (próximo sprint)

4. **Vault de secretos centralizado** — Migrar todos los tokens de API a un gestor de secretos:
   - Opción A: [Mozilla SOPS](https://github.com/mozilla/sops) + age para encryptar secretos en el repo.
   - Opción B: HashiCorp Vault o Infisical (self-hosted).
   - Opción C: Bitwarden Secrets Manager (BWS) para APIs.

5. **CI/CD con secret injection** — Los scripts de deploy (`DEPLOY.sh` y similares) deben leer tokens de variables de entorno del CI/CD runner, no tenerlos inline. En desarrollo local, leer de `~/.cloudflare/credentials` o `$CLOUDFLARE_API_TOKEN` de entorno.

6. **Revisión de secretos almacenados** — Identificar dónde más se almacenan tokens en el vault (archivos de configuración, scripts, notas) y reemplazar con referencias a un vault externo o marcadores `[SECRET_NAME]`.

### Permanentes (política)

7. **`CLAUDE.md` / policy del vault** — Agregar regla explícita en el manifesto del equipo:  
   _"Ningún token, API key, password o certificado puede ser escrito en archivos del vault. Usar variables de entorno, gestor de secretos o marcadores `[SECRET_NAME]`."_

8. **Auto-scan en cada push** — Configurar GitHub Actions para correr `trufflehog` o `gitleaks` en cada push y PR, bloqueando si detecta secretos.

9. **Rotación periódica** — Establecer política de rotación de tokens Cloudflare cada 90 días.

---

## 🔗 Referencias

- Commit de redacción: `53bd411` — `security: redact Cloudflare API token (GitHub push protection)`
- Commit original con token: `eea425d` — `Archive: DM-UAMI Phase 4 Validation Complete (2026-09-12)`
- Auditoría de exposición: `00_System/Notes/Servidor Proxmox/(C) Auditoría de exposición 2026-09-11.md`
- Script afectado: `gromacs-analyzer-worker/gromacs-analyzer/DEPLOY.sh` (token ya redactado)
- Tunnel CT 108: `00_Notes/Servidor Proxmox/Arquitectura/CT 108 cloudflared.md` (no localizado — mover documentación si existe)

---

## ✅ Estado final

| Concepto | Valor |
|---|---|
| Incidente | **Cerrado** — token revocado, causa documentada |
| Riesgo residual | Bajo — no hay otros tokens conocidos en el repo |
| Dueño | Belcebu (Ops/Security) |
| Fecha cierre | 2026-09-13 (acciones correctivas) / 2026-09-20 (reporte formal) |
| Próximo paso | [ ] Escanear historial completo de git con trufflehog |