* Minimal transient used to verify ngspice stop/resume control flow.
.options klu
Vdrive in 0 PULSE(0 1.8 1n 100p 100p 900p 2n)
Rdrive in out 1k
Cload out 0 1p
.tran 20p 20n uic
.control
stop when time = 8n
run
meas tran q_before integ i(Vdrive) from=6n to=8n
meas tran q_before_prev integ i(Vdrive) from=4n to=6n
let qgap = 100 * abs(abs(q_before_prev) - abs(q_before)) / abs(q_before)
print qgap
* This deliberately impossible threshold exercises the resume branch.
if qgap < 0
  meas tran q_c2 integ i(Vdrive) from=4n to=6n
  meas tran q_c3 integ i(Vdrive) from=6n to=8n
  let e_periph_pj = abs(q_c3)*1.8*1e12
  print e_periph_pj
  echo PERIPH_SETTLED_CYCLES=8
else
  stop when time = 12n
  resume
  meas tran q_c2 integ i(Vdrive) from=8n to=10n
  meas tran q_c3 integ i(Vdrive) from=10n to=12n
  let e_periph_pj = abs(q_c3)*1.8*1e12
  print e_periph_pj
  echo PERIPH_SETTLED_CYCLES=12
end
quit
.endc
.end
