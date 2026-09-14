#!/bin/sh
# wrom0..wrom3 icin KOLON BASINA cevrim ENERJISI, uc kosede.
#
# NEDEN ENERJI: Liberty `internal_power` = anahtarlama basina ENERJI (pJ),
# guc degil. Frekansi guc araci uygular (P = E*f*aktivite), bu yuzden
# frekans bilmeye gerek yok. Dogrulandi: TCLK 200n -> 400n degistiginde
# cevrim yuku sadece %3.3 degisti (2026-09-05).
#
# Kullanim: asic/scripts/rom_char/run_col_energy.sh

set -e
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$REPO_ROOT"
NG="${NGSPICE_BIN:-/nix/store/4ssrcgdvyb8car0yxay8cwfa5wc89f1w-ngspice-45/bin/ngspice}"
GEN=asic/scripts/rom_char/gen_col_power_tb.py

printf "%-7s %-4s %12s %12s %10s %14s\n" makro kose "E_kol(pJ)" "E_264(pJ)" "c2/c3(%)" "P@fmax(mW)"
for row in "wrom0:236" "wrom1:214" "wrom2:236" "wrom3:10"; do
  m=${row%%:*}; col=${row##*:}
  for ck in "tt:1.8:25:38.2" "ss:1.6:100:19.1" "ff:1.95:-40:60.7"; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3); f=$(echo "$ck" | cut -d: -f4)
    sp="asic/macros/$m/char/col${col}_energy_${c}.sp"
    lg="asic/macros/$m/char/col${col}_energy_${c}.log"
    python3 $GEN "$m" "$col" active "$sp" --corner "$c" --vdd "$v" --temp "$t" >/dev/null
    $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true
    q2=$(grep -m1 "q_c2 " "$lg" | awk '{print $3}')
    q3=$(grep -m1 "q_c3 " "$lg" | awk '{print $3}')
    if [ -z "$q3" ]; then
      printf "%-7s %-4s %12s\n" "$m" "$c" "OLCULEMEDI"; continue
    fi
    python3 -c "
q2=abs(float('$q2')); q3=abs(float('$q3')); v=float('$v'); f=float('$f')
e=q3*v*1e12          # pJ / kolon / cevrim
e264=e*256           # pJ / okuma (tum kolonlar; 256 = 32 bit x wpr 8)
settle=abs(q2-q3)/q3*100
pmw=e264*1e-12*f*1e6*1e3   # pJ*MHz -> mW
print(f'{\"$m\":<7} {\"$c\":<4} {e:>12.4f} {e264:>12.2f} {settle:>10.1f} {pmw:>14.3f}')"
  done
done
echo
echo "NOT: bu sayilar KOLON DIZISI icin. Kod cozucu/tampon/mux/kontrol"
echo "     (cevre birimi) enerjisi DAHIL DEGIL -- ayrica olculmeli."
