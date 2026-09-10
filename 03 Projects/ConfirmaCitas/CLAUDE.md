---
proyecto: ConfirmaCitas
estado: en producción (fase 1)
ct: 109
puerto: 8090
dominio: citas.satanzote.me
stack: Flask + Google Calendar API + SQLite
actualizado: 2026-09-10
---

# ConfirmaCitas

Dashboard móvil para que la doctora (esposa de José) confirme, cancele y reagende citas desde Google Calendar. Fase 1: wa.me links — ella presiona enviar. Fase 2 (futura): automatización completa con WhatsApp Business API oficial.

## Contexto

- 5-8 pacientes/día en consultorio
- Usa Google Calendar (varios calendarios, el de citas es "Family" creado por Laura Bernal)
- WhatsApp Business verificado (palomita azul) → NO usar librerías no oficiales en Fase 2
- Hoy en pruebas con cuenta de José. Producción: cuenta de la doctora

## Stack

| Componente | Detalle |
|---|---|
| App | Flask, Python 3, `/project/confirma-citas/app.py` |
| DB | SQLite `/project/confirma-citas/confirma_citas.db` |
| Auth | OAuth 2.0 Google (Desktop app), token en `token.json` |
| Credentials | `credentials.json` (Desktop) + `credentials_desktop.json` |
| Systemd | `confirma-citas.service` (CT 109, activo) |
| URL local | `http://192.168.0.64:8090` |
| URL pública | `https://citas.satanzote.me` (funcionando) |

## Funcionalidades (Fase 1)

- Dashboard muestra citas de **mañana** del calendario seleccionado
- Mensaje de WhatsApp editable por cita antes de enviar
- wa.me link → abre WhatsApp con texto precargado → ella envía
- Estado por cita: Pendiente → Enviado → Confirmado / Cancelado / Reagendado
- Al cambiar estado → Google Calendar se actualiza automáticamente (emojis ✅/❌/🔄 en título)
- Reagendar: cancela evento actual + crea nuevo evento en Calendar
- Agenda de pacientes: nombre + teléfono en SQLite (se captura primera vez)
- Google Meet: si el evento tiene Meet link, se incluye en el mensaje automáticamente
- Selector de calendario: `http://192.168.0.64:8090/setup`

## Template de mensaje

```
Hola {nombre}, tenemos consulta programada para el día de mañana a las {hora}, ¿queda confirmada?
[Si tiene Meet: \n\nEnlace de Meet: {url}]
```

## Rutas

| Ruta | Función |
|---|---|
| `/` | Dashboard principal (citas de mañana) |
| `/setup` | Selector de calendario de Google |
| `/pacientes` | Agenda de pacientes (nombre + teléfono) |
| `/login` | Inicia OAuth con Google |
| `/oauth2callback` | Callback OAuth |

## Para ir a producción (cuenta de la doctora)

1. Google Cloud Console → Pantalla de consentimiento → Usuarios de prueba → agregar su correo
2. `ssh root@192.168.0.64 "cd /project/confirma-citas && python3 auth.py"` → autorizar con su cuenta
3. `/setup` → seleccionar su calendario de pacientes

## Pendientes

- [ ] Autorizar con cuenta real de la doctora
- [ ] Seleccionar calendario correcto en producción
- [ ] Fase 2: WhatsApp Business API oficial (360dialog ~$5/mes)

## Decisiones de diseño

- **Doctoralia**: no tiene API pública → no se integra. Si tiene iCal export, puede sincronizarse a Google Calendar como fuente adicional (lectura solo)
- **SQLite local**: nombre + teléfono de pacientes, se agrega la primera vez que aparece una cita
- **Google OAuth tipo Desktop**: las IPs privadas no son válidas como redirect URI en Web apps. Desktop usa localhost y funciona con tunnel temporal para auth única
- **Token.json**: dura indefinidamente mientras no se revoque. Solo se genera una vez por cuenta

## Archivos del proyecto

```
/project/confirma-citas/
├── app.py                  # Flask app principal
├── auth.py                 # Script de autorización única (corre una vez)
├── credentials.json        # OAuth Web client (no usado actualmente)
├── credentials_desktop.json # OAuth Desktop client (el que funciona)
├── token.json              # Token generado tras autorizar
├── confirma_citas.db       # SQLite: pacientes, citas, config
└── templates/
    ├── index.html          # Dashboard principal
    ├── pacientes.html      # Agenda
    └── setup.html          # Selector de calendario
```

## Notas

- El nombre del proyecto en Google Cloud Console es `AgendarCitas` (viejo intento) y `ConfirmaCitas` (el actual)
- `OAUTHLIB_INSECURE_TRANSPORT=1` está en el systemd service — necesario porque Flask corre en HTTP localmente
