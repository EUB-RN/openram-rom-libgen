* wrom0 column 236 -- ACTIVE CYCLE ENERGY (per column)
* Charge integral drawn from VDD over one full cycle -> E = Q*VDD.
* The energy is FREQUENCY INDEPENDENT; verify by changing --tclk.
* Whole-macro energy ~ 256 x (this value) + periphery.
.lib /home/hpw/OpenLane/pdks/sky130A/libs.tech/ngspice/sky130.lib.spice ss
.temp 100
.param VDD=1.6

Vvdd vdd 0 DC {VDD}
Vggnd_uq0 gnd_uq0 0 DC 0
Vwl0 wl_0_0 0 DC {VDD}
Vwl1 wl_0_1 0 DC {VDD}
Vwl2 wl_0_2 0 DC {VDD}
Vwl3 wl_0_3 0 DC {VDD}
Vwl4 wl_0_4 0 DC {VDD}
Vwl5 wl_0_5 0 DC {VDD}
Vwl6 wl_0_6 0 DC {VDD}
Vwl7 wl_0_7 0 DC {VDD}
Vwl8 wl_0_8 0 DC {VDD}
Vwl9 wl_0_9 0 DC {VDD}
Vwl10 wl_0_10 0 DC {VDD}
Vwl11 wl_0_11 0 DC {VDD}
Vwl12 wl_0_12 0 DC {VDD}
Vwl13 wl_0_13 0 DC {VDD}
Vwl14 wl_0_14 0 DC {VDD}
Vwl15 wl_0_15 0 DC {VDD}
Vwl16 wl_0_16 0 DC {VDD}
Vwl17 wl_0_17 0 DC {VDD}
Vwl18 wl_0_18 0 DC {VDD}
Vwl19 wl_0_19 0 DC {VDD}
Vwl20 wl_0_20 0 DC {VDD}
Vwl21 wl_0_21 0 DC {VDD}
Vwl22 wl_0_22 0 DC {VDD}
Vwl23 wl_0_23 0 DC {VDD}
Vwl24 wl_0_24 0 DC {VDD}
Vwl25 wl_0_25 0 DC {VDD}
Vwl26 wl_0_26 0 DC {VDD}
Vwl27 wl_0_27 0 DC {VDD}
Vwl28 wl_0_28 0 DC {VDD}
Vwl29 wl_0_29 0 DC {VDD}
Vwl30 wl_0_30 0 DC {VDD}
Vwl31 wl_0_31 0 DC {VDD}
Vwl32 wl_0_32 0 DC {VDD}
Vwl33 wl_0_33 0 DC {VDD}
Vwl34 wl_0_34 0 DC {VDD}
Vwl35 wl_0_35 0 DC {VDD}
Vwl36 wl_0_36 0 DC {VDD}
Vwl37 wl_0_37 0 DC {VDD}
Vwl38 wl_0_38 0 DC {VDD}
Vwl39 wl_0_39 0 DC {VDD}
Vwl40 wl_0_40 0 DC {VDD}
Vwl41 wl_0_41 0 DC {VDD}
Vwl42 wl_0_42 0 DC {VDD}
Vwl43 wl_0_43 0 DC {VDD}
Vwl44 wl_0_44 0 DC {VDD}
Vwl45 wl_0_45 0 DC {VDD}
Vwl46 wl_0_46 0 DC {VDD}
Vwl47 wl_0_47 0 DC {VDD}
Vwl48 wl_0_48 0 DC {VDD}
Vwl49 wl_0_49 0 DC {VDD}
Vwl50 wl_0_50 0 DC {VDD}
Vwl51 wl_0_51 0 DC {VDD}
Vwl52 wl_0_52 0 DC {VDD}
Vwl53 wl_0_53 0 DC {VDD}
Vwl54 wl_0_54 0 DC {VDD}
Vwl55 wl_0_55 0 DC {VDD}
Vwl56 wl_0_56 0 DC {VDD}
Vwl57 wl_0_57 0 DC {VDD}
Vwl58 wl_0_58 0 DC {VDD}
Vwl59 wl_0_59 0 DC {VDD}
Vwl60 wl_0_60 0 DC {VDD}
Vwl61 wl_0_61 0 DC {VDD}
Vwl62 wl_0_62 0 DC {VDD}
Vwl63 wl_0_63 0 DC {VDD}
Vwl64 wl_0_64 0 DC {VDD}
Vwl65 wl_0_65 0 DC {VDD}
Vwl66 wl_0_66 0 DC {VDD}
Vwl67 wl_0_67 0 DC {VDD}
Vwl68 wl_0_68 0 DC {VDD}
Vwl69 wl_0_69 0 DC {VDD}
Vwl70 wl_0_70 0 DC {VDD}
Vwl71 wl_0_71 0 DC {VDD}
Vwl72 wl_0_72 0 DC {VDD}
Vwl73 wl_0_73 0 DC {VDD}
Vwl74 wl_0_74 0 DC {VDD}
Vwl75 wl_0_75 0 DC {VDD}
Vwl76 wl_0_76 0 DC {VDD}
Vwl77 wl_0_77 0 DC {VDD}
Vwl78 wl_0_78 0 DC {VDD}
Vwl79 wl_0_79 0 DC {VDD}
Vwl80 wl_0_80 0 DC {VDD}
Vwl81 wl_0_81 0 DC {VDD}
Vwl82 wl_0_82 0 DC {VDD}
Vwl83 wl_0_83 0 DC {VDD}
Vwl84 wl_0_84 0 DC {VDD}
Vwl85 wl_0_85 0 DC {VDD}
Vwl86 wl_0_86 0 DC {VDD}
Vwl87 wl_0_87 0 DC {VDD}
Vwl88 wl_0_88 0 DC {VDD}
Vwl89 wl_0_89 0 DC {VDD}
Vwl90 wl_0_90 0 DC {VDD}
Vwl91 wl_0_91 0 DC {VDD}
Vwl92 wl_0_92 0 DC {VDD}
Vwl93 wl_0_93 0 DC {VDD}
Vwl94 wl_0_94 0 DC {VDD}
Vwl95 wl_0_95 0 DC {VDD}
Vwl96 wl_0_96 0 DC {VDD}
Vwl97 wl_0_97 0 DC {VDD}
Vwl98 wl_0_98 0 DC {VDD}
Vwl99 wl_0_99 0 DC {VDD}
Vwl100 wl_0_100 0 DC {VDD}
Vwl101 wl_0_101 0 DC {VDD}
Vwl102 wl_0_102 0 DC {VDD}
Vwl103 wl_0_103 0 DC {VDD}
Vwl104 wl_0_104 0 DC {VDD}
Vwl105 wl_0_105 0 DC {VDD}
Vwl106 wl_0_106 0 DC {VDD}
Vwl107 wl_0_107 0 DC {VDD}
Vwl108 wl_0_108 0 DC {VDD}
Vwl109 wl_0_109 0 DC {VDD}
Vwl110 wl_0_110 0 DC {VDD}
Vwl111 wl_0_111 0 DC {VDD}
Vwl112 wl_0_112 0 DC {VDD}
Vwl113 wl_0_113 0 DC {VDD}
Vwl114 wl_0_114 0 DC {VDD}
Vwl115 wl_0_115 0 DC {VDD}
Vwl116 wl_0_116 0 DC {VDD}
Vwl117 wl_0_117 0 DC {VDD}
Vwl118 wl_0_118 0 DC {VDD}
Vwl119 wl_0_119 0 DC {VDD}
Vwl120 wl_0_120 0 DC {VDD}
Vwl121 wl_0_121 0 DC {VDD}
Vwl122 wl_0_122 0 DC {VDD}
Vwl123 wl_0_123 0 DC {VDD}
Vwl124 wl_0_124 0 DC {VDD}
Vwl125 wl_0_125 0 DC {VDD}
Vwl126 wl_0_126 0 DC {VDD}
Vwl127 wl_0_127 0 DC {VDD}
Vwl128 wl_0_128 0 DC {VDD}
Vwl129 wl_0_129 0 DC {VDD}
Vwl130 wl_0_130 0 DC {VDD}
Vwl131 wl_0_131 0 DC {VDD}
Vwl132 wl_0_132 0 DC {VDD}
.param TCLK=200n
Vprecharge precharge 0 PULSE(0 {VDD} {TCLK/2} 100p 100p {TCLK/2-100p} {TCLK})

