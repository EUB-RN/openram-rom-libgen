# shellcheck shell=sh
# Tum run_*.sh betiklerinin ortak tabani -- `. "$(dirname "$0")/common.sh"`
#
# NE SAGLIYOR
#   ROOT, MACROS_DIR, CHAR_DIR yollari (ROM_MACROS_DIR ile degistirilebilir)
#   NG / JOBS                         (NGSPICE_BIN, JOBS ile degistirilebilir)
#   CORNERS "<etiket>:<vdd>:<sicaklik>:<fmax_MHz>"
#   macro_list  -- argumanlar yoksa makro agacindaki TUM makrolar
#   load_geom   -- G_COLS / G_WORST_COL / G_CHAIN / G_CHAR ... degiskenleri
#   meas        -- ngspice .measure satirindan deger ceker
#
# NEDEN: onceki halde makro listesi, en kotu kolon tablosu, kolon sayisi
# (256) ve depo yolu her betikte ELLE tekrar ediyordu; ROM yeniden
# uretildiginde hepsi birden guncellenmezse olcum sessizce yanlis oluyordu.
# Bkz. rom_paths.py.

ROM_CHAR_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$ROM_CHAR_DIR/../.." && pwd)"
MACROS_DIR="$(python3 "$ROM_CHAR_DIR/rom_paths.py" --macros-dir-only)"

NG="${NGSPICE_BIN:-ngspice}"
JOBS="${JOBS:-4}"

# etiket:vdd:sicaklik:fmax(MHz)  -- fmax yalnizca ozet tablodaki P=E*f icin
CORNERS="${ROM_CORNERS:-tt:1.8:25:38.2 ss:1.6:100:19.1 ff:1.95:-40:60.7}"
# .lib CELL_TABLE index_2 (cikis yuku, fF)
LOADS="${LOADS:-1.7225 6.89 27.56}"

# kose etiketi -> .lib kose adi
corner_lib_name() {
  case "$1" in
    tt) echo "TT_1p8V_25C" ;;
    ss) echo "SS_1p6V_100C" ;;
    ff) echo "FF_1p95V_n40C" ;;
    *)  echo "$1" ;;
  esac
}

# islenecek makrolar: arguman varsa onlar, yoksa agactaki hepsi
macro_list() {
  if [ "$#" -gt 0 ]; then
    echo "$@"
  else
    python3 "$ROM_CHAR_DIR/rom_paths.py" --list
  fi
}

# G_* geometri degiskenlerini yukler (netlistten turetilir, onbellekli)
load_geom() {
  _g=$(python3 "$ROM_CHAR_DIR/rom_paths.py" "$1" --sh) || return 1
  eval "$_g"
}

# ngspice .measure satirindan deger: meas <log> <olcum_adi>
meas() {
  [ -f "$1" ] || return 0
  grep -m1 "^$2 " "$1" | awk '{print $3}'
}

# ngspice var mi? (uretici betikler onsuz da calisir, kosum calismaz)
need_ngspice() {
  command -v "$NG" >/dev/null 2>&1 && return 0
  [ -x "$NG" ] && return 0
  echo "HATA: ngspice bulunamadi ('$NG'). NGSPICE_BIN ile yolunu verin." >&2
  exit 1
}
