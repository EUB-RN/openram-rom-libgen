#!/bin/sh
# CEVRE BIRIMI (periphery) cevrim enerjisi, uc kosede.
#
# NEDEN: .lib'deki clk0 internal_power bloklarinda `when : "!cs0"` eksikti.
# cs0 yalnizca on-sarj yolunu kapatir (precharge = ~NAND(cs0, clk_int));
# saat surucusu ve satir kod cozucu clk_int ile surulur, cs0'dan BAGIMSIZ.
# Yani makro secili degilken de her cevrimde saat agaci, adres tamponlari,
# kod cozucu ve tum wordline'lar anahtarlanir. Eksik blok OpenSTA'da hata
# veya uyari uretmez -- o durumu sessizce 0 sayar.
#
# YONTEM: gen_col_power_tb.py'nin "dilim x adet" yaklasiminin aynisi.
# On binlerce transistorluk hucre dizisi SIMULE EDILMEZ; silinir ve yuku
# (wordline basina <kolon sayisi> hucre kapisi + parazitik tel C) lump
# olarak geri konur. Hucre sayimi ve kapi kapasitansi netlistten gelir.
#   Adim 1: hucre basina esdeger kapi kapasitansi (tek cihaz, saniyeler)
#   Adim 2: cevre birimi cevrim enerjisi (cs0=0 ve cs0=1)
#
# cs0=0 -> `when : "!cs0"` degeri; dogrudan --energy-idle-pj ile .lib'e.
# cs0=1 -> aktif cevrimin CEVRE BIRIMI payi. .lib'e yazilacak `when : "cs0"`
#          degeri = <kolon sayisi> x E_kolon (run_col_energy.sh) + BU deger;
#          bu toplami regen_rom_libs.sh kendisi yapar.
#
# Kosum basina ~6 dk (neredeyse tamami netlist acma); JOBS kadari paralel.
#
# Kullanim: scripts/rom_char/run_periphery_power.sh [makro ...]
#           JOBS=4 scripts/rom_char/run_periphery_power.sh wrom0

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
GENP="$ROM_CHAR_DIR/gen_periphery_power_tb.py"
GENC="$ROM_CHAR_DIR/gen_cell_gate_tb.py"

MACROS=$(macro_list "$@")

# --- Adim 1: hucre esdeger kapi kapasitansi ------------------------------
echo "== Adim 1: hucre esdeger kapi kapasitansi (C = Q(VDD)/VDD) =="
for m in $MACROS; do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)
    sp="$G_CHAR/cellgate_${c}.sp"
    lg="$G_CHAR/cellgate_${c}.log"
    python3 "$GENC" "$m" "$sp" --corner "$c" --vdd "$v" --temp "$t" >/dev/null
    $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true
    cg=$(meas "$lg" c_one_ff)
    printf "  %-7s %-4s C_esd = %s fF/hucre\n" "$m" "$c" "${cg:-OLCULEMEDI}"
  done
done

# --- Adim 2: cevre birimi enerjisi --------------------------------------
echo
echo "== Adim 2: cevre birimi cevrim enerjisi =="
n=0
for m in $MACROS; do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)
    cg=$(meas "$G_CHAR/cellgate_${c}.log" c_one_ff)
    [ -z "$cg" ] && { echo "  $m $c: C_esd yok, atlandi"; continue; }
    for cs in 0 1; do
      tag=$([ "$cs" = 0 ] && echo idle || echo active)
      sp="$G_CHAR/periph_${tag}_${c}.sp"
      lg="$G_CHAR/periph_${tag}_${c}.log"
      python3 "$GENP" "$m" "$cs" "$sp" --corner "$c" --vdd "$v" --temp "$t" \
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
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1); v=$(echo "$ck" | cut -d: -f2)
    f=$(echo "$ck" | cut -d: -f4)
    for cs in 0 1; do
      tag=$([ "$cs" = 0 ] && echo idle || echo active)
      lg="$G_CHAR/periph_${tag}_${c}.log"
      q2=$(meas "$lg" q_c2)
      q3=$(meas "$lg" q_c3)
      if [ -z "$q3" ]; then
        printf "%-7s %-4s %-6s %14s\n" "$m" "$c" "$cs" "OLCULEMEDI"; continue
      fi
      echo "$q2 $q3" | awk -v m="$m" -v c="$c" -v cs="$cs" -v v="$v" -v f="$f" '
        { q2 = ($1 < 0 ? -$1 : $1); q3 = ($2 < 0 ? -$2 : $2);
          e = q3*v*1e12;
          settle = q3 ? (q2-q3 < 0 ? q3-q2 : q2-q3)/q3*100 : 0;
          pmw = e*1e-12*f*1e6*1e3;
          printf "%-7s %-4s %-6s %14.4f %10.1f %14.4f\n", m, c, cs, e, settle, pmw }'
    done
  done
done
echo
echo "NOT: c2/c3 farki devrenin OTURDUGUNU gosterir; %5'in ustuyse --cycles"
echo "     buyutup tekrarlayin. Enerji frekanstan bagimsiz olmali --"
echo "     --tclk 400n ile dogrulanabilir."
