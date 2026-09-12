#!/bin/bash
# retoma_tokens.sh v3 — CT 109. Disparado por retoma-tokens.timer (2026-09-11 15:45).
# APPROACH (cambio de José, 13:30): análisis = SatanZote AI (ya hecho en la sesión Copilot).
# Programación = claude headless (Sonnet) en CT 901 con el brief de programación.
# 1) Probe tokens (15:45 -> 16:15, reintentos cada 2 min)
# 2) Enviar brief a CT 901
# 3) Lanzar Sonnet headless en CT 901 (nohup + timeout 90 min)
# 4) Monitorear y avisar por Telegram

PVE=root@192.168.0.52
BRIEF_SRC="/root/JarvisVault/03 Projects/GromacsMexicano/04 System/(C) brief-programacion-headless.md"
WORKDIR=/home/alejandre/UAMI_Source
LOG=/tmp/retoma_$(date +%H%M).log
exec >"$LOG" 2>&1

tx() { ssh "$PVE" "pct exec 901 -- su - alejandre -c './notify_telegram.sh \"$1\"'" >/dev/null 2>&1; }
D=$(date "+%H:%M")

if [ ! -f "$BRIEF_SRC" ]; then
  tx "⚠️ $D: brief de programación NO existe — no se lanza nada."
  exit 1
fi

OK=""
for i in $(seq 1 15); do
  if cd /root && timeout 60 claude -p "ok" --max-turns 1 >/dev/null 2>&1; then
    OK=1; echo "Probe OK (intento $i)"; break
  fi
  echo "Probe falló ($i/15)"; sleep 120
done
if [ -z "$OK" ]; then
  tx "⏰ $D: tokens NO restablecidos tras 15 reintentos. Nada se lanzó."
  touch /root/.retoma_tokens_disparado_20260911
  exit 1
fi

# Brief -> CT 901 (el stdin atraviesa ssh -> pct exec)
cat "$BRIEF_SRC" | ssh "$PVE" "pct exec 901 -- bash -c 'cat > /tmp/brief.txt'"
if [ $? -ne 0 ]; then
  tx "⚠️ $D: falló el envío del brief a CT 901."
  exit 1
fi

tx "🔓 $D: tokens OK. Lanzando PROGRAMADOR headless (Sonnet) en CT 901 → $WORKDIR. Encargo: semilla configurable para validación bit a bit. Te aviso hitos y cierre."

# Lanzar Sonnet headless en CT 901 (nota: `\$(` se expande EN CT 901)
ssh "$PVE" "pct exec 901 -- su - alejandre -c 'cd $WORKDIR && nohup timeout 5400 claude -p \"\$(cat /tmp/brief.txt)\" --max-turns 150 --allowedTools \"Read,Grep,Glob,Edit,Write,Bash\" > /tmp/programador.log 2>&1 &'"
echo "Sonnet lanzado en CT 901."

# Monitor: esperar fin del proceso claude -p (máx 95 min)
END=$(( $(date +%s) + 5700 ))
while [ $(date +%s) -lt $END ]; do
  if ! ssh "$PVE" "pct exec 901 -- pgrep -f 'claude -p' >/dev/null" 2>/dev/null; then break; fi
  sleep 60
done

SUMMARY=$(ssh "$PVE" "pct exec 901 -- bash -c 'tail -6 /tmp/resumen_programador.md 2>/dev/null; echo; tail -3 /tmp/programador.log 2>/dev/null'" | tr "\n" " " | head -c 500)
tx "📦 $D: programador TERMINÓ. Resumen: $SUMMARY — Log completo: CT 901 /tmp/programador.log"
touch /root/.retoma_tokens_disparado_20260911
echo "=== Fin retoma $(date '+%F %T') ==="