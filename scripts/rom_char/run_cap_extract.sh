#!/bin/sh
# REAL Magic parasitic CAPACITANCE extraction for one ROM macro.
# Resistance (extresist) is deliberately skipped: extracting resistance for the
# whole macro (tens of thousands of cells) in one go segfaults Magic 8.3.629
# (confirmed 2026-08-28).
#
# Usage: run_cap_extract.sh <macro_name>
# Example: run_cap_extract.sh wrom0
# Output: <macro_dir>/<macro>_cap_only.spice
#
# Next: python3 scripts/rom_char/gen_col_tb_parasitic.py <macro>
#       (the worst column is derived from the netlist)
#
# Environment: ROM_MACROS_DIR, MAGIC_BIN, OPENRAM_TECH, PDK_ROOT

set -e
. "$(dirname "$0")/common.sh"

MACRO="$1"
if [ -z "$MACRO" ]; then
    echo "usage: $0 <macro_name>" >&2
    echo "macros in the tree: $(macro_list)" >&2
    exit 1
fi

MACRO_DIR="$MACROS_DIR/$MACRO"
[ -d "$MACRO_DIR" ] || { echo "ERROR: no such directory: $MACRO_DIR" >&2; exit 1; }
cd "$MACRO_DIR"

# OpenRAM/PDK paths depend on the installation -- taken from the environment.
if [ -z "$OPENRAM_TECH" ]; then
    echo "ERROR: OPENRAM_TECH is not set." >&2
    echo "  example: export OPENRAM_TECH=\$HOME/OpenRAM/technology" >&2
    exit 1
fi
export OPENRAM_TECH
export PDK_ROOT="${PDK_ROOT:-$HOME/OpenLane/pdks}"
MAGIC="${MAGIC_BIN:-magic}"
command -v "$MAGIC" >/dev/null 2>&1 || [ -x "$MAGIC" ] || {
    echo "ERROR: magic not found ('$MAGIC'). Set MAGIC_BIN to its path." >&2
    exit 1
}

echo "$(date): start - capacitance-only extraction for $MACRO"

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
puts "Finished extract (with C)"
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
echo "$(date): done rc=$?"
