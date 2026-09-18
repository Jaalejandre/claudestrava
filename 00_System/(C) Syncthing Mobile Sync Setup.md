# (C) Syncthing Mobile Sync Setup

**Status:** Configurado y activo en CT 109  
**Last Updated:** 2026-09-17  
**Sync Size:** ~44 MB (notas, proyectos, planes — `.obsidian/` y `.git/` excluidos por `.stignore`)

---

## Servidor (CT 109)

| Parámetro | Valor |
|-----------|-------|
| Contenedor | CT 109 (Ubuntu 26.04 LTS) |
| Directorio | `/root/JarvisVault` |
| Servicio | `systemd` (`syncthing-root.service`) |
| IP del Server | `192.168.0.64` |
| Puerto Sync | `22000` (TCP/UDP) |
| Puerto WebUI | `8384` (TCP) — escucha en `0.0.0.0` |
| Discovery UDP | `21027` |
| Device ID | `N2D24W3-SJVNDFR-YKVJ5AJ-I4FPASQ-L6ZZL7F-47K6KNS-5VJX7JL-3OGW3QW` |
| API Key | `kpgeNC4ztCDMKta2hkdpsgingyTjHFVh` |
| Folder ID | `default` |
| Tipo | `sendreceive` (bidireccional) |

### Qué se sincroniza

✅ **Sí:** Todas las notas, proyectos, planes, documentos, skills (todo markdown + archivos esenciales).

❌ **No (excluido por `.stignore`):**
- `.obsidian/` — configuración de plugins + node_modules (683 MB) → no aplica en móvil
- `.git/` — historial de git (respaldado en GitHub)
- `node_modules/` — dependencias de proyectos
- Archivos binarios grandes (`.mp4`, `.mov`, `.zip`)
- Archivos temp del SO (`.DS_Store`, `Thumbs.db`)

### Firewall

```bash
# Permitir Syncthing desde cualquier IP en la red local
ufw allow from 192.168.0.0/24 to any port 22000,22001,21027 proto { tcp udp }
ufw enable
```

---

## Pasos EXACTOS para Android

### 1️⃣ Descargar la app

**Opción A (Recomendado):**
- Ve a **Google Play Store** en tu Android
- Busca: **Syncthing**
- Descarga la app oficial (icono azul + flecha de sincronización)
- Instala y abre

**Opción B (F-Droid — alternativa open-source):**
- Descarga F-Droid desde `https://f-droid.org`
- Abre F-Droid y busca **Syncthing**
- Instala la versión de **Syncthing Foundation**

### 2️⃣ Agregar el dispositivo servidor (CT 109)

Una vez abierta la app de Syncthing:

1. Toca el **botón ➕** en la esquina inferior derecha (o menú → Add Device)
2. Verás una pantalla que pide:
   - **Device ID** (código de 56 caracteres con guiones)
   - **Device Name** (nombre descriptivo, p. ej. "Servidor")
   - **Addresses** (opcional, solo si la auto-discovery falla)

3. **Copia y pega exactamente este Device ID:**
   ```
   N2D24W3-SJVNDFR-YKVJ5AJ-I4FPASQ-L6ZZL7F-47K6KNS-5VJX7JL-3OGW3QW
   ```

4. **Device Name:** escribe `Servidor CT-109` (o lo que prefieras)

5. Toca **Save**

### 3️⃣ Agregar la carpeta compartida

El servidor ya está configurado para compartir la carpeta `default` (JarvisVault). Cuando hayas agregado el servidor:

1. En la pantalla principal de Syncthing, aparecerá una notificación diciendo:
   > "Device 'Servidor CT-109' request sharing of folder 'Default Folder'"

2. Toca la notificación o ve a **Folders** → **JarvisVault (Default)**

3. En las opciones del folder:
   - **Folder Path:** déjalo como la app sugiera (típicamente algo como `~/Android/data/com.nutomic.syncthingandroid/files/Sync/JarvisVault/`)
   - **Folder ID:** debe ser `default` (no cambies)
   - **Type:** `Receive & Send` (ya está por defecto — correcto)
   - Toca **Save**

### 4️⃣ Esperar conexión

- El servidor y el celular deben estar en la **misma red local** (192.168.0.x o tu home WiFi)
- Syncthing en ambos lados buscará el otro dispositivo por discovery
- Verás una conexión cuando en la app aparezca el estado **"Synced"** o **"Up to Date"**
- La primera sincronización tardará un par de minutos (~44 MB)

### 5️⃣ Verificar en Obsidian Mobile

Una vez sincronizado:

1. Abre **Obsidian** en tu Android
2. Toca **Create** o **Open vault**
3. En el explorador de archivos, navega a la carpeta que Syncthing creó (usualmente `~/Sync/JarvisVault/` o similar)
4. Abre y disfruta de tu vault en el móvil

---

## Solución de problemas

