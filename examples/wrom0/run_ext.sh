#!/bin/sh
export OPENRAM_TECH="/home/hpw/OpenRAM/technology:/home/hpw/OpenRAM/compiler/../technology"
echo "$(date): Starting GDS to MAG using Magic /nix/store/1zcyq032zc3mzhmgs2j3q2rmfrjj5v6b-magic-vlsi-8.3.629/bin/magic"

/nix/store/1zcyq032zc3mzhmgs2j3q2rmfrjj5v6b-magic-vlsi-8.3.629/bin/magic -dnull -noconsole << EOF
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
gds read wrom0.gds
puts "Finished reading gds wrom0.gds"
load wrom0
puts "Finished loading cell wrom0"
cellname delete \(UNNAMED\)
writeall force
port makeall
extract style ngspice(si)
extract unique all
extract all
select top cell
feedback why
puts "Finished extract"
ext2spice hierarchy on
ext2spice format ngspice
ext2spice cthresh infinite
ext2spice rthresh infinite
ext2spice renumber off
ext2spice scale off
ext2spice blackbox on
ext2spice subcircuit top on
ext2spice global off
ext2spice format ngspice
ext2spice wrom0
select top cell
feedback why
puts "Finished ext2spice"
quit -noprompt
EOF
magic_retcode=$?
echo "$(date): Finished ($magic_retcode) GDS to MAG using Magic /nix/store/1zcyq032zc3mzhmgs2j3q2rmfrjj5v6b-magic-vlsi-8.3.629/bin/magic"
exit $magic_retcode
