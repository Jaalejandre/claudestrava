# Llave pública deploy para push del Entrenador L'Étape a GitHub

**Objetivo:** autorizar el push de `EntrenadorLEtape` (CT901) → GitHub.

Llave pública (NO es secreto — la pública es segura para compartir). Es la deploy key que ya está en CT901 (`/home/alejandre/.ssh/id_ed25519`).

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC1MMc1et+AWRolwIGt2NLtzRMkbVIcDXxMsFycyXMgJ deploy-letape
```

## Cómo agregarla en GitHub (2 min):

1. Ve a **https://github.com/Jaalejandre/EntrenadorLEtape/settings/keys**
   (si el repo aún NO existe, créalo primero: New repository → `EntrenadorLEtape` → Private)
2. Clic **Add deploy key**
3. **Title:** `ct901-deploy`
4. **Key:** pega la línea de arriba (la cadena ssh-ed25519 completa)
5. ✔ **Allow write access** (IMPORTANTE — sin esto no permite push)
6. **Add key**

## Después:

Dime "listo" y ejecuto desde CT901:
```
cd /home/alejandre/EntrenadorLEtape
git push -u origin main
```
Si aparece conflicto (non-fast-forward porque el remote ya tenía historia), lo resuelvo (rebase o merge) antes de forzar nada.

---
Fecha: 2026-09-14  ·  Autor: Sofía (CEO)