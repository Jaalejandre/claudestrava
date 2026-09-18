# Cómo obtener Cloudflare API Token (5 minutos)

## PASO 1: Crear/Verificar cuenta Cloudflare
1. Ve a https://dash.cloudflare.com
2. Si no tienes cuenta, crea una (email + contraseña)
3. Completa verificación de email

## PASO 2: Crear API Token
1. En Cloudflare Dashboard → My Account (esquina superior derecha)
2. Ir a **API Tokens** (en la barra lateral izquierda)
3. Click **Create Token**
4. Seleccionar preset: **Edit Cloudflare Workers**
   - O crear custom con permisos:
     - Account.Workers Scripts (read/write)
     - Account.R2 (read/write)
     - Zone.Workers (read/write)

5. Click **Create Token**
6. **COPIAR el token** (solo se muestra una vez)

## PASO 3: Guardar en Wrangler
```bash
# Opción A: Configuración interactiva (recomendado)
cd ~/JarvisVault/01\ Projects/DM UAMI/gromacs-analyzer-worker/
wrangler login

# Te abrirá navegador, autenticas, listo.

# Opción B: Token directo (si login no funciona)
wrangler config set api_token [PEGA_TU_TOKEN_AQUI]
```

## PASO 4: Crear R2 Bucket
```bash
wrangler r2 bucket create gromacs-storage
```

## PASO 5: Desplegar
```bash
wrangler deploy
```

---

**¿Ya tienes el token?**
Si sí, cópialo aquí y continúo el deploy.
