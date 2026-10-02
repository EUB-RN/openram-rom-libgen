* Prove that one parsed circuit can run two independent transient modes.
.options klu
Vmode mode 0 DC 1
Rmode mode out 1k
Cstate out 0 1n IC=0
.tran 10n 10u uic

.control
stop when time=5u
run
resume
meas tran active_start FIND v(out) AT=10n
meas tran active_final FIND v(out) AT=10u

* reset reconstructs device state from the parsed circuit.  Alter must follow
* reset because reset also restores device values from the original netlist.
delete 1 2 3 4
destroy all
reset
alter Vmode=0
stop when time=5u
run
resume
meas tran idle_start FIND v(out) AT=10n
meas tran idle_final FIND v(out) AT=10u
echo PAIRED_RESET_ALTER_OK
quit
.endc
.end
