* wrom1 -- hucre ESDEGER KAPI KAPASITANSI (tt)
* C_esd = Q(VDD)/VDD  -- cevrim enerjisini koruyan kucultme.
* Kaynak/govde toprakta: wordline yukselirken hucrenin gordugu durum.
* Hucre ici parazitik C'ler BURADA YOK (periphery betigi ayrica ekler).

.lib /home/hpw/OpenLane/pdks/sky130A/libs.tech/ngspice/sky130.lib.spice tt
.temp 25
.param VDD=1.8
.param TR=10n

Vg0 g0 0 PWL(0 0 {TR} {VDD})
Vg1 g1 0 PWL(0 0 {TR} {VDD})

X0 0 g0 0 0 sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.108u ps=1.32 w=0.36 l=0.15
X1 0 g1 0 0 sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.216u ps=2.64 w=0.36 l=0.15

.options gmin=1e-12 abstol=1e-15 reltol=1e-4
.tran 'TR/2000' '1.2*TR' uic
.measure tran q_one  integ i(Vg0) from=0 to='TR'
.measure tran q_zero integ i(Vg1) from=0 to='TR'
.measure tran c_one_ff  param='abs(q_one)/VDD*1e15'
.measure tran c_zero_ff param='abs(q_zero)/VDD*1e15'
.end
