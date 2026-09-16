#!/bin/sh
# KOLON BASINA sizinti (.op) olcumu, uc kosede.
# Sonuc: <makro>/char/col<N>_leak_<kose>.log  +  ekrana ozet tablo.
#
# YONTEM NOTU: .op kullaniliyor, transient DEGIL. "uic"li transient'te
# dugumler 0'dan baslayip onlarca transistorluk direncli zincirden yavasca
# doluyor; 600 ns'de bile oturmuyor (65->19->8.7 nA) ve sarj akimi
# sizinti sanilarak ~100x yuksek olculuyordu (2026-09-05'te dogrulandi).
#
# En kotu kolon ve kolon SAYISI netlistten turetilir (rom_paths.py) --
# eskiden ikisi de bu dosyada sabitti ("wrom0:236", carpan 256) ve ROM
# yeniden uretilince sessizce yanlis kaliyordu.
#
# Kullanim: scripts/rom_char/run_col_power.sh [makro ...]

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
GEN="$ROM_CHAR_DIR/gen_col_power_tb.py"

printf "%-7s %-4s %14s %14s %14s\n" makro kose "I_kolon(nA)" "I_tum(uA)" "P_tum(uW)"
for m in $(macro_list "$@"); do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)
    sp="$G_CHAR/${G_COLTAG}_leak_${c}.sp"
    lg="$G_CHAR/${G_COLTAG}_leak_${c}.log"
    python3 "$GEN" "$m" "$G_WORST_COL" idle "$sp" --corner "$c" --vdd "$v" --temp "$t" >/dev/null
    $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true
    # .measure op sayisal cikti uretmiyor -> akimi .op tablosundan oku
    i=$(grep -m1 "vvdd#branch" "$lg" | awk '{print $2}')
    if [ -z "$i" ]; then
      printf "%-7s %-4s %14s\n" "$m" "$c" "OLCULEMEDI"
      continue
    fi
    echo "$i" | awk -v m="$m" -v c="$c" -v n="$G_COLS" -v v="$v" \
      '{ i = $1 < 0 ? -$1 : $1;
         printf "%-7s %-4s %14.4f %14.4f %14.4f\n", m, c, i*1e9, i*n*1e6, i*n*v*1e6 }'
  done
done
echo
echo "NOT: I_tum/P_tum = kolon degeri x kolon sayisi (netlistten sayildi)."