| Problema | Solución |
|----------|----------|
| **La app no encuentra el servidor** | 1. Verifica que estés en la misma red WiFi. 2. Recopia el Device ID (sin errores). 3. En "Addresses", agrega manualmente: `tcp://192.168.0.64:22000` |
| **Conexión lenta** | Normal la primera vez (~44 MB). Después es casi instantáneo. |
| **Archivo no aparece en móvil** | Espera a que Syncthing termine (mira el % de progreso en la app). |
| **Conflicto de archivo** | Syncthing crea una copia con `.sync-conflict` si hay edición simultánea. Resuelve manualmente o deleta una copia. |
| **App se congela** | Reinicia la app o el Syncthing en el servidor (`systemctl restart syncthing-root`). |

---

## Comandos útiles (servidor — CT 109)

```bash
# Ver estado del servicio
systemctl status syncthing-root

# Reiniciar Syncthing
systemctl restart syncthing-root

# Ver logs en vivo
journalctl -u syncthing-root -f

# Ver qué archivos se están sincronizando
curl -s -H "X-API-Key: kpgeNC4ztCDMKta2hkdpsgingyTjHFVh" \
  http://127.0.0.1:8384/rest/folder/default/status | python3 -m json.tool

# Ver dispositivos conectados
curl -s -H "X-API-Key: kpgeNC4ztCDMKta2hkdpsgingyTjHFVh" \
  http://127.0.0.1:8384/rest/system/connections | python3 -m json.tool
```

---

## Notas de seguridad

⚠️ **Importante:**
- **No edites archivos en `/00 System/` desde el móvil.** Esa carpeta contiene scripts y configuración que genera el servidor automáticamente.
- Los cambios en el móvil se sincronizan en tiempo real. Si editas una nota en el móvil y en la Mac simultáneamente, Syncthing creará un archivo de conflicto.
- El cifrado de Syncthing es automático entre dispositivos (TLS). La Web UI (`8384`) **no está cifrada** — úsala solo en tu red local.
- El `git commit` diario sigue funcionando con normalidad (el timer en CT 109 hace `git add -A && commit && push`).

---

## Control desde el navegador (opcional)

Si quieres ver el estado de la sincronización desde cualquier navegador en tu red:

1. En tu Mac o Android, abre: `http://192.168.0.64:8384/`
2. Te pedirá un API Key. Usa: `kpgeNC4ztCDMKta2hkdpsgingyTjHFVh`
3. Verás el dashboard con:
   - Estado de conexión (% de sincronización)
   - Dispositivos activos
   - Bandwidth actual
   - Últimos eventos

---

## Verificación Pre-Móvil (Servidor — YA HECHO ✅)

| Paso | Estado | Detalle |
|------|--------|---------|
| 1. Syncthing instalado | ✅ | Ubuntu 26.04 x86_64, versión actual |
| 2. Servicio activo | ✅ | `systemctl status syncthing-root` → active (running) |
| 3. Folder configurado | ✅ | Path: `/root/JarvisVault`, Type: `sendreceive` |
| 4. .stignore activo | ✅ | Excluye `.obsidian/` (683 MB), `.git/`, binarios |
| 5. Firewall UFW | ✅ | Puertos 22000-22001/tcp+udp, 21027/udp, 8384/tcp abiertos |
| 6. WebUI accesible | ✅ | `http://192.168.0.64:8384/` responde HTTP 200 |
| 7. Device ID | ✅ | `N2D24W3-SJVNDFR-YKVJ5AJ-I4FPASQ-L6ZZL7F-47K6KNS-5VJX7JL-3OGW3QW` |
| 8. Tamaño a sincronizar | ✅ | ~44 MB (notas + proyectos) |

---

## Checklist Post-Setup (Android)

Después de instalar y conectar en tu móvil, verifica:

- [ ] **App instalada:** Syncthing en Play Store
- [ ] **Device agregado:** Device ID copiado y pegado correctamente (56 caracteres)
- [ ] **Folder aceptado:** Notificación del servidor aceptada
- [ ] **Sincronización iniciada:** App muestra % de progreso
- [ ] **Sincronización completada:** Dice "Synced" o "Up to Date" en el folder
- [ ] **Contenido visible:** Carpetas (00 Notes, 03 Projects, etc.) aparecen en el móvil
- [ ] **Editar en móvil:** Crea/edita una nota en el móvil
- [ ] **Verificar en Mac:** Abre el vault en Mac y confirma que la nota esté ahí
- [ ] **Obsidian instalado (opcional):** Descarga Obsidian Mobile y abre el vault

---

## Roadmap

- [ ] Instalar Syncthing en Android (hoy)
- [ ] Verificar que Android se conecte correctamente (hoy)
- [ ] Probar editar una nota en el móvil y confirmar que aparezca en el Mac (hoy)
- [ ] (Opcional) Instalar Obsidian en el Android y abrir vault (cuando quieras)
- [ ] Revisar logs de Syncthing si hay conflictos (si aplica)

---

**Created:** 2026-09-17 by SatanZote AI  
**Firewall:** Configurado 2026-09-17 13:15 CST  
**Next review:** 2026-09-24 (después de primer uso en móvil)
