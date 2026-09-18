# (C) Audit Diario — 2026-09-16 06:03 CST

Ejecutado por: satanzote-daily-audit-orchestrator (Hermes, CT 109)

## Resumen
- Estado general: OPERATIVO con 2 hallazgos
- 🟡 Hallazgo 1: Dashboard EntrenadorLEtape (:8003 en CT 901) CAÍDO
- 🟡 Hallazgo 2: Swap del host alto — 6.1/8.1 GB usados (swappiness 10, RAM libre 17 GB disp)

## Host Proxmox (192.168.0.52)
- RAM: 14,710/31,862 MB (17,151 disponibles) | load 0.72
- Swap: 6,135/8,191 MB usados ⚠️
- Top RAM: kvm 2.3GB, kvm 1.3GB, omniroute 1.1GB, open-webui 0.6GB
- Guests: 21 running, 1 stopped (CT 120 — esperado)

## CT 109 (claude-dev — este)
- Uptime 1d 11h | load 0.72 | disco 35/59 GB (62%)
- RAM: 2.5/16 GB | swap 0.9/4 GB
- Servicios: hermes-gateway ✅ active | omniroute ✅ active (:20128 escuchando)
- Puertos vivos: 20128 (omniroute), 8877 (airbnb-admin uvicorn), 8090 (ConfirmaCitas)
- vault-backup.timer ✅ activo — último push 2026-09-15 23:30, próximo hoy 23:30
- Vault git: working tree limpio

## CT 901 (dev — Gromacs/dm-UAMI/L'Étape)
- Uptime 1d 8h | disco 23/98 GB (25%) | RAM 0.9/8 GB | 0 usuarios conectados
- GPU: RTX 5070 Ti, driver 580.105.08, 3 MiB usados (idle), 36°C ✅
- ❌ Dashboard L'Étape :8003 NO está escuchando (caído o no arrancado)

## CT 103 (Ollama)
- Servicio ollama ✅ active
- Modelos: gpt-oss:20b, qwen2.5-coder:14b, gemma3:latest, kimi-k2.7-code:cloud
- Nota: qwen2.5-coder:14b-64k y gpt-oss:16k ya NO aparecen en la lista (inventario cambió vs mapa previo)

## Acciones sugeridas
1. Reiniciar dashboard L'Étape en CT 901 (o confirmar si se apagó a propósito).
2. Swap del host: no crítico (hay RAM libre), monitorear tendencia.
3. Actualizar mapa canónico de modelos Ollama (E40) — inventario divergió.
