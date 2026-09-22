* wrom1 -- isolated measurement of column 214 with REAL PARASITIC C
* 88 series NMOS + 46 dead cells (graph walk, name independent)
* wire resistance: 505.4 ohm per cell (88 x = 44.5 kohm)

.lib /home/hpw/OpenLane/pdks/sky130A/libs.tech/ngspice/sky130.lib.spice tt

.param VDD=1.8
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
.param TCLK=2u

Vvdd vdd 0 DC {VDD}
Vgndgnd_uq0 gnd_uq0 0 DC 0
Vprecharge precharge 0 PULSE(0 {VDD} {TCLK/2} 100p 100p {TCLK/2-100p} {TCLK})

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

Xprechg_pmos bl_0_214 precharge vdd gnd wrom1_precharge_cell
Xbl_inv gnd vdd vdd bl_0_214 bl_b wrom1_pinv_dec_3

Xwrom1_rom_base_one_cell_16988 bl_0_214_r wrom1_rom_base_one_cell_16988/D wl_0_3 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_16848 wrom1_rom_base_one_cell_16988/D_r1 wrom1_rom_base_one_cell_16848/D wl_0_4 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_16597 wrom1_rom_base_one_cell_16848/D_r2 wrom1_rom_base_one_cell_16597/D wl_0_6 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_16351 wrom1_rom_base_one_cell_16597/D_r3 wrom1_rom_base_one_cell_16351/D wl_0_8 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_16089 wrom1_rom_base_one_cell_16351/D_r4 wrom1_rom_base_one_cell_16089/D wl_0_10 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15964 wrom1_rom_base_one_cell_16089/D_r5 wrom1_rom_base_one_cell_15964/D wl_0_11 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15692 wrom1_rom_base_one_cell_15964/D_r6 wrom1_rom_base_one_cell_15692/D wl_0_13 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15550 wrom1_rom_base_one_cell_15692/D_r7 wrom1_rom_base_one_cell_15550/D wl_0_14 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15279 wrom1_rom_base_one_cell_15550/D_r8 wrom1_rom_base_one_cell_15279/D wl_0_16 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15147 wrom1_rom_base_one_cell_15279/D_r9 wrom1_rom_base_one_cell_15147/D wl_0_17 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15011 wrom1_rom_base_one_cell_15147/D_r10 wrom1_rom_base_one_cell_15011/D wl_0_18 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_14872 wrom1_rom_base_one_cell_15011/D_r11 wrom1_rom_base_one_cell_14872/D wl_0_19 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_14600 wrom1_rom_base_one_cell_14872/D_r12 wrom1_rom_base_one_cell_14600/D wl_0_21 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_14363 wrom1_rom_base_one_cell_14600/D_r13 wrom1_rom_base_one_cell_14363/D wl_0_23 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_14223 wrom1_rom_base_one_cell_14363/D_r14 wrom1_rom_base_one_cell_14223/D wl_0_24 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13963 wrom1_rom_base_one_cell_14223/D_r15 wrom1_rom_base_one_cell_13963/D wl_0_26 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13730 wrom1_rom_base_one_cell_13963/D_r16 wrom1_rom_base_one_cell_13730/D wl_0_28 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13591 wrom1_rom_base_one_cell_13730/D_r17 wrom1_rom_base_one_cell_13591/D wl_0_29 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13468 wrom1_rom_base_one_cell_13591/D_r18 wrom1_rom_base_one_cell_13468/D wl_0_30 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13345 wrom1_rom_base_one_cell_13468/D_r19 wrom1_rom_base_one_cell_13345/D wl_0_31 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13213 wrom1_rom_base_one_cell_13345/D_r20 wrom1_rom_base_one_cell_13213/D wl_0_32 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13072 wrom1_rom_base_one_cell_13213/D_r21 wrom1_rom_base_one_cell_13072/D wl_0_33 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12936 wrom1_rom_base_one_cell_13072/D_r22 wrom1_rom_base_one_cell_12936/D wl_0_34 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12829 wrom1_rom_base_one_cell_12936/D_r23 wrom1_rom_base_one_cell_12829/D wl_0_35 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12718 wrom1_rom_base_one_cell_12829/D_r24 wrom1_rom_base_one_cell_12718/D wl_0_36 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12478 wrom1_rom_base_one_cell_12718/D_r25 wrom1_rom_base_one_cell_12478/D wl_0_38 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12347 wrom1_rom_base_one_cell_12478/D_r26 wrom1_rom_base_one_cell_12347/D wl_0_39 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12245 wrom1_rom_base_one_cell_12347/D_r27 wrom1_rom_base_one_cell_12245/D wl_0_40 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12105 wrom1_rom_base_one_cell_12245/D_r28 wrom1_rom_base_one_cell_12105/D wl_0_41 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_11980 wrom1_rom_base_one_cell_12105/D_r29 wrom1_rom_base_one_cell_11980/D wl_0_42 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_11861 wrom1_rom_base_one_cell_11980/D_r30 wrom1_rom_base_one_cell_11861/D wl_0_43 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_11736 wrom1_rom_base_one_cell_11861/D_r31 wrom1_rom_base_one_cell_11736/D wl_0_44 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_11612 wrom1_rom_base_one_cell_11736/D_r32 wrom1_rom_base_one_cell_11612/D wl_0_45 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_11342 wrom1_rom_base_one_cell_11612/D_r33 wrom1_rom_base_one_cell_11342/D wl_0_47 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_11078 wrom1_rom_base_one_cell_11342/D_r34 wrom1_rom_base_one_cell_11078/D wl_0_49 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_10954 wrom1_rom_base_one_cell_11078/D_r35 wrom1_rom_base_one_cell_10954/D wl_0_50 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_10814 wrom1_rom_base_one_cell_10954/D_r36 wrom1_rom_base_zero_cell_9962/S wl_0_51 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_10439 wrom1_rom_base_zero_cell_9962/S_r37 wrom1_rom_base_one_cell_10439/D wl_0_54 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_10302 wrom1_rom_base_one_cell_10439/D_r38 wrom1_rom_base_one_cell_10302/D wl_0_55 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_10173 wrom1_rom_base_one_cell_10302/D_r39 wrom1_rom_base_one_cell_9932/S wl_0_56 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_9932 wrom1_rom_base_one_cell_9932/S_r40 wrom1_rom_base_one_cell_9932/D wl_0_58 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_9833 wrom1_rom_base_one_cell_9932/D_r41 wrom1_rom_base_one_cell_9833/D wl_0_59 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_9712 wrom1_rom_base_one_cell_9833/D_r42 wrom1_rom_base_one_cell_9712/D wl_0_60 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_9570 wrom1_rom_base_one_cell_9712/D_r43 wrom1_rom_base_one_cell_9570/D wl_0_61 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_9325 wrom1_rom_base_one_cell_9570/D_r44 wrom1_rom_base_one_cell_9325/D wl_0_63 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_9071 wrom1_rom_base_one_cell_9325/D_r45 wrom1_rom_base_one_cell_9071/D wl_0_65 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8947 wrom1_rom_base_one_cell_9071/D_r46 wrom1_rom_base_one_cell_8947/D wl_0_66 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8819 wrom1_rom_base_one_cell_8947/D_r47 wrom1_rom_base_one_cell_8819/D wl_0_67 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8555 wrom1_rom_base_one_cell_8819/D_r48 wrom1_rom_base_one_cell_8555/D wl_0_69 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8436 wrom1_rom_base_one_cell_8555/D_r49 wrom1_rom_base_one_cell_8436/D wl_0_70 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8300 wrom1_rom_base_one_cell_8436/D_r50 wrom1_rom_base_one_cell_8300/D wl_0_71 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8149 wrom1_rom_base_one_cell_8300/D_r51 wrom1_rom_base_one_cell_8149/D wl_0_72 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8017 wrom1_rom_base_one_cell_8149/D_r52 wrom1_rom_base_one_cell_8017/D wl_0_73 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_7743 wrom1_rom_base_one_cell_8017/D_r53 wrom1_rom_base_one_cell_7743/D wl_0_75 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_7091 wrom1_rom_base_one_cell_7743/D_r54 wrom1_rom_base_one_cell_7091/D wl_0_80 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_6827 wrom1_rom_base_one_cell_7091/D_r55 wrom1_rom_base_one_cell_6827/D wl_0_82 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_6283 wrom1_rom_base_one_cell_6827/D_r56 wrom1_rom_base_one_cell_6283/D wl_0_86 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_6146 wrom1_rom_base_one_cell_6283/D_r57 wrom1_rom_base_one_cell_6146/D wl_0_87 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_6034 wrom1_rom_base_one_cell_6146/D_r58 wrom1_rom_base_one_cell_6034/D wl_0_88 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_5901 wrom1_rom_base_one_cell_6034/D_r59 wrom1_rom_base_one_cell_5901/D wl_0_89 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_5769 wrom1_rom_base_one_cell_5901/D_r60 wrom1_rom_base_one_cell_5769/D wl_0_90 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_5515 wrom1_rom_base_one_cell_5769/D_r61 wrom1_rom_base_one_cell_5515/D wl_0_92 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_5377 wrom1_rom_base_one_cell_5515/D_r62 wrom1_rom_base_one_cell_5377/D wl_0_93 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_5115 wrom1_rom_base_one_cell_5377/D_r63 wrom1_rom_base_one_cell_5115/D wl_0_95 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_4966 wrom1_rom_base_one_cell_5115/D_r64 wrom1_rom_base_one_cell_4966/D wl_0_96 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_4582 wrom1_rom_base_one_cell_4966/D_r65 wrom1_rom_base_one_cell_4582/D wl_0_99 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_4464 wrom1_rom_base_one_cell_4582/D_r66 wrom1_rom_base_one_cell_4464/D wl_0_100 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_4046 wrom1_rom_base_one_cell_4464/D_r67 wrom1_rom_base_one_cell_4046/D wl_0_103 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_3915 wrom1_rom_base_one_cell_4046/D_r68 wrom1_rom_base_one_cell_3915/D wl_0_104 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_3807 wrom1_rom_base_one_cell_3915/D_r69 wrom1_rom_base_one_cell_3807/D wl_0_105 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_3536 wrom1_rom_base_one_cell_3807/D_r70 wrom1_rom_base_one_cell_3536/D wl_0_107 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_3281 wrom1_rom_base_one_cell_3536/D_r71 wrom1_rom_base_one_cell_3281/D wl_0_109 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_3143 wrom1_rom_base_one_cell_3281/D_r72 wrom1_rom_base_one_cell_3143/D wl_0_110 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_2880 wrom1_rom_base_one_cell_3143/D_r73 wrom1_rom_base_one_cell_2880/D wl_0_112 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_2731 wrom1_rom_base_one_cell_2880/D_r74 wrom1_rom_base_one_cell_2731/D wl_0_113 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_2479 wrom1_rom_base_one_cell_2731/D_r75 wrom1_rom_base_one_cell_2479/D wl_0_115 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_2341 wrom1_rom_base_one_cell_2479/D_r76 wrom1_rom_base_one_cell_2341/D wl_0_116 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_2235 wrom1_rom_base_one_cell_2341/D_r77 wrom1_rom_base_one_cell_2235/D wl_0_117 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1959 wrom1_rom_base_one_cell_2235/D_r78 wrom1_rom_base_one_cell_1959/D wl_0_119 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1846 wrom1_rom_base_one_cell_1959/D_r79 wrom1_rom_base_one_cell_1846/D wl_0_120 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1718 wrom1_rom_base_one_cell_1846/D_r80 wrom1_rom_base_one_cell_1718/D wl_0_121 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1581 wrom1_rom_base_one_cell_1718/D_r81 wrom1_rom_base_one_cell_1581/D wl_0_122 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1449 wrom1_rom_base_one_cell_1581/D_r82 wrom1_rom_base_one_cell_1449/D wl_0_123 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1214 wrom1_rom_base_one_cell_1449/D_r83 wrom1_rom_base_one_cell_1214/D wl_0_125 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1078 wrom1_rom_base_one_cell_1214/D_r84 wrom1_rom_base_one_cell_652/S wl_0_126 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_652 wrom1_rom_base_one_cell_652/S_r85 wrom1_rom_base_one_cell_652/D wl_0_129 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_274 wrom1_rom_base_one_cell_652/D_r86 wrom1_rom_base_one_cell_41/S wl_0_132 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_41 wrom1_rom_base_one_cell_41/S_r87 gnd_uq0 precharge gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_zero_cell_16588 bl_0_214 wl_0_1 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_16709 bl_0_214 wl_0_0 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_16454 bl_0_214 wl_0_2 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_16080 wrom1_rom_base_one_cell_16848/D wl_0_5 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_15818 wrom1_rom_base_one_cell_16597/D wl_0_7 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_15565 wrom1_rom_base_one_cell_16351/D wl_0_9 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_15187 wrom1_rom_base_one_cell_15964/D wl_0_12 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_14836 wrom1_rom_base_one_cell_15550/D wl_0_15 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_14234 wrom1_rom_base_one_cell_14872/D wl_0_20 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_13977 wrom1_rom_base_one_cell_14600/D wl_0_22 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_13596 wrom1_rom_base_one_cell_14223/D wl_0_25 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_13325 wrom1_rom_base_one_cell_13963/D wl_0_27 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_12011 wrom1_rom_base_one_cell_12718/D wl_0_37 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_10837 wrom1_rom_base_one_cell_11612/D wl_0_46 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_10578 wrom1_rom_base_one_cell_11342/D wl_0_48 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_9962 wrom1_rom_base_zero_cell_9962/S wl_0_53 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_10105 wrom1_rom_base_zero_cell_9962/S wl_0_52 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_9450 wrom1_rom_base_one_cell_9932/S wl_0_57 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_8766 wrom1_rom_base_one_cell_9570/D wl_0_62 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_8510 wrom1_rom_base_one_cell_9325/D wl_0_64 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_7994 wrom1_rom_base_one_cell_8819/D wl_0_68 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_7262 wrom1_rom_base_one_cell_8017/D wl_0_74 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_6901 wrom1_rom_base_one_cell_7743/D wl_0_77 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_6777 wrom1_rom_base_one_cell_7743/D wl_0_78 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_7030 wrom1_rom_base_one_cell_7743/D wl_0_76 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_6650 wrom1_rom_base_one_cell_7743/D wl_0_79 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_6396 wrom1_rom_base_one_cell_7091/D wl_0_81 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_5902 wrom1_rom_base_one_cell_6827/D wl_0_85 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_6027 wrom1_rom_base_one_cell_6827/D wl_0_84 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_6147 wrom1_rom_base_one_cell_6827/D wl_0_83 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_5149 wrom1_rom_base_one_cell_5769/D wl_0_91 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_4774 wrom1_rom_base_one_cell_5377/D wl_0_94 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_4290 wrom1_rom_base_one_cell_4966/D wl_0_98 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_4415 wrom1_rom_base_one_cell_4966/D wl_0_97 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_3791 wrom1_rom_base_one_cell_4464/D wl_0_102 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_3904 wrom1_rom_base_one_cell_4464/D wl_0_101 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_3277 wrom1_rom_base_one_cell_3807/D wl_0_106 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_3032 wrom1_rom_base_one_cell_3536/D wl_0_108 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_2669 wrom1_rom_base_one_cell_3143/D wl_0_111 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_2302 wrom1_rom_base_one_cell_2731/D wl_0_114 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_1789 wrom1_rom_base_one_cell_2235/D wl_0_118 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_1012 wrom1_rom_base_one_cell_1449/D wl_0_124 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_519 wrom1_rom_base_one_cell_652/S wl_0_128 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_642 wrom1_rom_base_one_cell_652/S wl_0_127 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_144 wrom1_rom_base_one_cell_652/D wl_0_131 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_277 wrom1_rom_base_one_cell_652/D wl_0_130 gnd wrom1_rom_base_zero_cell
Rw0 bl_0_214 bl_0_214_r 505.3714
Rw1 wrom1_rom_base_one_cell_16988/D wrom1_rom_base_one_cell_16988/D_r1 505.3714
Rw2 wrom1_rom_base_one_cell_16848/D wrom1_rom_base_one_cell_16848/D_r2 505.3714
Rw3 wrom1_rom_base_one_cell_16597/D wrom1_rom_base_one_cell_16597/D_r3 505.3714
Rw4 wrom1_rom_base_one_cell_16351/D wrom1_rom_base_one_cell_16351/D_r4 505.3714
Rw5 wrom1_rom_base_one_cell_16089/D wrom1_rom_base_one_cell_16089/D_r5 505.3714
Rw6 wrom1_rom_base_one_cell_15964/D wrom1_rom_base_one_cell_15964/D_r6 505.3714
Rw7 wrom1_rom_base_one_cell_15692/D wrom1_rom_base_one_cell_15692/D_r7 505.3714
Rw8 wrom1_rom_base_one_cell_15550/D wrom1_rom_base_one_cell_15550/D_r8 505.3714
Rw9 wrom1_rom_base_one_cell_15279/D wrom1_rom_base_one_cell_15279/D_r9 505.3714
Rw10 wrom1_rom_base_one_cell_15147/D wrom1_rom_base_one_cell_15147/D_r10 505.3714
Rw11 wrom1_rom_base_one_cell_15011/D wrom1_rom_base_one_cell_15011/D_r11 505.3714
Rw12 wrom1_rom_base_one_cell_14872/D wrom1_rom_base_one_cell_14872/D_r12 505.3714
Rw13 wrom1_rom_base_one_cell_14600/D wrom1_rom_base_one_cell_14600/D_r13 505.3714
Rw14 wrom1_rom_base_one_cell_14363/D wrom1_rom_base_one_cell_14363/D_r14 505.3714
Rw15 wrom1_rom_base_one_cell_14223/D wrom1_rom_base_one_cell_14223/D_r15 505.3714
Rw16 wrom1_rom_base_one_cell_13963/D wrom1_rom_base_one_cell_13963/D_r16 505.3714
Rw17 wrom1_rom_base_one_cell_13730/D wrom1_rom_base_one_cell_13730/D_r17 505.3714
Rw18 wrom1_rom_base_one_cell_13591/D wrom1_rom_base_one_cell_13591/D_r18 505.3714
Rw19 wrom1_rom_base_one_cell_13468/D wrom1_rom_base_one_cell_13468/D_r19 505.3714
Rw20 wrom1_rom_base_one_cell_13345/D wrom1_rom_base_one_cell_13345/D_r20 505.3714
Rw21 wrom1_rom_base_one_cell_13213/D wrom1_rom_base_one_cell_13213/D_r21 505.3714
Rw22 wrom1_rom_base_one_cell_13072/D wrom1_rom_base_one_cell_13072/D_r22 505.3714
Rw23 wrom1_rom_base_one_cell_12936/D wrom1_rom_base_one_cell_12936/D_r23 505.3714
Rw24 wrom1_rom_base_one_cell_12829/D wrom1_rom_base_one_cell_12829/D_r24 505.3714
Rw25 wrom1_rom_base_one_cell_12718/D wrom1_rom_base_one_cell_12718/D_r25 505.3714
Rw26 wrom1_rom_base_one_cell_12478/D wrom1_rom_base_one_cell_12478/D_r26 505.3714
Rw27 wrom1_rom_base_one_cell_12347/D wrom1_rom_base_one_cell_12347/D_r27 505.3714
Rw28 wrom1_rom_base_one_cell_12245/D wrom1_rom_base_one_cell_12245/D_r28 505.3714
Rw29 wrom1_rom_base_one_cell_12105/D wrom1_rom_base_one_cell_12105/D_r29 505.3714
Rw30 wrom1_rom_base_one_cell_11980/D wrom1_rom_base_one_cell_11980/D_r30 505.3714
Rw31 wrom1_rom_base_one_cell_11861/D wrom1_rom_base_one_cell_11861/D_r31 505.3714
Rw32 wrom1_rom_base_one_cell_11736/D wrom1_rom_base_one_cell_11736/D_r32 505.3714
Rw33 wrom1_rom_base_one_cell_11612/D wrom1_rom_base_one_cell_11612/D_r33 505.3714
Rw34 wrom1_rom_base_one_cell_11342/D wrom1_rom_base_one_cell_11342/D_r34 505.3714
Rw35 wrom1_rom_base_one_cell_11078/D wrom1_rom_base_one_cell_11078/D_r35 505.3714
Rw36 wrom1_rom_base_one_cell_10954/D wrom1_rom_base_one_cell_10954/D_r36 505.3714
Rw37 wrom1_rom_base_zero_cell_9962/S wrom1_rom_base_zero_cell_9962/S_r37 505.3714
Rw38 wrom1_rom_base_one_cell_10439/D wrom1_rom_base_one_cell_10439/D_r38 505.3714
Rw39 wrom1_rom_base_one_cell_10302/D wrom1_rom_base_one_cell_10302/D_r39 505.3714
Rw40 wrom1_rom_base_one_cell_9932/S wrom1_rom_base_one_cell_9932/S_r40 505.3714
Rw41 wrom1_rom_base_one_cell_9932/D wrom1_rom_base_one_cell_9932/D_r41 505.3714
Rw42 wrom1_rom_base_one_cell_9833/D wrom1_rom_base_one_cell_9833/D_r42 505.3714
Rw43 wrom1_rom_base_one_cell_9712/D wrom1_rom_base_one_cell_9712/D_r43 505.3714
Rw44 wrom1_rom_base_one_cell_9570/D wrom1_rom_base_one_cell_9570/D_r44 505.3714
Rw45 wrom1_rom_base_one_cell_9325/D wrom1_rom_base_one_cell_9325/D_r45 505.3714
Rw46 wrom1_rom_base_one_cell_9071/D wrom1_rom_base_one_cell_9071/D_r46 505.3714
Rw47 wrom1_rom_base_one_cell_8947/D wrom1_rom_base_one_cell_8947/D_r47 505.3714
Rw48 wrom1_rom_base_one_cell_8819/D wrom1_rom_base_one_cell_8819/D_r48 505.3714
Rw49 wrom1_rom_base_one_cell_8555/D wrom1_rom_base_one_cell_8555/D_r49 505.3714
Rw50 wrom1_rom_base_one_cell_8436/D wrom1_rom_base_one_cell_8436/D_r50 505.3714
Rw51 wrom1_rom_base_one_cell_8300/D wrom1_rom_base_one_cell_8300/D_r51 505.3714
Rw52 wrom1_rom_base_one_cell_8149/D wrom1_rom_base_one_cell_8149/D_r52 505.3714
Rw53 wrom1_rom_base_one_cell_8017/D wrom1_rom_base_one_cell_8017/D_r53 505.3714
Rw54 wrom1_rom_base_one_cell_7743/D wrom1_rom_base_one_cell_7743/D_r54 505.3714
Rw55 wrom1_rom_base_one_cell_7091/D wrom1_rom_base_one_cell_7091/D_r55 505.3714
Rw56 wrom1_rom_base_one_cell_6827/D wrom1_rom_base_one_cell_6827/D_r56 505.3714
Rw57 wrom1_rom_base_one_cell_6283/D wrom1_rom_base_one_cell_6283/D_r57 505.3714
Rw58 wrom1_rom_base_one_cell_6146/D wrom1_rom_base_one_cell_6146/D_r58 505.3714
Rw59 wrom1_rom_base_one_cell_6034/D wrom1_rom_base_one_cell_6034/D_r59 505.3714
Rw60 wrom1_rom_base_one_cell_5901/D wrom1_rom_base_one_cell_5901/D_r60 505.3714
Rw61 wrom1_rom_base_one_cell_5769/D wrom1_rom_base_one_cell_5769/D_r61 505.3714
Rw62 wrom1_rom_base_one_cell_5515/D wrom1_rom_base_one_cell_5515/D_r62 505.3714
Rw63 wrom1_rom_base_one_cell_5377/D wrom1_rom_base_one_cell_5377/D_r63 505.3714
Rw64 wrom1_rom_base_one_cell_5115/D wrom1_rom_base_one_cell_5115/D_r64 505.3714
Rw65 wrom1_rom_base_one_cell_4966/D wrom1_rom_base_one_cell_4966/D_r65 505.3714
Rw66 wrom1_rom_base_one_cell_4582/D wrom1_rom_base_one_cell_4582/D_r66 505.3714
Rw67 wrom1_rom_base_one_cell_4464/D wrom1_rom_base_one_cell_4464/D_r67 505.3714
Rw68 wrom1_rom_base_one_cell_4046/D wrom1_rom_base_one_cell_4046/D_r68 505.3714
Rw69 wrom1_rom_base_one_cell_3915/D wrom1_rom_base_one_cell_3915/D_r69 505.3714
Rw70 wrom1_rom_base_one_cell_3807/D wrom1_rom_base_one_cell_3807/D_r70 505.3714
Rw71 wrom1_rom_base_one_cell_3536/D wrom1_rom_base_one_cell_3536/D_r71 505.3714
Rw72 wrom1_rom_base_one_cell_3281/D wrom1_rom_base_one_cell_3281/D_r72 505.3714
Rw73 wrom1_rom_base_one_cell_3143/D wrom1_rom_base_one_cell_3143/D_r73 505.3714
Rw74 wrom1_rom_base_one_cell_2880/D wrom1_rom_base_one_cell_2880/D_r74 505.3714
Rw75 wrom1_rom_base_one_cell_2731/D wrom1_rom_base_one_cell_2731/D_r75 505.3714
Rw76 wrom1_rom_base_one_cell_2479/D wrom1_rom_base_one_cell_2479/D_r76 505.3714
Rw77 wrom1_rom_base_one_cell_2341/D wrom1_rom_base_one_cell_2341/D_r77 505.3714
Rw78 wrom1_rom_base_one_cell_2235/D wrom1_rom_base_one_cell_2235/D_r78 505.3714
Rw79 wrom1_rom_base_one_cell_1959/D wrom1_rom_base_one_cell_1959/D_r79 505.3714
Rw80 wrom1_rom_base_one_cell_1846/D wrom1_rom_base_one_cell_1846/D_r80 505.3714
Rw81 wrom1_rom_base_one_cell_1718/D wrom1_rom_base_one_cell_1718/D_r81 505.3714
Rw82 wrom1_rom_base_one_cell_1581/D wrom1_rom_base_one_cell_1581/D_r82 505.3714
Rw83 wrom1_rom_base_one_cell_1449/D wrom1_rom_base_one_cell_1449/D_r83 505.3714
Rw84 wrom1_rom_base_one_cell_1214/D wrom1_rom_base_one_cell_1214/D_r84 505.3714
Rw85 wrom1_rom_base_one_cell_652/S wrom1_rom_base_one_cell_652/S_r85 505.3714
Rw86 wrom1_rom_base_one_cell_652/D wrom1_rom_base_one_cell_652/D_r86 505.3714
Rw87 wrom1_rom_base_one_cell_41/S wrom1_rom_base_one_cell_41/S_r87 505.3714

