#!/bin/sh
# addr0 -> kod cozucu SETUP olcumu, 4 makro x 3 kose.
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
# Kullanim: run_addr_setup.sh
# Cikti:    asic/macros/<makro>/char/periph_setup_<kose>.log
#           ve ozet tablo (stdout) -- gen_rom_lib.py'ye --setup ile gecilir.

set -e
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$REPO_ROOT"

GENP=asic/scripts/rom_char/gen_periphery_power_tb.py
NG="${NGSPICE_BIN:-ngspice}"
JOBS="${JOBS:-6}"

# Adres 0 -> 0x7FF: 11 bitin HEPSI degisir, yani en kotu durum (butun
# tamponlar ayni anda anahtarlanir, kaynak/besleme cokmesi dahil).
ADDR=0
ADDR_ALT=2047

n=0
for row in "wrom0" "wrom1" "wrom2" "wrom3"; do
  m="$row"
  for ck in "tt:1.8:25" "ss:1.6:100" "ff:1.95:-40"; do
    c=$(echo "$ck" | cut -d: -f1)
    v=$(echo "$ck" | cut -d: -f2)
    t=$(echo "$ck" | cut -d: -f3)

    # hucre esdeger kapi kapasitansi -- periph deck'iyle ayni girdi
    cgl="asic/macros/$m/char/cellgate_${c}.log"
    if [ ! -f "$cgl" ]; then
      echo "  $m $c: cellgate log yok (once run_periphery_power.sh), atlandi"
      continue
    fi
    cg=$(grep -m1 "c_one_ff" "$cgl" | awk '{print $3}')
    [ -z "$cg" ] && { echo "  $m $c: C_esd yok, atlandi"; continue; }

    sp="asic/macros/$m/char/periph_setup_${c}.sp"
    lg="asic/macros/$m/char/periph_setup_${c}.log"
    python3 $GENP "$m" 1 "$sp" --corner "$c" --vdd "$v" --temp "$t" \
            --gate-cap-ff "$cg" --addr "$ADDR" --addr-alt "$ADDR_ALT" >/dev/null
    ( $NG -b -o "$lg" "$sp" >/dev/null 2>&1 || true ) &
    n=$((n+1))
    [ $((n % JOBS)) -eq 0 ] && wait
  done
done
wait

echo ""
echo "makro   kose   olculen setup (ns)   [addr0 -> kod cozucu NAND girisi]"
for m in wrom0 wrom1 wrom2 wrom3; do
  for c in tt ss ff; do
    lg="asic/macros/$m/char/periph_setup_${c}.log"
    [ -f "$lg" ] || continue
    # tum tampon olcumlerinin EN KOTUSU
    w=$(grep -E "^t_addr2dec[0-9]+" "$lg" 2>/dev/null \
        | awk '{ if ($3 ~ /^[0-9.eE+-]+$/ && $3+0 > mx) mx = $3+0 } END { if (mx>0) printf "%.4f", mx*1e9 }')
    cnt=$(grep -cE "^t_addr2dec[0-9]+" "$lg" 2>/dev/null || echo 0)
    printf "%-7s %-4s   %-8s   (%s olcum)\n" "$m" "$c" "${w:-YOK}" "$cnt"
  done
done
