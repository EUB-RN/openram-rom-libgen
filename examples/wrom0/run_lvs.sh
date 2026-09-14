#!/bin/sh
export OPENRAM_TECH="/home/hpw/OpenRAM/technology:/home/hpw/OpenRAM/compiler/../technology"
echo "$(date): Starting LVS using Netgen /nix/store/h3crgmx1w7h86qjpr131igi7p576mp3x-netgen-1.5.318/bin/netgen"
/nix/store/h3crgmx1w7h86qjpr131igi7p576mp3x-netgen-1.5.318/bin/netgen -noconsole << EOF
lvs {wrom0.spice wrom0} {wrom0.lvs.sp wrom0} setup.tcl wrom0.lvs.report -full -json
quit
EOF
magic_retcode=$?
echo "$(date): Finished ($magic_retcode) LVS using Netgen /nix/store/h3crgmx1w7h86qjpr131igi7p576mp3x-netgen-1.5.318/bin/netgen"
exit $magic_retcode