.subckt wrom1_rom_base_one_cell S D G gnd
X0 D G S gnd sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.108u ps=1.32 w=0.36 l=0.15
C0 S G 0.00394f
C1 S D 0.04533f
C2 D G 0.00394f
C3 S gnd 0.05671f
C4 D gnd 0.09245f
C5 G gnd 0.10004f
.ends
.subckt wrom1_rom_base_zero_cell S G gnd
X0 S G S gnd sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.216u ps=2.64 w=0.36 l=0.15
C0 S G 0.01098f
C1 S gnd 0.169f
C2 G gnd 0.10004f
.ends
.subckt wrom1_precharge_cell D G vdd gnd
X0 D G vdd vdd sky130_fd_pr__pfet_01v8 ad=0.126u pd=1.44 as=0.126u ps=1.44 w=0.42 l=0.15
C0 D G 0.00394f
C1 D vdd 0.03592f
C2 G vdd 0.05763f
C3 D gnd 0.05546f
C4 G gnd 0.03904f
C5 vdd gnd 0.33982f
.ends
.subckt wrom1_pinv_dec_3 gnd vdd w_692_n79# A Z
X0 vdd A Z w_692_n79# sky130_fd_pr__pfet_01v8 ad=1.5u pd=10.6 as=1.5u ps=10.6 w=5 l=0.15
X1 gnd A Z gnd sky130_fd_pr__nfet_01v8 ad=0.504u pd=3.96 as=0.504u ps=3.96 w=1.68 l=0.15
C0 w_692_n79# A 0.10891f
C1 vdd Z 0.06954f
C2 vdd A 0.01892f
C3 Z A 0.04991f
C4 w_692_n79# vdd 0.02783f
C5 w_692_n79# Z 0.05333f
C6 vdd gnd 0.06645f
C7 Z gnd 0.35042f
C8 A gnd 0.23452f
C9 w_692_n79# gnd 1.35078f
.ends

