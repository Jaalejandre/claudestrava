#!/bin/bash
# (C) continuar-determinismo.sh — GromacsMexicano | determinismo md5 UAMI
# Continuación automática de la sesión del 2026-09-11 12:41 (corte de tokens, reset 15:40).
# Pregunta abierta: ¿el md5 distinto baseline vs opt es por el cambio de plomería
# o el código ya es no-determinista por los atomicAdd de CUDA?
# Experimento: 2 corridas baseline + 2 corridas opt, md5 de energy.dat de cada una.
# Sin uso de LLM (plomería pura). Corre en CT 109, mide en CT 901.
# Notifica por Telegram al inicio, en cada corrida y al final.

PVE=root@192.168.0.52
DIR=/home/alejandre/GromacsMexicano/Bench_UAMI_baseline
REF_MD5=add05c038cfb436153b9260a8b600437
RESUMEN="/root/JarvisVault/03 Projects/GromacsMexicano/03 Benchmarks/(C) 2026-09-11 determinismo md5 - resultados brutos.md"
TS=$(date +%Y%m%d_%H%M)
LOG=/tmp/determinismo_$TS.log
SUMMARY=/tmp/det_summary_$TS.tsv

exec >"$LOG" 2>&1

tx() { ssh "$PVE" "pct exec 901 -- su - alejandre -c './notify_telegram.sh \"$1\"'" >/dev/null 2>&1; }

echo "=== $TS Inicio experimento determinismo UAMI ==="

# Protocolo del proyecto: verificar CT 901 libre antes de medir
BLOCK=$(ssh "$PVE" "pct exec 901 -- bash -c 'ps aux | grep -E \"dm_mx_npt|gmx_mexicano\" | grep -v grep'")
if [ -n "$BLOCK" ]; then
  echo "ABORTADO: CT 901 ocupado -> $BLOCK"
  tx "⚠️ Determinismo UAMI ABORTADO: CT 901 ocupado ($BLOCK)"
  exit 1
fi
echo "CT 901 libre, arrancando."

run_one() {
  local bin=$1 tag=$2 t0 t1 secs md5
  t0=$(date +%s)
  ssh "$PVE" "pct exec 901 -- bash -c 'cd $DIR && rm -f energy.dat && /usr/bin/time -f \"%e\" -o $tag.time ./$bin > run_$tag.log 2>&1; cp energy.dat energy_$tag.dat; md5sum energy_$tag.dat > $tag.md5; head -3 energy.dat > $tag.head; echo done'"
  t1=$(date +%s)
  secs=$(ssh "$PVE" "pct exec 901 -- cat $DIR/$tag.time")
  md5=$(ssh "$PVE" "pct exec 901 -- cat $DIR/$tag.md5" | cut -d' ' -f1)
  echo "$tag | wall=$((t1-t0))s | time=$secs s | md5=$md5"
  echo -e "$tag\t$bin\t$((t1-t0))\t$secs\t$md5" >> "$SUMMARY"
}

tx "🚀 Determinismo UAMI arrancado: 2× baseline + 2× opt (≈12 min). Progreso 0/4"

run_one dm_mx_npt    base_run2;  tx "📊 Determinismo: baseline 1/2 (1/4)"
run_one dm_mx_npt    base_run3;  tx "📊 Determinismo: baseline lista (2/4)"
run_one dm_mx_npt_opt opt_run1;  tx "📊 Determinismo: opt 1/2 (3/4)"
run_one dm_mx_npt_opt opt_run2;  tx "📊 Determinismo: opt lista (4/4)"

# ---- Resumen factual en el vault (sin análisis, solo datos) ----
{
  echo "# (C) Determinismo md5 — 2026-09-11 (resultados brutos)"
  echo
  echo "Experimento lanzado automáticamente el 2026-09-11 ~13:05 (continuación tras corte de tokens de la sesión 12:41). Plomería pura, sin LLM. El ANÁLISIS se hace en la sesión de retoma."
  echo
  echo "Referencia: \`energy_baseline.dat\` md5 = \`$REF_MD5\` (corrida baseline previa, 181.45s)"
  echo
  echo "| corrida | binario | wall ssh (s) | time proceso (s) | md5 energy.dat |"
  echo "|---|---|---|---|---|"
  while IFS=$'\t' read -r tag bin wall secs md5; do
    echo "| \`$tag\` | \`$bin\` | $wall | $secs | \`$md5\` |"
  done < "$SUMMARY"
  echo
  echo "Logs: \`run_<tag>.log\` + \`<tag>.time\` + \`<tag>.head\` en \`Bench_UAMI_baseline/\` (CT 901)."
} > "$RESUMEN"
echo "Resumen escrito: $RESUMEN"

tx "✅ Determinismo UAMI terminado (4/4). Resumen en vault: (C) 2026-09-11 determinismo md5 - resultados brutos"
echo "=== Fin $(date '+%F %T') ==="