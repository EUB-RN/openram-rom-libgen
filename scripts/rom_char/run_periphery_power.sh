#!/bin/sh
# wrom0..wrom3 icin CEVRE BIRIMI (periphery) cevrim enerjisi, uc kosede.
#
# NEDEN: .lib'deki clk0 internal_power bloklarinda `when : "!cs0"` eksikti.
# cs0 yalnizca on-sarj yolunu kapatir (precharge = ~NAND(cs0, clk_int));
# saat surucusu ve satir kod cozucu clk_int ile surulur, cs0'dan BAGIMSIZ.
# Yani makro secili degilken de her cevrimde saat agaci, adres tamponlari,
# kod cozucu ve 128 wordline anahtarlanir. Eksik blok OpenSTA'da hata veya
# uyari uretmez -- o durumu sessizce 0 sayar.
#
# YONTEM: gen_col_power_tb.py'nin "dilim x adet" yaklasiminin aynisi.
# 34320 transistorluk hucre dizisi SIMULE EDILMEZ; silinir ve yuku
# (wordline basina 264 hucre kapisi + parazitik tel C) lump olarak geri
# konur. Simule edilen devre ~2660 cihaz.
#   Adim 1: hucre basina esdeger kapi kapasitansi (tek cihaz, saniyeler)
#   Adim 2: cevre birimi cevrim enerjisi (cs0=0 ve cs0=1)
#
# cs0=0 -> `when : "!cs0"` degeri; dogrudan --energy-idle-pj ile .lib'e.
# cs0=1 -> aktif cevrimin CEVRE BIRIMI payi. .lib'e yazilacak `when : "cs0"`
#          degeri = 264 x E_kolon (run_col_energy.sh) + BU deger.
#
# Kosum basina ~6 dk (neredeyse tamami netlist acma); JOBS kadari paralel.
#
# Kullanim: asic/scripts/rom_char/run_periphery_power.sh [makro ...]
#           JOBS=4 asic/scripts/rom_char/run_periphery_power.sh wrom0

set -e
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$REPO_ROOT"
NG="${NGSPICE_BIN:-/nix/store/4ssrcgdvyb8car0yxay8cwfa5wc89f1w-ngspice-45/bin/ngspice}"
GENP=asic/scripts/rom_char/gen_periphery_power_tb.py
GENC=asic/scripts/rom_char/gen_cell_gate_tb.py
MACROS="${*:-wrom0 wrom1 wrom2 wrom3}"
JOBS="${JOBS:-4}"

# --- Adim 1: hucre esdeger kapi kapasitansi ------------------------------
echo "== Adim 1: hucre esdeger kapi kapasitansi (C = Q(VDD)/VDD) =="
for m in $MACROS; do
  for ck in "tt:1.8:25" "ss:1.6:100" "ff:1.95:-40"; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)
    sp="asic/macros/$m/char/cellgate_${c}.sp"
    lg="asic/macros/$m/char/cellgate_${c}.log"
    python3 $GENC "$m" "$sp" --corner "$c" --vdd "$v" --temp "$t" >/dev/null
    $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true
    cg=$(grep -m1 "c_one_ff" "$lg" | awk '{print $3}')
    printf "  %-7s %-4s C_esd = %s fF/hucre\n" "$m" "$c" "${cg:-OLCULEMEDI}"
  done
done

# --- Adim 2: cevre birimi enerjisi --------------------------------------
echo
echo "== Adim 2: cevre birimi cevrim enerjisi =="
n=0
for m in $MACROS; do
  for ck in "tt:1.8:25" "ss:1.6:100" "ff:1.95:-40"; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)
    cg=$(grep -m1 "c_one_ff" "asic/macros/$m/char/cellgate_${c}.log" | awk '{print $3}')
    [ -z "$cg" ] && { echo "  $m $c: C_esd yok, atlandi"; continue; }
    for cs in 0 1; do
      tag=$([ "$cs" = 0 ] && echo idle || echo active)
      sp="asic/macros/$m/char/periph_${tag}_${c}.sp"
      lg="asic/macros/$m/char/periph_${tag}_${c}.log"
      python3 $GENP "$m" "$cs" "$sp" --corner "$c" --vdd "$v" --temp "$t" \
              --gate-cap-ff "$cg" >/dev/null
      ( $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true ) &
      n=$((n+1))
      [ $((n % JOBS)) -eq 0 ] && wait
    done
  done
done
wait

# --- Ozet ---------------------------------------------------------------
echo
printf "%-7s %-4s %-6s %14s %10s %14s\n" makro kose cs0 "E_cevre(pJ)" "c2/c3(%)" "P@fmax(mW)"
for m in $MACROS; do
  for ck in "tt:1.8:38.2" "ss:1.6:19.1" "ff:1.95:60.7"; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    f=$(echo "$ck" | cut -d: -f3)
    for cs in 0 1; do
      tag=$([ "$cs" = 0 ] && echo idle || echo active)
      lg="asic/macros/$m/char/periph_${tag}_${c}.log"
      q2=$(grep -m1 "q_c2 " "$lg" 2>/dev/null | awk '{print $3}')
      q3=$(grep -m1 "q_c3 " "$lg" 2>/dev/null | awk '{print $3}')
      if [ -z "$q3" ]; then
        printf "%-7s %-4s %-6s %14s\n" "$m" "$c" "$cs" "OLCULEMEDI"; continue
      fi
      python3 -c "
q2=abs(float('$q2')); q3=abs(float('$q3')); v=float('$v'); f=float('$f')
e=q3*v*1e12
settle=abs(q2-q3)/q3*100 if q3 else 0
pmw=e*1e-12*f*1e6*1e3
print(f'{\"$m\":<7} {\"$c\":<4} {\"$cs\":<6} {e:>14.4f} {settle:>10.1f} {pmw:>14.4f}')"
    done
  done
done
echo
echo "NOT: c2/c3 farki devrenin OTURDUGUNU gosterir; %5'in ustuyse --cycles"
echo "     buyutup tekrarlayin. Enerji frekanstan bagimsiz olmali --"
echo "     --tclk 400n ile dogrulanabilir."
