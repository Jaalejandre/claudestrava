#!/bin/bash
# (C) comparar-determinismo.sh — GromacsMexicano | comparación numérica por paso (sin LLM)
# Corre en CT 109. Espera a que continuar-determinismo.sh termine y compara
# los energy.dat por pares: filas bit-iguales vs distintas, max abs/rel delta por columna.
# Escribe la nota (C) 2026-09-11 determinismo - comparación numérica por paso.md en el vault.
# Notifica por Telegram al terminar.

PVE=root@192.168.0.52
DIR=/home/alejandre/GromacsMexicano/Bench_UAMI_baseline
NOTE="/root/JarvisVault/03 Projects/GromacsMexicano/03 Benchmarks/(C) 2026-09-11 determinismo - comparación numérica por paso.md"
OUT=/tmp/comparacion_det.txt
TS=$(date +%Y%m%d_%H%M)
LOG=/tmp/comparacion_$TS.log

exec >"$LOG" 2>&1

tx() { ssh "$PVE" "pct exec 901 -- su - alejandre -c './notify_telegram.sh \"$1\"'" >/dev/null 2>&1; }

echo "=== $TS Esperando a que termine el experimento (máx 40 min) ==="

N=0
for i in $(seq 1 80); do
  N=$(ssh "$PVE" "pct exec 901 -- ls $DIR/base_run3.md5 $DIR/opt_run2.md5 2>/dev/null | wc -l")
  if [ "$N" -ge 2 ]; then break; fi
  sleep 30
done

if [ "$N" -lt 2 ]; then
  echo "ABORTADO: el experimento no terminó a tiempo"
  tx "⚠️ Comparación numérica ABORTADA: el experimento de determinismo no terminó a tiempo (revisar /tmp/determinismo_*.log)"
  exit 1
fi
echo "Experimento terminado, trayendo archivos."

for t in base_run2 base_run3 opt_run1 opt_run2; do
  ssh "$PVE" "pct exec 901 -- cat $DIR/energy_$t.dat" > /tmp/energy_$t.dat
done
ssh "$PVE" "pct exec 901 -- cat $DIR/energy_baseline.dat" > /tmp/energy_ref.dat

{
  echo "# (C) Determinismo — comparación numérica por paso (2026-09-11)"
  echo
  echo "Generada automáticamente por \`comparar-determinismo.sh\` (plomería, sin LLM)."
  echo
  echo "## Cabeceras de energy.dat (para saber qué es cada columna)"
  for t in base_run2 base_run3 opt_run1 opt_run2; do
    echo
    echo "### $t"
    head -2 /tmp/energy_$t.dat
  done
} > "$OUT"

compare_pair() {
  local a=$1 b=$2
  paste /tmp/energy_$a.dat /tmp/energy_$b.dat | awk -v a=$a -v b=$b '
    NR==1 { next }
    $1 !~ /^[-+0-9.]/ { next }
    {
      rows++
      half = NF/2
      for (i = 1; i <= half; i++) {
        j = i + half
        if ($i == $j) { same++ }
        else {
          diff++
          d = $i - $j; ad = d < 0 ? -d : d
          ma = $i < 0 ? -$i : $i; mb = $j < 0 ? -$j : $j
          base = ma > mb ? ma : mb
          if (ad > max_abs) { max_abs = ad; ca = i }
          if (base > 1e-30) { rd = ad / base; if (rd > max_rel) { max_rel = rd; cr = i } }
        }
      }
    }
    END {
      if (max_abs == "") max_abs = 0
      if (max_rel == "") max_rel = 0
      printf "| `%s` vs `%s` | %d | %d | %d | %.3e (col %d) | %.3e (col %d) |\n", a, b, rows, same, diff, max_abs, ca, max_rel, cr
    }'
}

{
  echo
  echo "## Comparación por pares (campos = valores individuales en el archivo)"
  echo
  echo "| par | filas de datos | campos bit-iguales | campos distintos | max abs delta | max rel delta |"
  echo "|---|---|---|---|---|---|"
  compare_pair base_run2 base_run3
  compare_pair opt_run1 opt_run2
  compare_pair base_run2 opt_run1
  compare_pair base_run3 opt_run2
  compare_pair base_run2 ref
} >> "$OUT"

cp "$OUT" "$NOTE"
echo "Nota escrita: $NOTE"
tx "📐 Comparación numérica por paso LISTA. Pares clave: baseline vs baseline (¿determinista?) y baseline vs opt (¿cuánto difiere?). Detalle en: 03 Benchmarks/(C) 2026-09-11 determinismo - comparación numérica por paso.md"
echo "=== Fin $(date '+%F %T') ==="