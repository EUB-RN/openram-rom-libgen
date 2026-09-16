#!/bin/sh
# KOLON BASINA cevrim ENERJISI, uc kosede.
#
# NEDEN ENERJI: Liberty `internal_power` = anahtarlama basina ENERJI (pJ),
# guc degil. Frekansi guc araci uygular (P = E*f*aktivite), bu yuzden
# frekans bilmeye gerek yok. Dogrulandi: TCLK 200n -> 400n degistiginde
# cevrim yuku sadece %3.3 degisti (2026-09-05).
#
# En kotu kolon ve kolon SAYISI netlistten turetilir (rom_paths.py).
#
# Kullanim: scripts/rom_char/run_col_energy.sh [makro ...]

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
GEN="$ROM_CHAR_DIR/gen_col_power_tb.py"

printf "%-7s %-4s %12s %12s %10s %14s\n" \
       makro kose "E_kol(pJ)" "E_tum(pJ)" "c2/c3(%)" "P@fmax(mW)"
for m in $(macro_list "$@"); do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3); f=$(echo "$ck" | cut -d: -f4)
    sp="$G_CHAR/${G_COLTAG}_energy_${c}.sp"
    lg="$G_CHAR/${G_COLTAG}_energy_${c}.log"
    python3 "$GEN" "$m" "$G_WORST_COL" active "$sp" --corner "$c" --vdd "$v" --temp "$t" >/dev/null
    $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true
    q2=$(meas "$lg" q_c2)
    q3=$(meas "$lg" q_c3)
    if [ -z "$q3" ]; then
      printf "%-7s %-4s %12s\n" "$m" "$c" "OLCULEMEDI"; continue
    fi
    echo "$q2 $q3" | awk -v m="$m" -v c="$c" -v v="$v" -v f="$f" -v n="$G_COLS" '
      { q2 = ($1 < 0 ? -$1 : $1); q3 = ($2 < 0 ? -$2 : $2);
        e    = q3*v*1e12;                 # pJ / kolon / cevrim
        etot = e*n;                       # pJ / okuma (tum kolonlar)
        settle = q3 ? (q2-q3 < 0 ? q3-q2 : q2-q3)/q3*100 : 0;
        pmw  = etot*1e-12*f*1e6*1e3;      # pJ x MHz -> mW
        printf "%-7s %-4s %12.4f %12.2f %10.1f %14.3f\n", m, c, e, etot, settle, pmw }'
  done
done
echo
echo "NOT: bu sayilar KOLON DIZISI icin. Kod cozucu/tampon/mux/kontrol"
echo "     (cevre birimi) enerjisi DAHIL DEGIL -- run_periphery_power.sh."