.ic v(bl_0_214)={VDD}
* THE FIRST CYCLE IS NOT A MEASUREMENT (found 2026-09-20 from a waveform).
* `.ic` sets the bitline only; with `uic` the 88 internal chain nodes start at
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
.measure tran t_dis_50 TRIG v(precharge) VAL='VDD/2' RISE=1 TD='2.5*TCLK'
+                      TARG v(bl_0_214)   VAL='VDD/2' FALL=1 TD='2.5*TCLK'
.measure tran t_dis_10 TRIG v(precharge) VAL='VDD/2' RISE=1 TD='2.5*TCLK'
+                      TARG v(bl_0_214)   VAL='0.1*VDD' FALL=1 TD='2.5*TCLK'
.measure tran t_dis_50_prev TRIG v(precharge) VAL='VDD/2' RISE=1 TD='1.5*TCLK'
+                           TARG v(bl_0_214)   VAL='VDD/2' FALL=1 TD='1.5*TCLK'

* t_pre_50: the bitline crosses the bitline-inverter trip point on the way
* back up -- this is the moment dout0 STOPS being valid after clk0 falls.
* It feeds the falling_edge arc of the .lib (gen_rom_lib.py --t-invalid).
* t_pre_90/t_pre_99 are the recharge-complete times and are much later, so
* they must NOT be used for that arc.
* These sit on the falling edge that ENDS cycle 2, i.e. after two discharges.
.measure tran t_pre_50 TRIG v(precharge) VAL='VDD/2' FALL=1 TD='1.9*TCLK'
+                      TARG v(bl_0_214)   VAL='VDD/2' RISE=1 TD='1.9*TCLK'
.measure tran t_pre_90 TRIG v(precharge) VAL='VDD/2' FALL=1 TD='1.9*TCLK'
+                      TARG v(bl_0_214)   VAL='0.9*VDD' RISE=1 TD='1.9*TCLK'
.measure tran t_pre_99 TRIG v(precharge) VAL='VDD/2' FALL=1 TD='1.9*TCLK'
+                      TARG v(bl_0_214)   VAL='0.99*VDD' RISE=1 TD='1.9*TCLK'

* 200 ps: the step is not a sensitivity here -- 100 ps against 200 ps moves
* t_dis_50 by 0.007% -- and at a 1 us phase it keeps the run under a few
* minutes.
.tran 200p '3*TCLK'
.end
