#!/bin/sh
# wrom0..wrom3 icin KOLON BASINA sizinti (.op) olcumu, uc kosede.
# Sonuc: <macro>/char/col<N>_leak_<kose>.log  +  ekrana ozet tablo.
#
# YONTEM NOTU: .op kullaniliyor, transient DEGIL. "uic"li transient'te
# dugumler 0'dan baslayip 85 transistorluk direncli zincirden yavasca
# doluyor; 600 ns'de bile oturmuyor (65->19->8.7 nA) ve sarj akimi
# sizinti sanilarak ~100x yuksek olculuyordu (2026-09-05'te dogrulandi).
#
# Kullanim: asic/scripts/rom_char/run_col_power.sh

set -e
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$REPO_ROOT"
NG="${NGSPICE_BIN:-/nix/store/4ssrcgdvyb8car0yxay8cwfa5wc89f1w-ngspice-45/bin/ngspice}"
GEN=asic/scripts/rom_char/gen_col_power_tb.py

printf "%-7s %-4s %14s %14s %14s\n" makro kose "I_kolon(nA)" "I_264kol(uA)" "P_264kol(uW)"
for row in "wrom0:236" "wrom1:214" "wrom2:236" "wrom3:10"; do
  m=${row%%:*}; col=${row##*:}
  for ck in "tt:1.8:25" "ss:1.6:100" "ff:1.95:-40"; do
    c=$(echo "$ck" | cut -d: -f1)
    v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)
    sp="asic/macros/$m/char/col${col}_leak_${c}.sp"
    lg="asic/macros/$m/char/col${col}_leak_${c}.log"
    python3 $GEN "$m" "$col" idle "$sp" --corner "$c" --vdd "$v" --temp "$t" >/dev/null
    $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true
    # .measure op sayisal cikti uretmiyor -> akimi .op tablosundan oku
    i=$(grep -m1 "vvdd#branch" "$lg" | awk '{print $2}')
    if [ -z "$i" ]; then
      printf "%-7s %-4s %14s\n" "$m" "$c" "OLCULEMEDI"
      continue
    fi
    python3 -c "
i=abs(float('$i')); v=float('$v')
print(f'{\"$m\":<7} {\"$c\":<4} {i*1e9:>14.4f} {i*256*1e6:>14.4f} {i*256*v*1e6:>14.4f}')"
  done
done
