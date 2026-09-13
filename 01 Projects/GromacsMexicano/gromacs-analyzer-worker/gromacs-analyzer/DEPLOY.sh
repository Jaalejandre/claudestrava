#!/bin/bash
# Deploy Gromacs Worker — Script para ejecutar en CT 109

set -e

echo '========================================='
echo '🚀 DESPLEGAR GROMACS WORKER'
echo '========================================='
echo ''

# Ruta del proyecto
PROJECT_DIR="$HOME/JarvisVault/01 Projects/GromacsMexicano/gromacs-analyzer-worker"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "❌ ERROR: Proyecto no encontrado en $PROJECT_DIR"
  exit 1
fi

cd "$PROJECT_DIR"

echo '1️⃣  Configurar token Cloudflare'
echo ''
echo 'OPCIÓN A: Usar wrangler login (recomendado)'
echo '  wrangler login'
echo ''
echo 'OPCIÓN B: Usar token directo'
echo '  export CLOUDFLARE_API_TOKEN="cfut_REDACTED"'
echo ''
read -p 'Presiona ENTER cuando hayas configurado el token... '

echo ''
echo '========================================='
echo '2️⃣  Crear R2 Bucket'
echo '========================================='
echo ''

wrangler r2 bucket create gromacs-storage 2>&1 || echo '⚠️  Bucket puede que ya exista'

echo ''
echo '========================================='
echo '3️⃣  DESPLEGAR WORKER'
echo '========================================='
echo ''

wrangler deploy

echo ''
echo '========================================='
echo '✅ DEPLOY COMPLETO'
echo '========================================='
echo ''
echo 'Tu Worker está en:'
echo '  https://gromacs-analyzer.satanzote.workers.dev'
echo ''
echo 'Prueba:'
echo '  curl https://gromacs-analyzer.satanzote.workers.dev'
echo ''
echo 'Dashboard:'
echo '  https://dash.cloudflare.com/workers/gromacs-analyzer'
echo ''
