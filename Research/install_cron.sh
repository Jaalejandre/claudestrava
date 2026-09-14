#!/bin/bash
# INSTALL CRON JOBS SCRIPT
# Instala los trabajos programados del Sistema de Innovación

set -e

REPO_PATH="/root/JarvisVault/Research"
CRON_SCRIPT="$REPO_PATH/cron_jobs/innovation_cycle_daily.sh"

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                                                                    ║"
echo "║   INNOVATION SYSTEM - CRON JOB INSTALLATION                       ║"
echo "║                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# Verificar que el script existe
if [ ! -f "$CRON_SCRIPT" ]; then
    echo "✗ Error: Cron script not found at $CRON_SCRIPT"
    exit 1
fi

echo "✓ Found cron script: $CRON_SCRIPT"

# Hacer el script ejecutable
chmod +x "$CRON_SCRIPT"
echo "✓ Made script executable"

# Crear entrada de crontab
CRON_ENTRY="0 9 * * * $CRON_SCRIPT"

# Verificar si ya existe
if crontab -l 2>/dev/null | grep -q "innovation_cycle_daily"; then
    echo "⚠ Cron job already installed"
    crontab -l | grep "innovation_cycle_daily"
else
    # Agregar nueva entrada
    (crontab -l 2>/dev/null || true; echo "$CRON_ENTRY") | crontab -
    echo "✓ Installed cron job: Daily at 09:00 AM"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║  Cron Job Installation Complete                                   ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# Mostrar detalles
echo "Cron Job Details:"
echo "  Schedule: 0 9 * * * (Daily at 9:00 AM)"
echo "  Script: $CRON_SCRIPT"
echo "  Log: /root/JarvisVault/Research/logs/innovation_cycle_*.log"
echo ""

# Verificar crontab
echo "Current crontab entry:"
crontab -l 2>/dev/null | grep "innovation_cycle_daily" || true

echo ""
echo "✓ Installation Complete"
echo ""
echo "To manually run the innovation cycle:"
echo "  bash $CRON_SCRIPT"
echo ""
echo "To view logs:"
echo "  tail -f /root/JarvisVault/Research/logs/innovation_cycle_*.log"
echo ""
