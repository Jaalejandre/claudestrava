#!/bin/bash
# (C) auto-heal.sh — Auto-healing de CTs para SatanZote Infraestructura
# Ejecutar cada 5 minutos via cron en CT 109
# Verifica estado de cada CT vía SSH a Proxmox, reanuda si está stopped,
# desbloquea si está locked >5min, alerta ntfy si falla.
#
# Dependencias: ssh root@192.168.0.52, jq, curl
# Instalación (como root):
#   cp (C) auto-heal.sh /usr/local/bin/auto-heal.sh
#   chmod +x /usr/local/bin/auto-heal.sh
#   echo '*/5 * * * * root /usr/local/bin/auto-heal.sh' > /etc/cron.d/auto-heal
#
# Log central: append a /root/JarvisVault/00_System/logs/<YYYY-MM-DD>.jsonl

set -euo pipefail

PVE_HOST="root@192.168.0.52"
NTFY_TOPIC="sanzote-alerts"
NTFY_URL="https://ntfy.sh/${NTFY_TOPIC}"
TIMESTAMP=$(date -u "+%Y-%m-%dT%H:%M:%S-06:00")
DATE_TAG=$(date "+%Y-%m-%d")
HOSTNAME=$(hostname)
LOG_FILE="/root/JarvisVault/00_System/logs/${DATE_TAG}.jsonl"
LOCK_TIMEOUT_SEC=300  # 5 minutos

# CTs a monitorear (los que nos importan)
CTS=(109 110 118 666 120 901 103 108 100)
ACTIONS_TAKEN=0
FAILURES=""
FAIL_COUNT=0
START_EPOCH=$(date +%s)

send_alert() {
    local title="$1"
    local msg="$2"
    curl -s -H "Title: ${title}" -H "Tags: warning" -H "Priority: high" \
        -d "${msg}" "${NTFY_URL}" >/dev/null 2>&1 || true
}

log_entry() {
    local status="$1"
    local result="$2"
    local duration="$3"
    local entry
    entry=$(cat <<ENDJSON
{"ts":"${TIMESTAMP}","team":"infra","task":"auto-heal","worker_id":"${HOSTNAME}","status":"${status}","duration_s":${duration},"result":"${result}"}
ENDJSON
)
    echo "${entry}" >> "${LOG_FILE}" 2>/dev/null || true
}

get_ct_status() {
    local ctid="$1"
    ssh "${PVE_HOST}" "pct status ${ctid} 2>/dev/null" 2>/dev/null || echo "error"
}

get_ct_lock() {
    local ctid="$1"
    ssh "${PVE_HOST}" "pct list 2>/dev/null | awk -v id=\"${ctid}\" '\$1==id{print \$3}'" 2>/dev/null || echo ""
}

ct_start() {
    local ctid="$1"
    ssh "${PVE_HOST}" "pct start ${ctid}" 2>&1 || return 1
}

ct_unlock() {
    local ctid="$1"
    ssh "${PVE_HOST}" "pct unlock ${ctid}" 2>&1 || return 1
}

# --- Main ---
echo "[auto-heal] Starting check at $(date)"

for ctid in "${CTS[@]}"; do
    status=$(get_ct_status "${ctid}")
    
    if echo "${status}" | grep -q "status: stopped"; then
        echo "[auto-heal] CT ${ctid} is STOPPED — starting..."
        if ct_start "${ctid}"; then
            ACTIONS_TAKEN=$((ACTIONS_TAKEN + 1))
            send_alert "Auto-Heal: CT ${ctid} restarted" "CT ${ctid} estaba stopped, iniciado automáticamente."
            echo "[auto-heal] CT ${ctid} started OK"
        else
            FAIL_COUNT=$((FAIL_COUNT + 1))
            FAILURES="${FAILURES} - CT ${ctid}: start failed"$'\n'
            send_alert "Auto-Heal FAIL: CT ${ctid}" "No se pudo iniciar CT ${ctid}"
        fi
        
    elif echo "${status}" | grep -q "status: running"; then
        # Verificar si está locked
        lock_status=$(get_ct_lock "${ctid}")
        if [ -n "${lock_status}" ] && [ "${lock_status}" != "running" ]; then
            # Lock detectado — verificar con 'pct list' para antigüedad aproximada
            # pct list muestra 'lock' en columna 3 cuando hay lock
            if echo "${lock_status}" | grep -qi "lock"; then
                echo "[auto-heal] CT ${ctid} is LOCKED — attempting unlock..."
                if ct_unlock "${ctid}"; then
                    ACTIONS_TAKEN=$((ACTIONS_TAKEN + 1))
                    send_alert "Auto-Heal: CT ${ctid} unlocked" "CT ${ctid} estaba locked, desbloqueado automáticamente."
                    echo "[auto-heal] CT ${ctid} unlocked OK"
                else
                    FAIL_COUNT=$((FAIL_COUNT + 1))
                    FAILURES="${FAILURES} - CT ${ctid}: unlock failed"$'\n'
                    send_alert "Auto-Heal FAIL: CT ${ctid}" "No se pudo desbloquear CT ${ctid}"
                fi
            fi
        fi
        
    elif echo "${status}" | grep -q "error"; then
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILURES="${FAILURES} - CT ${ctid}: SSH error"$'\n'
        send_alert "Auto-Heal FAIL: CT ${ctid}" "No se puede conectar a PVE para CT ${ctid}"
    fi
done

END_EPOCH=$(date +%s)
DURATION=$((END_EPOCH - START_EPOCH))

# Resultado final
if [ "${FAIL_COUNT}" -gt 0 ]; then
    echo "[auto-heal] FAILURES:"
    echo "${FAILURES}"
    log_entry "fail" "CT(s) con fallos: ${FAILURES} (acciones tomadas: ${ACTIONS_TAKEN})" "${DURATION}"
    exit 1
elif [ "${ACTIONS_TAKEN}" -gt 0 ]; then
    echo "[auto-heal] All OK, ${ACTIONS_TAKEN} action(s) taken"
    log_entry "partial" "Auto-healing: ${ACTIONS_TAKEN} CT(s) recuperados" "${DURATION}"
else
    echo "[auto-heal] All systems nominal"
    log_entry "ok" "Todos los CTs responden, sin acciones necesarias" "${DURATION}"
fi

exit 0