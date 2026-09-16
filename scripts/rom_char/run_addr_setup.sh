#!/bin/sh
# addr0 -> kod cozucu SETUP olcumu, tum makrolar x uc kose.
#
# NE OLCULUYOR
# ------------
# .lib'deki `setup_rising`: addr0/cs0'in clk0 yukselmeden ONCE kararli
# kalmasi gereken sure. Bu makroda fiziksel karsiligi net:
#
#     rom_address_control_buf yapisi (netlistten):
#         addr0 -> inv_array_mod/Z -> nand2_dec(A=inv/Z, clk) -> A_out
#
# yani adres, tampondan DOGRUDAN SAATLI NAND'a giriyor; arada ayri bir
# on-kod cozucu kati yok. Adresin kararli olmasi gereken son nokta
# inv_array_mod'un Z'sidir ve olculen sey addr0 -> o net gecikmesidir.
#
# NEDEN ONEMLI: kod cozucu ON-SARJLI. On-sarj fazinda tum wordline'lar
# yukselir, evaluate'te SECILMEYENLER duser. Adres evaluate baslarken
# oturmamissa YANLIS wordline duser -- ve bitline gibi kod cozucu dugumu de
# bir sonraki on-sarja kadar geri DOLMAZ. Yani setup ihlali metastabilite
# degil, sessiz ve kalici yanlis okuma uretir.
#
# NEDEN AYRI DECK: adres gecisi ekstra anahtarlama enerjisi getirir;
# periph_active/idle deck'lerine eklenirse E_cevrim olcumunu sisirir.
# Bu betik ayni ureticiyi --addr-alt ile cagirip AYRI bir deck kosturur,
# guc akisina dokunmaz.
#
# EN KOTU ADRES: 0 -> tum adres bitleri 1 (LEF'teki addr0[] pin sayisindan
# turetilir). Butun tamponlar ayni anda anahtarlanir, besleme cokmesi dahil.
# Eskiden 2047 (11 bit) sabitti; adres genisligi degisince bu sessizce
# eksik uyarana donusuyordu.
#
# Kullanim: scripts/rom_char/run_addr_setup.sh [makro ...]
# Cikti:    <makro>/char/periph_setup_<kose>.log
#           ve ozet tablo (stdout); regen_rom_libs.sh bunu --setup'a gecirir.

set -e
. "$(dirname "$0")/common.sh"
need_ngspice
GENP="$ROM_CHAR_DIR/gen_periphery_power_tb.py"
JOBS="${JOBS:-6}"

MACROS=$(macro_list "$@")
n=0
for m in $MACROS; do
  load_geom "$m" || continue
  ADDR=0
  ADDR_ALT=$(awk -v b="$G_ADDR_BITS" 'BEGIN{printf "%d", 2^b - 1}')
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)

    # hucre esdeger kapi kapasitansi -- periph deck'iyle ayni girdi
    cgl="$G_CHAR/cellgate_${c}.log"
    if [ ! -f "$cgl" ]; then
      echo "  $m $c: cellgate log yok (once run_periphery_power.sh), atlandi"
      continue
    fi
    cg=$(meas "$cgl" c_one_ff)
    [ -z "$cg" ] && { echo "  $m $c: C_esd yok, atlandi"; continue; }

    sp="$G_CHAR/periph_setup_${c}.sp"
    lg="$G_CHAR/periph_setup_${c}.log"
    python3 "$GENP" "$m" 1 "$sp" --corner "$c" --vdd "$v" --temp "$t" \
            --gate-cap-ff "$cg" --addr "$ADDR" --addr-alt "$ADDR_ALT" >/dev/null
    ( $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true ) &
    n=$((n+1))
    [ $((n % JOBS)) -eq 0 ] && wait
  done
done
wait

echo ""
echo "makro   kose   olculen setup (ns)   [addr0 -> kod cozucu NAND girisi]"
for m in $MACROS; do
  load_geom "$m" || continue
  for ck in $CORNERS; do
    c=$(echo "$ck" | cut -d: -f1)
    lg="$G_CHAR/periph_setup_${c}.log"
    [ -f "$lg" ] || continue
    # tum tampon olcumlerinin EN KOTUSU
    w=$(grep -E "^t_addr2dec[0-9]+" "$lg" 2>/dev/null \
        | awk '{ if ($3 ~ /^[0-9.eE+-]+$/ && $3+0 > mx) mx = $3+0 } END { if (mx>0) printf "%.4f", mx*1e9 }')
    cnt=$(grep -cE "^t_addr2dec[0-9]+" "$lg" 2>/dev/null || echo 0)
    printf "%-7s %-4s   %-8s   (%s olcum)\n" "$m" "$c" "${w:-YOK}" "$cnt"
  done
done
