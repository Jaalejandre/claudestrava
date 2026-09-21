#!/usr/bin/env bash
# (C) gpu-log-bridge.sh — Postea resultados del orchestrator al log central
# Uso: gpu-log-bridge.sh <job_id> <status> <duration_s> <gpu_id> <result_msg>

LOG_FILE="/root/JarvisVault/00_System/logs/$(date +%Y-%m-%d).jsonl"
JOB_ID="${1:-unknown}"
STATUS="${2:-done}"
DURATION="${3:-0}"
GPU="${4:-none}"
RESULT="${5:-no result}"

# Escapar comillas para JSON
RESULT_ESC=$(echo "$RESULT" | sed 's/"/\\"/g')

ENTRY=$(cat <<EOF
{"ts":"$(date -Iseconds)","team":"ai-agentes","task":"swarm-gpu","worker_id":"gpu-orchestrator","status":"$STATUS","duration_s":$DURATION,"gpu_used":"$GPU","result":"$RESULT_ESC"}
EOF
)

echo "$ENTRY" >> "$LOG_FILE"
echo "Logged: $ENTRY"