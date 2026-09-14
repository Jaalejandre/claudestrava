#!/bin/bash
# INNOVATION SYSTEM DAILY CRON JOB
# Ejecuta ciclo completo: E25 → E26 → E27 + E24 Info Broker
# Schedule: 0 9 * * * (Daily at 9:00 AM)

set -e

REPO_PATH="/root/JarvisVault/Research"
LOG_DIR="$REPO_PATH/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/innovation_cycle_${TIMESTAMP}.log"

# Crear directorio de logs si no existe
mkdir -p "$LOG_DIR"

echo "═══════════════════════════════════════════════════════" >> "$LOG_FILE"
echo "INNOVATION SYSTEM - DAILY CRON JOB" >> "$LOG_FILE"
echo "Start Time: $(date)" >> "$LOG_FILE"
echo "═══════════════════════════════════════════════════════" >> "$LOG_FILE"

# Ir a repo
cd "$REPO_PATH"

# Git: Asegurar clean state
echo "[GIT] Ensuring clean working directory..." >> "$LOG_FILE"
git status >> "$LOG_FILE" 2>&1 || true

# Ejecutar orchestrator
echo "" >> "$LOG_FILE"
echo "[ORCHESTRATOR] Starting innovation cycle..." >> "$LOG_FILE"
python3 "$REPO_PATH/innovation_orchestrator.py" >> "$LOG_FILE" 2>&1

# Git: Commit resultados
echo "" >> "$LOG_FILE"
echo "[GIT] Committing cycle results..." >> "$LOG_FILE"
git add -A
git commit -m "Innovation cycle ${TIMESTAMP}: E25→E26→E27 complete" >> "$LOG_FILE" 2>&1 || true

# Info Broker: Procesar decisiones
echo "" >> "$LOG_FILE"
echo "[INFO_BROKER] Processing notifications..." >> "$LOG_FILE"
python3 "$REPO_PATH/info_broker.py" >> "$LOG_FILE" 2>&1

# Limpiar logs antiguos (mantener últimos 30 días)
echo "" >> "$LOG_FILE"
echo "[CLEANUP] Removing logs older than 30 days..." >> "$LOG_FILE"
find "$LOG_DIR" -name "innovation_cycle_*.log" -mtime +30 -delete >> "$LOG_FILE" 2>&1

echo "" >> "$LOG_FILE"
echo "═══════════════════════════════════════════════════════" >> "$LOG_FILE"
echo "End Time: $(date)" >> "$LOG_FILE"
echo "STATUS: COMPLETE ✓" >> "$LOG_FILE"
echo "═══════════════════════════════════════════════════════" >> "$LOG_FILE"

# Email notificación (si está configurado)
if command -v mail &> /dev/null; then
    mail -s "Innovation Cycle Complete - $(date +%Y-%m-%d)" admin@company.com < "$LOG_FILE"
fi

exit 0