* wrom0 -- isolated measurement of column 236 with REAL PARASITIC C
* 82 series NMOS + 52 dead cells (graph walk, name independent)
* wire resistance: 505.4 ohm per cell (82 x = 41.4 kohm)
* TCLK/2 is the PRECHARGE PHASE, and it is a real parameter of the answer --
* not a formality. The internal chain nodes never reach VDD (every cell is a
* pass transistor, so each one loses a Vth and the deeper nodes settle lower
* still), so the longer the precharge lasts the more charge the next read has
* to remove and the slower it is. Measured on wrom0 column 236 at TT:
*     precharge phase   25n     50n     100n    200n    1u
*     settled t_dis_50  6.9642  9.5409  11.5907 12.9614 14.8495 ns
* Monotonic and saturating, so the WORST CASE is the longest precharge: a ROM
* that has been idle with clk0 parked low, whose chain has filled
* asymptotically, and whose next read is the slowest read it can perform.
* That is what a .lib has to cover, so the phase is 1 us here.
Xprechg_pmos bl_0_236 precharge vdd gnd wrom0_precharge_cell
Xbl_inv gnd vdd vdd bl_0_236 bl_b wrom0_pinv_dec_3
Xwrom0_rom_base_one_cell_17189 bl_0_236_r wrom0_rom_base_one_cell_17189/D wl_0_0 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_16890 wrom0_rom_base_one_cell_17189/D_r1 wrom0_rom_base_one_cell_16890/D wl_0_2 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_16605 wrom0_rom_base_one_cell_16890/D_r2 wrom0_rom_base_one_cell_16605/D wl_0_4 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_16467 wrom0_rom_base_one_cell_16605/D_r3 wrom0_rom_base_one_cell_16467/D wl_0_5 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_16198 wrom0_rom_base_one_cell_16467/D_r4 wrom0_rom_base_one_cell_16198/D wl_0_7 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15938 wrom0_rom_base_one_cell_16198/D_r5 wrom0_rom_base_one_cell_15938/D wl_0_9 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15546 wrom0_rom_base_one_cell_15938/D_r6 wrom0_rom_base_one_cell_15546/D wl_0_12 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15420 wrom0_rom_base_one_cell_15546/D_r7 wrom0_rom_base_one_cell_15420/D wl_0_13 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15289 wrom0_rom_base_one_cell_15420/D_r8 wrom0_rom_base_one_cell_15289/D wl_0_14 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15136 wrom0_rom_base_one_cell_15289/D_r9 wrom0_rom_base_one_cell_15136/D wl_0_15 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15000 wrom0_rom_base_one_cell_15136/D_r10 wrom0_rom_base_one_cell_15000/D wl_0_16 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_14762 wrom0_rom_base_one_cell_15000/D_r11 wrom0_rom_base_one_cell_14762/D wl_0_18 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_14639 wrom0_rom_base_one_cell_14762/D_r12 wrom0_rom_base_one_cell_14639/D wl_0_19 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_14242 wrom0_rom_base_one_cell_14639/D_r13 wrom0_rom_base_one_cell_14242/D wl_0_22 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_14119 wrom0_rom_base_one_cell_14242/D_r14 wrom0_rom_base_one_cell_14119/D wl_0_23 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_13984 wrom0_rom_base_one_cell_14119/D_r15 wrom0_rom_base_one_cell_13984/D wl_0_24 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_13851 wrom0_rom_base_one_cell_13984/D_r16 wrom0_rom_base_one_cell_13851/D wl_0_25 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_13712 wrom0_rom_base_one_cell_13851/D_r17 wrom0_rom_base_one_cell_13712/D wl_0_26 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_13558 wrom0_rom_base_one_cell_13712/D_r18 wrom0_rom_base_one_cell_13558/D wl_0_27 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_13325 wrom0_rom_base_one_cell_13558/D_r19 wrom0_rom_base_one_cell_13325/D wl_0_29 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_13074 wrom0_rom_base_one_cell_13325/D_r20 wrom0_rom_base_one_cell_13074/D wl_0_31 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_12937 wrom0_rom_base_one_cell_13074/D_r21 wrom0_rom_base_one_cell_12937/D wl_0_32 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_12821 wrom0_rom_base_one_cell_12937/D_r22 wrom0_rom_base_one_cell_12821/D wl_0_33 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_12414 wrom0_rom_base_one_cell_12821/D_r23 wrom0_rom_base_one_cell_12414/D wl_0_36 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_12032 wrom0_rom_base_one_cell_12414/D_r24 wrom0_rom_base_one_cell_12032/D wl_0_39 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_11925 wrom0_rom_base_one_cell_12032/D_r25 wrom0_rom_base_one_cell_11925/D wl_0_40 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_11621 wrom0_rom_base_one_cell_11925/D_r26 wrom0_rom_base_one_cell_11621/D wl_0_42 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_11477 wrom0_rom_base_one_cell_11621/D_r27 wrom0_rom_base_one_cell_11477/D wl_0_43 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_11334 wrom0_rom_base_one_cell_11477/D_r28 wrom0_rom_base_one_cell_11334/D wl_0_44 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_11210 wrom0_rom_base_one_cell_11334/D_r29 wrom0_rom_base_one_cell_11210/D wl_0_45 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_10842 wrom0_rom_base_one_cell_11210/D_r30 wrom0_rom_base_one_cell_10842/D wl_0_48 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_10591 wrom0_rom_base_one_cell_10842/D_r31 wrom0_rom_base_one_cell_10591/D wl_0_50 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_10478 wrom0_rom_base_one_cell_10591/D_r32 wrom0_rom_base_one_cell_10478/D wl_0_51 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_10348 wrom0_rom_base_one_cell_10478/D_r33 wrom0_rom_base_one_cell_9969/S wl_0_52 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_9969 wrom0_rom_base_one_cell_9969/S_r34 wrom0_rom_base_one_cell_9969/D wl_0_55 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_9836 wrom0_rom_base_one_cell_9969/D_r35 wrom0_rom_base_one_cell_9836/D wl_0_56 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_9626 wrom0_rom_base_one_cell_9836/D_r36 wrom0_rom_base_one_cell_9626/D wl_0_58 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_9379 wrom0_rom_base_one_cell_9626/D_r37 wrom0_rom_base_one_cell_9379/D wl_0_60 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_8987 wrom0_rom_base_one_cell_9379/D_r38 wrom0_rom_base_one_cell_8987/D wl_0_63 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_8779 wrom0_rom_base_one_cell_8987/D_r39 wrom0_rom_base_one_cell_8779/D wl_0_65 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_8641 wrom0_rom_base_one_cell_8779/D_r40 wrom0_rom_base_one_cell_8641/D wl_0_66 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_8384 wrom0_rom_base_one_cell_8641/D_r41 wrom0_rom_base_one_cell_8384/D wl_0_68 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_8018 wrom0_rom_base_one_cell_8384/D_r42 wrom0_rom_base_one_cell_8018/D wl_0_71 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_7883 wrom0_rom_base_one_cell_8018/D_r43 wrom0_rom_base_one_cell_7883/D wl_0_72 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_7523 wrom0_rom_base_one_cell_7883/D_r44 wrom0_rom_base_one_cell_7523/D wl_0_75 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_7405 wrom0_rom_base_one_cell_7523/D_r45 wrom0_rom_base_one_cell_7405/D wl_0_76 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_7272 wrom0_rom_base_one_cell_7405/D_r46 wrom0_rom_base_one_cell_7272/D wl_0_77 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_7147 wrom0_rom_base_one_cell_7272/D_r47 wrom0_rom_base_one_cell_7147/D wl_0_78 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_7034 wrom0_rom_base_one_cell_7147/D_r48 wrom0_rom_base_one_cell_7034/D wl_0_79 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_6896 wrom0_rom_base_one_cell_7034/D_r49 wrom0_rom_base_one_cell_6896/D wl_0_80 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_6317 wrom0_rom_base_one_cell_6896/D_r50 wrom0_rom_base_one_cell_6317/D wl_0_85 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_6176 wrom0_rom_base_one_cell_6317/D_r51 wrom0_rom_base_one_cell_6176/D wl_0_86 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_6050 wrom0_rom_base_one_cell_6176/D_r52 wrom0_rom_base_one_cell_6050/D wl_0_87 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_5926 wrom0_rom_base_one_cell_6050/D_r53 wrom0_rom_base_one_cell_5926/D wl_0_88 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_5553 wrom0_rom_base_one_cell_5926/D_r54 wrom0_rom_base_one_cell_5553/D wl_0_91 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_5423 wrom0_rom_base_one_cell_5553/D_r55 wrom0_rom_base_one_cell_5423/D wl_0_92 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_5295 wrom0_rom_base_one_cell_5423/D_r56 wrom0_rom_base_one_cell_5295/D wl_0_93 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_4918 wrom0_rom_base_one_cell_5295/D_r57 wrom0_rom_base_one_cell_4918/D wl_0_96 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_4682 wrom0_rom_base_one_cell_4918/D_r58 wrom0_rom_base_one_cell_4682/D wl_0_98 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_4379 wrom0_rom_base_one_cell_4682/D_r59 wrom0_rom_base_one_cell_4379/D wl_0_100 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_4032 wrom0_rom_base_one_cell_4379/D_r60 wrom0_rom_base_one_cell_4032/D wl_0_103 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_3917 wrom0_rom_base_one_cell_4032/D_r61 wrom0_rom_base_one_cell_3917/D wl_0_104 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_3762 wrom0_rom_base_one_cell_3917/D_r62 wrom0_rom_base_one_cell_3762/D wl_0_105 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_3657 wrom0_rom_base_one_cell_3762/D_r63 wrom0_rom_base_one_cell_3657/D wl_0_106 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_3535 wrom0_rom_base_one_cell_3657/D_r64 wrom0_rom_base_one_cell_3535/D wl_0_107 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_3412 wrom0_rom_base_one_cell_3535/D_r65 wrom0_rom_base_one_cell_3412/D wl_0_108 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_3128 wrom0_rom_base_one_cell_3412/D_r66 wrom0_rom_base_one_cell_3128/D wl_0_110 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_2732 wrom0_rom_base_one_cell_3128/D_r67 wrom0_rom_base_one_cell_2732/D wl_0_113 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_2481 wrom0_rom_base_one_cell_2732/D_r68 wrom0_rom_base_one_cell_2481/D wl_0_115 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_2230 wrom0_rom_base_one_cell_2481/D_r69 wrom0_rom_base_one_cell_2230/D wl_0_117 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_1825 wrom0_rom_base_one_cell_2230/D_r70 wrom0_rom_base_one_cell_1825/D wl_0_120 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_1700 wrom0_rom_base_one_cell_1825/D_r71 wrom0_rom_base_one_cell_1700/D wl_0_121 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_1581 wrom0_rom_base_one_cell_1700/D_r72 wrom0_rom_base_one_cell_1581/D wl_0_122 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_1444 wrom0_rom_base_one_cell_1581/D_r73 wrom0_rom_base_one_cell_1444/D wl_0_123 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_1304 wrom0_rom_base_one_cell_1444/D_r74 wrom0_rom_base_zero_cell_894/S wl_0_124 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_1044 wrom0_rom_base_zero_cell_894/S_r75 wrom0_rom_base_one_cell_919/S wl_0_126 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_919 wrom0_rom_base_one_cell_919/S_r76 wrom0_rom_base_one_cell_919/D wl_0_127 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_794 wrom0_rom_base_one_cell_919/D_r77 wrom0_rom_base_one_cell_794/D wl_0_128 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_664 wrom0_rom_base_one_cell_794/D_r78 wrom0_rom_base_one_cell_664/D wl_0_129 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_512 wrom0_rom_base_one_cell_664/D_r79 wrom0_rom_base_one_cell_512/D wl_0_130 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_389 wrom0_rom_base_one_cell_512/D_r80 wrom0_rom_base_zero_cell_9/S wl_0_131 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_19 wrom0_rom_base_zero_cell_9/S_r81 gnd_uq0 precharge gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_zero_cell_16767 wrom0_rom_base_one_cell_17189/D wl_0_1 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_16543 wrom0_rom_base_one_cell_16890/D wl_0_3 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_16196 wrom0_rom_base_one_cell_16467/D wl_0_6 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_15949 wrom0_rom_base_one_cell_16198/D wl_0_8 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_15583 wrom0_rom_base_one_cell_15938/D wl_0_11 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_15695 wrom0_rom_base_one_cell_15938/D wl_0_10 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_14828 wrom0_rom_base_one_cell_15000/D wl_0_17 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_14315 wrom0_rom_base_one_cell_14639/D wl_0_21 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_14434 wrom0_rom_base_one_cell_14639/D wl_0_20 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_13461 wrom0_rom_base_one_cell_13558/D wl_0_28 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_13185 wrom0_rom_base_one_cell_13325/D wl_0_30 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_12555 wrom0_rom_base_one_cell_12821/D wl_0_35 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_12681 wrom0_rom_base_one_cell_12821/D wl_0_34 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_12314 wrom0_rom_base_one_cell_12414/D wl_0_37 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_12188 wrom0_rom_base_one_cell_12414/D wl_0_38 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_11790 wrom0_rom_base_one_cell_11925/D wl_0_41 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_11070 wrom0_rom_base_one_cell_11210/D wl_0_47 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_11194 wrom0_rom_base_one_cell_11210/D wl_0_46 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_10827 wrom0_rom_base_one_cell_10842/D wl_0_49 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_10155 wrom0_rom_base_one_cell_9969/S wl_0_54 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_10283 wrom0_rom_base_one_cell_9969/S wl_0_53 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_9744 wrom0_rom_base_one_cell_9836/D wl_0_57 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_9463 wrom0_rom_base_one_cell_9626/D wl_0_59 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_9203 wrom0_rom_base_one_cell_9379/D wl_0_61 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_9066 wrom0_rom_base_one_cell_9379/D wl_0_62 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_8803 wrom0_rom_base_one_cell_8987/D wl_0_64 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_8401 wrom0_rom_base_one_cell_8641/D wl_0_67 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_8011 wrom0_rom_base_one_cell_8384/D wl_0_70 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_8150 wrom0_rom_base_one_cell_8384/D wl_0_69 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_7473 wrom0_rom_base_one_cell_7883/D wl_0_74 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_7600 wrom0_rom_base_one_cell_7883/D wl_0_73 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_6119 wrom0_rom_base_one_cell_6896/D wl_0_84 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_6404 wrom0_rom_base_one_cell_6896/D wl_0_82 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_6259 wrom0_rom_base_one_cell_6896/D wl_0_83 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_6542 wrom0_rom_base_one_cell_6896/D wl_0_81 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_5356 wrom0_rom_base_one_cell_5926/D wl_0_90 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_5496 wrom0_rom_base_one_cell_5926/D wl_0_89 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_4709 wrom0_rom_base_one_cell_5295/D wl_0_95 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_4832 wrom0_rom_base_one_cell_5295/D wl_0_94 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_4441 wrom0_rom_base_one_cell_4918/D wl_0_97 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_4193 wrom0_rom_base_one_cell_4682/D wl_0_99 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_3810 wrom0_rom_base_one_cell_4379/D wl_0_102 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_3954 wrom0_rom_base_one_cell_4379/D wl_0_101 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_2891 wrom0_rom_base_one_cell_3412/D wl_0_109 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_2659 wrom0_rom_base_one_cell_3128/D wl_0_111 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_2517 wrom0_rom_base_one_cell_3128/D wl_0_112 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_2267 wrom0_rom_base_one_cell_2732/D wl_0_114 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_2014 wrom0_rom_base_one_cell_2481/D wl_0_116 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_1758 wrom0_rom_base_one_cell_2230/D wl_0_118 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_1632 wrom0_rom_base_one_cell_2230/D wl_0_119 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_894 wrom0_rom_base_zero_cell_894/S wl_0_125 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_9 wrom0_rom_base_zero_cell_9/S wl_0_132 gnd wrom0_rom_base_zero_cell
Rw0 bl_0_236 bl_0_236_r 505.3714
Rw1 wrom0_rom_base_one_cell_17189/D wrom0_rom_base_one_cell_17189/D_r1 505.3714
Rw2 wrom0_rom_base_one_cell_16890/D wrom0_rom_base_one_cell_16890/D_r2 505.3714
Rw3 wrom0_rom_base_one_cell_16605/D wrom0_rom_base_one_cell_16605/D_r3 505.3714
Rw4 wrom0_rom_base_one_cell_16467/D wrom0_rom_base_one_cell_16467/D_r4 505.3714
Rw5 wrom0_rom_base_one_cell_16198/D wrom0_rom_base_one_cell_16198/D_r5 505.3714
Rw6 wrom0_rom_base_one_cell_15938/D wrom0_rom_base_one_cell_15938/D_r6 505.3714
Rw7 wrom0_rom_base_one_cell_15546/D wrom0_rom_base_one_cell_15546/D_r7 505.3714
Rw8 wrom0_rom_base_one_cell_15420/D wrom0_rom_base_one_cell_15420/D_r8 505.3714
Rw9 wrom0_rom_base_one_cell_15289/D wrom0_rom_base_one_cell_15289/D_r9 505.3714
Rw10 wrom0_rom_base_one_cell_15136/D wrom0_rom_base_one_cell_15136/D_r10 505.3714
Rw11 wrom0_rom_base_one_cell_15000/D wrom0_rom_base_one_cell_15000/D_r11 505.3714
Rw12 wrom0_rom_base_one_cell_14762/D wrom0_rom_base_one_cell_14762/D_r12 505.3714
Rw13 wrom0_rom_base_one_cell_14639/D wrom0_rom_base_one_cell_14639/D_r13 505.3714
Rw14 wrom0_rom_base_one_cell_14242/D wrom0_rom_base_one_cell_14242/D_r14 505.3714
Rw15 wrom0_rom_base_one_cell_14119/D wrom0_rom_base_one_cell_14119/D_r15 505.3714
Rw16 wrom0_rom_base_one_cell_13984/D wrom0_rom_base_one_cell_13984/D_r16 505.3714
Rw17 wrom0_rom_base_one_cell_13851/D wrom0_rom_base_one_cell_13851/D_r17 505.3714
Rw18 wrom0_rom_base_one_cell_13712/D wrom0_rom_base_one_cell_13712/D_r18 505.3714
Rw19 wrom0_rom_base_one_cell_13558/D wrom0_rom_base_one_cell_13558/D_r19 505.3714
Rw20 wrom0_rom_base_one_cell_13325/D wrom0_rom_base_one_cell_13325/D_r20 505.3714
Rw21 wrom0_rom_base_one_cell_13074/D wrom0_rom_base_one_cell_13074/D_r21 505.3714
Rw22 wrom0_rom_base_one_cell_12937/D wrom0_rom_base_one_cell_12937/D_r22 505.3714
Rw23 wrom0_rom_base_one_cell_12821/D wrom0_rom_base_one_cell_12821/D_r23 505.3714
Rw24 wrom0_rom_base_one_cell_12414/D wrom0_rom_base_one_cell_12414/D_r24 505.3714
Rw25 wrom0_rom_base_one_cell_12032/D wrom0_rom_base_one_cell_12032/D_r25 505.3714
Rw26 wrom0_rom_base_one_cell_11925/D wrom0_rom_base_one_cell_11925/D_r26 505.3714
Rw27 wrom0_rom_base_one_cell_11621/D wrom0_rom_base_one_cell_11621/D_r27 505.3714
Rw28 wrom0_rom_base_one_cell_11477/D wrom0_rom_base_one_cell_11477/D_r28 505.3714
Rw29 wrom0_rom_base_one_cell_11334/D wrom0_rom_base_one_cell_11334/D_r29 505.3714
Rw30 wrom0_rom_base_one_cell_11210/D wrom0_rom_base_one_cell_11210/D_r30 505.3714
Rw31 wrom0_rom_base_one_cell_10842/D wrom0_rom_base_one_cell_10842/D_r31 505.3714
Rw32 wrom0_rom_base_one_cell_10591/D wrom0_rom_base_one_cell_10591/D_r32 505.3714
Rw33 wrom0_rom_base_one_cell_10478/D wrom0_rom_base_one_cell_10478/D_r33 505.3714
Rw34 wrom0_rom_base_one_cell_9969/S wrom0_rom_base_one_cell_9969/S_r34 505.3714
Rw35 wrom0_rom_base_one_cell_9969/D wrom0_rom_base_one_cell_9969/D_r35 505.3714
Rw36 wrom0_rom_base_one_cell_9836/D wrom0_rom_base_one_cell_9836/D_r36 505.3714
Rw37 wrom0_rom_base_one_cell_9626/D wrom0_rom_base_one_cell_9626/D_r37 505.3714
Rw38 wrom0_rom_base_one_cell_9379/D wrom0_rom_base_one_cell_9379/D_r38 505.3714
Rw39 wrom0_rom_base_one_cell_8987/D wrom0_rom_base_one_cell_8987/D_r39 505.3714
Rw40 wrom0_rom_base_one_cell_8779/D wrom0_rom_base_one_cell_8779/D_r40 505.3714
Rw41 wrom0_rom_base_one_cell_8641/D wrom0_rom_base_one_cell_8641/D_r41 505.3714
Rw42 wrom0_rom_base_one_cell_8384/D wrom0_rom_base_one_cell_8384/D_r42 505.3714
Rw43 wrom0_rom_base_one_cell_8018/D wrom0_rom_base_one_cell_8018/D_r43 505.3714
Rw44 wrom0_rom_base_one_cell_7883/D wrom0_rom_base_one_cell_7883/D_r44 505.3714
Rw45 wrom0_rom_base_one_cell_7523/D wrom0_rom_base_one_cell_7523/D_r45 505.3714
Rw46 wrom0_rom_base_one_cell_7405/D wrom0_rom_base_one_cell_7405/D_r46 505.3714
Rw47 wrom0_rom_base_one_cell_7272/D wrom0_rom_base_one_cell_7272/D_r47 505.3714
Rw48 wrom0_rom_base_one_cell_7147/D wrom0_rom_base_one_cell_7147/D_r48 505.3714
Rw49 wrom0_rom_base_one_cell_7034/D wrom0_rom_base_one_cell_7034/D_r49 505.3714
Rw50 wrom0_rom_base_one_cell_6896/D wrom0_rom_base_one_cell_6896/D_r50 505.3714
Rw51 wrom0_rom_base_one_cell_6317/D wrom0_rom_base_one_cell_6317/D_r51 505.3714
Rw52 wrom0_rom_base_one_cell_6176/D wrom0_rom_base_one_cell_6176/D_r52 505.3714
Rw53 wrom0_rom_base_one_cell_6050/D wrom0_rom_base_one_cell_6050/D_r53 505.3714
Rw54 wrom0_rom_base_one_cell_5926/D wrom0_rom_base_one_cell_5926/D_r54 505.3714
Rw55 wrom0_rom_base_one_cell_5553/D wrom0_rom_base_one_cell_5553/D_r55 505.3714
Rw56 wrom0_rom_base_one_cell_5423/D wrom0_rom_base_one_cell_5423/D_r56 505.3714
Rw57 wrom0_rom_base_one_cell_5295/D wrom0_rom_base_one_cell_5295/D_r57 505.3714
Rw58 wrom0_rom_base_one_cell_4918/D wrom0_rom_base_one_cell_4918/D_r58 505.3714
Rw59 wrom0_rom_base_one_cell_4682/D wrom0_rom_base_one_cell_4682/D_r59 505.3714
Rw60 wrom0_rom_base_one_cell_4379/D wrom0_rom_base_one_cell_4379/D_r60 505.3714
Rw61 wrom0_rom_base_one_cell_4032/D wrom0_rom_base_one_cell_4032/D_r61 505.3714
Rw62 wrom0_rom_base_one_cell_3917/D wrom0_rom_base_one_cell_3917/D_r62 505.3714
Rw63 wrom0_rom_base_one_cell_3762/D wrom0_rom_base_one_cell_3762/D_r63 505.3714
Rw64 wrom0_rom_base_one_cell_3657/D wrom0_rom_base_one_cell_3657/D_r64 505.3714
Rw65 wrom0_rom_base_one_cell_3535/D wrom0_rom_base_one_cell_3535/D_r65 505.3714
Rw66 wrom0_rom_base_one_cell_3412/D wrom0_rom_base_one_cell_3412/D_r66 505.3714
Rw67 wrom0_rom_base_one_cell_3128/D wrom0_rom_base_one_cell_3128/D_r67 505.3714
Rw68 wrom0_rom_base_one_cell_2732/D wrom0_rom_base_one_cell_2732/D_r68 505.3714
Rw69 wrom0_rom_base_one_cell_2481/D wrom0_rom_base_one_cell_2481/D_r69 505.3714
Rw70 wrom0_rom_base_one_cell_2230/D wrom0_rom_base_one_cell_2230/D_r70 505.3714
Rw71 wrom0_rom_base_one_cell_1825/D wrom0_rom_base_one_cell_1825/D_r71 505.3714
Rw72 wrom0_rom_base_one_cell_1700/D wrom0_rom_base_one_cell_1700/D_r72 505.3714
Rw73 wrom0_rom_base_one_cell_1581/D wrom0_rom_base_one_cell_1581/D_r73 505.3714
Rw74 wrom0_rom_base_one_cell_1444/D wrom0_rom_base_one_cell_1444/D_r74 505.3714
Rw75 wrom0_rom_base_zero_cell_894/S wrom0_rom_base_zero_cell_894/S_r75 505.3714
Rw76 wrom0_rom_base_one_cell_919/S wrom0_rom_base_one_cell_919/S_r76 505.3714
Rw77 wrom0_rom_base_one_cell_919/D wrom0_rom_base_one_cell_919/D_r77 505.3714
Rw78 wrom0_rom_base_one_cell_794/D wrom0_rom_base_one_cell_794/D_r78 505.3714
Rw79 wrom0_rom_base_one_cell_664/D wrom0_rom_base_one_cell_664/D_r79 505.3714
Rw80 wrom0_rom_base_one_cell_512/D wrom0_rom_base_one_cell_512/D_r80 505.3714
Rw81 wrom0_rom_base_zero_cell_9/S wrom0_rom_base_zero_cell_9/S_r81 505.3714
.subckt wrom0_rom_base_one_cell S D G gnd
X0 D G S gnd sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.108u ps=1.32 w=0.36 l=0.15
C0 G D 0.00394f
C1 S D 0.04533f
C2 G S 0.00394f
C3 S gnd 0.05671f
C4 D gnd 0.09245f
C5 G gnd 0.10004f
.ends
.subckt wrom0_rom_base_zero_cell S G gnd
X0 S G S gnd sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.216u ps=2.64 w=0.36 l=0.15
C0 G S 0.01098f
C1 S gnd 0.169f
C2 G gnd 0.10004f
.ends
.subckt wrom0_precharge_cell D G vdd gnd
X0 D G vdd vdd sky130_fd_pr__pfet_01v8 ad=0.126u pd=1.44 as=0.126u ps=1.44 w=0.42 l=0.15
C0 vdd G 0.05763f
C1 D G 0.00394f
C2 vdd D 0.03592f
C3 D gnd 0.05546f
C4 G gnd 0.03904f
C5 vdd gnd 0.33982f
.ends
.subckt wrom0_pinv_dec_3 gnd vdd w_692_n79# A Z
X0 vdd A Z w_692_n79# sky130_fd_pr__pfet_01v8 ad=1.5u pd=10.6 as=1.5u ps=10.6 w=5 l=0.15
X1 gnd A Z gnd sky130_fd_pr__nfet_01v8 ad=0.504u pd=3.96 as=0.504u ps=3.96 w=1.68 l=0.15
C0 Z A 0.04991f
C1 w_692_n79# vdd 0.02783f
C2 w_692_n79# A 0.10891f
C3 w_692_n79# Z 0.05333f
C4 vdd A 0.01892f
C5 Z vdd 0.06954f
C6 vdd gnd 0.06645f
C7 Z gnd 0.35042f
C8 A gnd 0.23452f
C9 w_692_n79# gnd 1.35078f
.ends
* THE FIRST CYCLE IS NOT A MEASUREMENT (found 2026-09-20 from a waveform).
* `.ic` sets the bitline only; with `uic` the 82 internal chain nodes start at
* 0 V and jump within picoseconds to a capacitive-divider level set by each
* cell's parasitic C to vdd and to gnd. That level is HIGHER than the state
* conduction produces, and the nodes cannot come back down: the foot
* transistor is off during precharge, so they can only be charged, never
* discharged. A longer first precharge therefore does not wash it out --
* wrom0 cycle 1 gives 16.5035 ns whether the first precharge phase is 25 ns,
* 100 ns or 1 us, against 14.8495 ns settled at the same 1 us phase.
* Probed at the end of the precharge phase (wrom0, TT):
*     node          cycle 1   settled
*     bitline       1.8000 V  1.7990 V
*     chain node 1  1.2623 V  1.0696 V
*     chain node 41 1.1171 V  0.8426 V
*     chain node 81 1.1082 V  0.8201 V
* Cycle 1 is nearly flat -- a capacitive divider; the settled state is a
* gradient built by conduction. So every measurement below sits on a LATE
* cycle, the same rule the energy decks already follow (q_c2 vs q_c3).
*
* t_dis_50_prev is the previous cycle and exists to PROVE the settling: if it
* differs from t_dis_50, the deck has not settled and the number must not be
* used. On these macros the two agree to four decimals.
* t_pre_50: the bitline crosses the bitline-inverter trip point on the way
* back up -- this is the moment dout0 STOPS being valid after clk0 falls.
* It feeds the falling_edge arc of the .lib (gen_rom_lib.py --t-invalid).
* t_pre_90/t_pre_99 are the recharge-complete times and are much later, so
* they must NOT be used for that arc.
* These sit on the falling edge that ENDS cycle 2, i.e. after two discharges.
* 200 ps: the step is not a sensitivity here -- 100 ps against 200 ps moves
* t_dis_50 by 0.007% -- and at a 1 us phase it keeps the run under a few
* minutes.

.tran '200n/400' '4*TCLK' uic
* Cycles 2 AND 3 are measured separately: equal values prove the circuit has
* SETTLED (with uic every node starts at 0 and the chain fills slowly).
* Cycle 3 is the more settled one, so THAT is what goes into the .lib.
* FREQUENCY INDEPENDENCE VERIFIED (2026-09-05, wrom0 column 155, TT):
*   TCLK=200n -> q_c3 = 2.342e-13 C
*   TCLK=400n -> q_c3 = 2.419e-13 C   (period 2x, charge 3.3% different)
.measure tran q_c2 integ i(Vvdd) from='TCLK' to='2*TCLK'
.measure tran q_c3 integ i(Vvdd) from='2*TCLK' to='3*TCLK'
.measure tran e_col_pj param='abs(q_c3)*VDD*1e12'
.end
