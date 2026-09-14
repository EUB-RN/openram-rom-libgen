#!/bin/sh
# Bir ROM makrosu icin GERCEK Magic parazitik KAPASITANS cikarimi.
# Direnc (extresist) BILEREK atlandi: tum makroyu (~34k hucre) tek seferde
# islemeye calisirken Magic 8.3.629'da segfault veriyor (2026-08-28'de
# dogrulandi). Bkz. docs/guides/rom_lib_uretimi.md.
#
# Kullanim: run_cap_extract.sh <macro_adi>
# Ornek:    run_cap_extract.sh wrom0
# Cikti:    asic/macros/<macro>/<macro>_cap_only.spice
#
# Sonra: python3 asic/scripts/rom_char/gen_col_tb_parasitic.py <macro> <en_kotu_kolon>

set -e
MACRO="$1"
if [ -z "$MACRO" ]; then
    echo "Kullanim: $0 <macro_adi>" >&2
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
MACRO_DIR="$REPO_ROOT/asic/macros/$MACRO"
cd "$MACRO_DIR"

export OPENRAM_TECH="/home/hpw/OpenRAM/technology:/home/hpw/OpenRAM/compiler/../technology"
export PDK_ROOT="${PDK_ROOT:-/home/hpw/OpenLane/pdks}"
MAGIC="${MAGIC_BIN:-/nix/store/1zcyq032zc3mzhmgs2j3q2rmfrjj5v6b-magic-vlsi-8.3.629/bin/magic}"

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
