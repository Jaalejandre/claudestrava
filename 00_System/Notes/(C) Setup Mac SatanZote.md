---
tipo: referencia-setup
tema: mac-workspace
generado: 2026-09-09
estado: activo
---

# (C) Setup Mac SatanZote — workspace persistente

Configuración de la Mac (`josealejandre`, macOS) para el workspace SatanZote AI. **Objetivo: nunca reprogramar al reiniciar o cambiar de equipo.** Si se pierde la Mac o se formatea, seguir [[#Recuperación desde cero]].

## Resumen de lo configurado (2026-09-09)

| Pieza | Archivo | Estado |
| --- | --- | --- |
| Aliases SSH (pve, CTs, omniroute) | `~/.ssh/config` | ✅ activo |
| Aliases + funciones zsh | `~/.zshrc` | ✅ activo |
| Script bootstrap | `~/bin/satanzote` | ✅ activo (ejecutable) |
| Credenciales locales | `~/.config/satanzote/env` (chmod 600) | ✅ activo |
| Auto-mount del vault al login | `~/Library/LaunchAgents/com.jarvis.mountvault.plist` | ✅ activo |
| OmniRoute local autostart | `~/Library/LaunchAgents/com.omniroute.autostart.plist` | ✅ activo (KeepAlive) |
| Vault montado en | `/Volumes/JarvisVault` (smb de CT 109 `.64`) | ✅ activo |
| Llave SSH | `~/.ssh/id_ed25519` (copia pública en pve, CT 109, CT 901) | ✅ activo |

## Aliases SSH (`~/.ssh/config`)

| Alias | Host | Usuario | Para qué |
| --- | --- | --- | --- |
| `pve` | 192.168.0.52 | root | Host Proxmox — administrar todo |
| `claude-dev` / `ct109` | 192.168.0.64 | root | Nodo IA: vault, OmniRoute :20128, Telegram |
| `gromacs` / `ct901` | 192.168.0.230 | alejandre | GromacsMexicano (GPU, CUDA) |
| `ollama` / `ct103` | 192.168.0.99 | root | Ollama :11434 + Open WebUI :8080 |
| `vaultwarden` / `ct114` | 192.168.0.30 | root | Gestor de contraseñas |
| `ntfy` / `ct116` | 192.168.0.179 | root | Notificaciones push |
| `npm` / `ct100` | 192.168.0.109 | root | Nginx Proxy Manager |
| `omniroute` | 192.168.0.64 | root | Gateway LLM |

> ⚠️ CTs .99 / .30 / .179 / .109 **no tienen la llave pública de la Mac instalada** (verificado 2026-09-09: `Permission denied`). Acceso por web o vía `ssh pve`. Para habilitar SSH directo, copiar la llave desde el host Proxmox:
> `ssh pve "ssh-copy-id root@192.168.0.99"` (y .30, .179, .109).

## Comandos disponibles en la Mac

| Comando | Qué hace |
| --- | --- |
| `satanzote up` | Bootstrap: monta vault si falta, verifica SSH a pve, levanta OmniRoute local |
| `satanzote status` | Resumen: vault / ssh pve / OmniRoute remoto |
| `pve-status` | Una línea del estado del host Proxmox (uso protocolo compacto) |
| `qct <id>` | Una línea del estado de un CT/VM (ej: `qct 901`) |
| `gpu` | Atajo de `qct 901` (estado GPU de Gromacs) |
| `gm` / `gmb` | SSH a CT 901 / listar el proyecto C++ de Gromacs |
| `vault` | `cd /Volumes/JarvisVault` |
| `vault-status` | Verifica si el vault está montado |
| `omni` | Health check de OmniRoute remoto (CT 109 :20128) |

## Credenciales — dónde viven (NO en el vault)

| Secreto | Ubicación | Nota |
| --- | --- | --- |
| API key OmniRoute | `~/.config/satanzote/env` (`OMNIROUTE_API_KEY`) | chmod 600; el vault **no** la contiene |
| URL SMB del vault (root + pass) | `~/.config/satanzote/env` (`SMB_VAULT_URL`) | usada por `satanzote`; también está en `com.jarvis.mountvault.plist` |
| Credencial de OmniRoute dashboard | `vault.satanzote.me` (Vaultwarden, CT 114) | admin / password en Vaultwarden `vault.satanzote.me` |
| Llave SSH Mac | `~/.ssh/id_ed25519` | la pública está en pve .52, CT 109 .64, CT 901 .230 |

**Regla de hierro:** nada de contraseñas/API keys en notas del vault — es repo git que se pushea a GitHub (privado, pero igual no se arriesga). Los secretos de la Mac viven SOLO en `~/.config/satanzote/env` y en el keychain de Vaultwarden.

## Recuperación desde cero (Mac nueva / formateada)

1. Instalar Xcode CLT + Homebrew + zsh.
2. Instalar [Claude Code](https://claude.ai/claude-code) → loguear (OAuth). Con eso el vault ya se puede clonar:
3. `git clone git@github.com:Jaalejandre/claudestrava.git ~/JarvisVault` (montar el SMB es opcional; el repo completo vive en Git).
4. Recrear `~/.ssh/id_ed25519` y copiar la llave: `ssh-copy-id root@192.168.0.52` (pve), luego `ssh pve "ssh-copy-id root@192.168.0.64; ssh-copy-id alejandre@192.168.0.230"`.
5. Copiar este archivo de config de referencia (versión redactada en el repo): `~/.ssh/config`, `.zshrc` (sección SatanZote), `~/bin/satanzote`.
6. Recrear `~/.config/satanzote/env` con los secretos desde Vaultwarden.
7. `satanzote up` → debería quedar todo como antes.

## Notas

- **Backup automático:** el vault se pushea a GitHub diario 23:30 (timer `vault-backup.timer` en CT 109) — la config de la Mac documentada aquí viaja con el repo.
- **Rotación:** si se rota la API key de OmniRoute, actualizar `~/.config/satanzote/env` y el plist de mountvault si aplica. No hay que tocar el vault.
- **OmniRoute local:** por qué existe: fallback si CT 109 cae; el remoto (.64:20128) es el de uso diario. `KeepAlive` lo mantiene vivo desde el login.
- El `.ssh/config` original (hosts `.146`, `.7`, `.162`, `gpu.satanzote.me`) se preservó intacto y se añadieron los nuevos hosts al final. Backup: `~/.ssh/config.bak.20260909`.