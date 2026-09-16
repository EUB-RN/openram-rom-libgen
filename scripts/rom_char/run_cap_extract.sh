#!/bin/sh
# Bir ROM makrosu icin GERCEK Magic parazitik KAPASITANS cikarimi.
# Direnc (extresist) BILEREK atlandi: tum makroyu (on binlerce hucre) tek
# seferde islemeye calisirken Magic 8.3.629 segfault veriyor (2026-08-28'de
# dogrulandi).
#
# Kullanim: run_cap_extract.sh <makro_adi>
# Ornek:    run_cap_extract.sh wrom0
# Cikti:    <makro_dizini>/<makro>_cap_only.spice
#
# Sonra: python3 scripts/rom_char/gen_col_tb_parasitic.py <makro>
#        (en kotu kolon netlistten turetilir)
#
# Ortam degiskenleri: ROM_MACROS_DIR, MAGIC_BIN, OPENRAM_TECH, PDK_ROOT

set -e
. "$(dirname "$0")/common.sh"

MACRO="$1"
if [ -z "$MACRO" ]; then
    echo "Kullanim: $0 <makro_adi>" >&2
    echo "Agactaki makrolar: $(macro_list)" >&2
    exit 1
fi

MACRO_DIR="$MACROS_DIR/$MACRO"
[ -d "$MACRO_DIR" ] || { echo "HATA: $MACRO_DIR yok" >&2; exit 1; }
cd "$MACRO_DIR"

# OpenRAM/PDK yollari kuruluma gore degisir -- ortamdan alinir.
if [ -z "$OPENRAM_TECH" ]; then
    echo "HATA: OPENRAM_TECH ayarli degil." >&2
    echo "  ornek: export OPENRAM_TECH=\$HOME/OpenRAM/technology" >&2
    exit 1
fi
export OPENRAM_TECH
export PDK_ROOT="${PDK_ROOT:-$HOME/OpenLane/pdks}"
MAGIC="${MAGIC_BIN:-magic}"
command -v "$MAGIC" >/dev/null 2>&1 || [ -x "$MAGIC" ] || {
    echo "HATA: magic bulunamadi ('$MAGIC'). MAGIC_BIN ile yolunu verin." >&2
    exit 1
}

echo "$(date): Baslangic - $MACRO icin sadece-C parazitik cikarim"

"$MAGIC" -dnull -noconsole << EOF
drc off
set VDD vdd
set GND gnd
set SUB gnd
gds warning default
gds flatglob *_?mos_m*
gds flatglob sky130_fd_bd_sram__sram_sp_cell_fom_serifs
gds flatglob sky130_fd_bd_sram__sram_sp_cell
gds flatglob sky130_fd_bd_sram__openram_sp_cell_opt1_replica_cell
gds flatglob sky130_fd_bd_sram__openram_sp_cell_opt1a_replica_cell
gds flatglob sky130_fd_bd_sram__sram_sp_cell_opt1_ce
gds flatglob sky130_fd_bd_sram__openram_sp_cell_opt1_replica_ce
gds flatglob sky130_fd_bd_sram__openram_sp_cell_opt1a_replica_ce
gds flatglob sky130_fd_bd_sram__sram_sp_wlstrap_ce
gds flatglob sky130_fd_bd_sram__sram_sp_wlstrap_p_ce
gds flatten true
gds ordering true
gds read ${MACRO}.gds
load ${MACRO}
cellname delete \(UNNAMED\)
port makeall
extract style ngspice(si)
extract unique all
extract all
puts "Finished extract (C dahil)"
ext2spice hierarchy on
ext2spice format ngspice
ext2spice cthresh 0
ext2spice rthresh infinite
ext2spice extresist off
ext2spice renumber off
ext2spice scale off
ext2spice blackbox on
ext2spice subcircuit top on
ext2spice global off
ext2spice -o ${MACRO}_cap_only.spice
puts "Finished ext2spice C-ONLY"
quit -noprompt
EOF
echo "$(date): Bitti rc=$?"
