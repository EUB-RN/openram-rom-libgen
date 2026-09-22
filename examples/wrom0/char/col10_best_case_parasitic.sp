* wrom0 -- isolated measurement of column 10 with REAL PARASITIC C
* 48 series NMOS + 86 dead cells (graph walk, name independent)
* wire resistance: 505.4 ohm per cell (48 x = 24.3 kohm)

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

Xprechg_pmos bl_0_10 precharge vdd gnd wrom0_precharge_cell
Xbl_inv gnd vdd vdd bl_0_10 bl_b wrom0_pinv_dec_3

Xwrom0_rom_base_one_cell_16873 bl_0_10_r wrom0_rom_base_one_cell_16873/D wl_0_3 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_16738 wrom0_rom_base_one_cell_16873/D_r1 wrom0_rom_base_one_cell_16738/D wl_0_4 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_16056 wrom0_rom_base_one_cell_16738/D_r2 wrom0_rom_base_one_cell_16056/D wl_0_9 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15921 wrom0_rom_base_one_cell_16056/D_r3 wrom0_rom_base_one_cell_15921/D wl_0_10 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15656 wrom0_rom_base_one_cell_15921/D_r4 wrom0_rom_base_one_cell_15656/D wl_0_12 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15528 wrom0_rom_base_one_cell_15656/D_r5 wrom0_rom_base_one_cell_15528/D wl_0_13 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15401 wrom0_rom_base_one_cell_15528/D_r6 wrom0_rom_base_one_cell_15401/D wl_0_14 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15270 wrom0_rom_base_one_cell_15401/D_r7 wrom0_rom_base_one_cell_15270/D wl_0_15 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_14492 wrom0_rom_base_one_cell_15270/D_r8 wrom0_rom_base_one_cell_14492/D wl_0_21 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_13543 wrom0_rom_base_one_cell_14492/D_r9 wrom0_rom_base_one_cell_13543/D wl_0_28 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_13055 wrom0_rom_base_one_cell_13543/D_r10 wrom0_rom_base_one_cell_13055/D wl_0_32 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_12664 wrom0_rom_base_one_cell_13055/D_r11 wrom0_rom_base_one_cell_12664/D wl_0_35 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_12395 wrom0_rom_base_one_cell_12664/D_r12 wrom0_rom_base_one_cell_12395/D wl_0_37 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_12269 wrom0_rom_base_one_cell_12395/D_r13 wrom0_rom_base_one_cell_12269/D wl_0_38 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_11906 wrom0_rom_base_one_cell_12269/D_r14 wrom0_rom_base_one_cell_11906/D wl_0_41 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_11764 wrom0_rom_base_one_cell_11906/D_r15 wrom0_rom_base_one_cell_11764/D wl_0_42 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_11603 wrom0_rom_base_one_cell_11764/D_r16 wrom0_rom_base_one_cell_11603/D wl_0_43 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_11455 wrom0_rom_base_one_cell_11603/D_r17 wrom0_rom_base_one_cell_11455/D wl_0_44 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_11194 wrom0_rom_base_one_cell_11455/D_r18 wrom0_rom_base_one_cell_11194/D wl_0_46 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_11078 wrom0_rom_base_one_cell_11194/D_r19 wrom0_rom_base_one_cell_11078/D wl_0_47 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_10949 wrom0_rom_base_one_cell_11078/D_r20 wrom0_rom_base_one_cell_9611/S wl_0_48 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_9611 wrom0_rom_base_one_cell_9611/S_r21 wrom0_rom_base_one_cell_9611/D wl_0_59 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_9367 wrom0_rom_base_one_cell_9611/D_r22 wrom0_rom_base_one_cell_9367/D wl_0_61 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_8974 wrom0_rom_base_one_cell_9367/D_r23 wrom0_rom_base_one_cell_8974/D wl_0_64 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_8627 wrom0_rom_base_one_cell_8974/D_r24 wrom0_rom_base_one_cell_8627/D wl_0_67 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_8122 wrom0_rom_base_one_cell_8627/D_r25 wrom0_rom_base_one_cell_8122/D wl_0_71 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_8000 wrom0_rom_base_one_cell_8122/D_r26 wrom0_rom_base_one_cell_8000/D wl_0_72 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_7386 wrom0_rom_base_one_cell_8000/D_r27 wrom0_rom_base_one_cell_7386/D wl_0_77 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_7014 wrom0_rom_base_one_cell_7386/D_r28 wrom0_rom_base_one_cell_7014/D wl_0_80 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_5771 wrom0_rom_base_one_cell_7014/D_r29 wrom0_rom_base_one_cell_5771/D wl_0_90 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_5656 wrom0_rom_base_one_cell_5771/D_r30 wrom0_rom_base_one_cell_5656/D wl_0_91 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_5405 wrom0_rom_base_one_cell_5656/D_r31 wrom0_rom_base_one_cell_5405/D wl_0_93 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_5154 wrom0_rom_base_one_cell_5405/D_r32 wrom0_rom_base_one_cell_5154/D wl_0_95 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_5020 wrom0_rom_base_one_cell_5154/D_r33 wrom0_rom_base_one_cell_5020/D wl_0_96 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_4778 wrom0_rom_base_one_cell_5020/D_r34 wrom0_rom_base_one_cell_4778/D wl_0_98 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_4665 wrom0_rom_base_one_cell_4778/D_r35 wrom0_rom_base_one_cell_4665/D wl_0_99 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_4360 wrom0_rom_base_one_cell_4665/D_r36 wrom0_rom_base_one_cell_4360/D wl_0_101 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_4014 wrom0_rom_base_one_cell_4360/D_r37 wrom0_rom_base_one_cell_4014/D wl_0_104 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_3251 wrom0_rom_base_one_cell_4014/D_r38 wrom0_rom_base_one_cell_3251/D wl_0_110 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_3109 wrom0_rom_base_one_cell_3251/D_r39 wrom0_rom_base_one_cell_3109/D wl_0_111 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_2975 wrom0_rom_base_one_cell_3109/D_r40 wrom0_rom_base_one_cell_2975/D wl_0_112 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_2864 wrom0_rom_base_one_cell_2975/D_r41 wrom0_rom_base_one_cell_2864/D wl_0_113 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_2212 wrom0_rom_base_one_cell_2864/D_r42 wrom0_rom_base_one_cell_2212/D wl_0_118 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_1958 wrom0_rom_base_one_cell_2212/D_r43 wrom0_rom_base_one_cell_1958/D wl_0_120 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_1426 wrom0_rom_base_one_cell_1958/D_r44 wrom0_rom_base_one_cell_781/S wl_0_124 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_781 wrom0_rom_base_one_cell_781/S_r45 wrom0_rom_base_one_cell_781/D wl_0_129 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_646 wrom0_rom_base_one_cell_781/D_r46 wrom0_rom_base_one_cell_646/D wl_0_130 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_245 wrom0_rom_base_one_cell_646/D_r47 gnd_uq0 precharge gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_zero_cell_16989 bl_0_10 wl_0_0 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_16753 bl_0_10 wl_0_2 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_16862 bl_0_10 wl_0_1 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_16416 wrom0_rom_base_one_cell_16738/D wl_0_5 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_16056 wrom0_rom_base_one_cell_16738/D wl_0_8 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_16300 wrom0_rom_base_one_cell_16738/D wl_0_6 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_16177 wrom0_rom_base_one_cell_16738/D wl_0_7 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_15681 wrom0_rom_base_one_cell_15921/D wl_0_11 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_14683 wrom0_rom_base_one_cell_15270/D wl_0_19 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_14815 wrom0_rom_base_one_cell_15270/D wl_0_18 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_14956 wrom0_rom_base_one_cell_15270/D wl_0_17 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_15082 wrom0_rom_base_one_cell_15270/D wl_0_16 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_14548 wrom0_rom_base_one_cell_15270/D wl_0_20 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_14299 wrom0_rom_base_one_cell_14492/D wl_0_22 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_13928 wrom0_rom_base_one_cell_14492/D wl_0_25 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_14043 wrom0_rom_base_one_cell_14492/D wl_0_24 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_14181 wrom0_rom_base_one_cell_14492/D wl_0_23 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_13802 wrom0_rom_base_one_cell_14492/D wl_0_26 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_13688 wrom0_rom_base_one_cell_14492/D wl_0_27 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_13446 wrom0_rom_base_one_cell_13543/D wl_0_29 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_13300 wrom0_rom_base_one_cell_13543/D wl_0_30 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_13168 wrom0_rom_base_one_cell_13543/D wl_0_31 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_12918 wrom0_rom_base_one_cell_13055/D wl_0_33 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_12784 wrom0_rom_base_one_cell_13055/D wl_0_34 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_12541 wrom0_rom_base_one_cell_12664/D wl_0_36 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_12172 wrom0_rom_base_one_cell_12269/D wl_0_39 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_12032 wrom0_rom_base_one_cell_12269/D wl_0_40 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_11448 wrom0_rom_base_one_cell_11455/D wl_0_45 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_10658 wrom0_rom_base_one_cell_9611/S wl_0_51 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_10809 wrom0_rom_base_one_cell_9611/S wl_0_50 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_10266 wrom0_rom_base_one_cell_9611/S wl_0_54 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_9876 wrom0_rom_base_one_cell_9611/S wl_0_57 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_10001 wrom0_rom_base_one_cell_9611/S wl_0_56 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_10923 wrom0_rom_base_one_cell_9611/S wl_0_49 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_10388 wrom0_rom_base_one_cell_9611/S wl_0_53 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_10515 wrom0_rom_base_one_cell_9611/S wl_0_52 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_10134 wrom0_rom_base_one_cell_9611/S wl_0_55 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_9724 wrom0_rom_base_one_cell_9611/S wl_0_58 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_9443 wrom0_rom_base_one_cell_9611/D wl_0_60 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_9187 wrom0_rom_base_one_cell_9367/D wl_0_62 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_9053 wrom0_rom_base_one_cell_9367/D wl_0_63 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_8627 wrom0_rom_base_one_cell_8974/D wl_0_66 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_8785 wrom0_rom_base_one_cell_8974/D wl_0_65 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_8258 wrom0_rom_base_one_cell_8627/D wl_0_69 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_8387 wrom0_rom_base_one_cell_8627/D wl_0_68 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_8137 wrom0_rom_base_one_cell_8627/D wl_0_70 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_7731 wrom0_rom_base_one_cell_8000/D wl_0_73 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_7583 wrom0_rom_base_one_cell_8000/D wl_0_74 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_7324 wrom0_rom_base_one_cell_8000/D wl_0_76 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_7455 wrom0_rom_base_one_cell_8000/D wl_0_75 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_7071 wrom0_rom_base_one_cell_7386/D wl_0_78 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_6936 wrom0_rom_base_one_cell_7386/D wl_0_79 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_6527 wrom0_rom_base_one_cell_7014/D wl_0_82 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_5605 wrom0_rom_base_one_cell_7014/D wl_0_89 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_6671 wrom0_rom_base_one_cell_7014/D wl_0_81 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_6105 wrom0_rom_base_one_cell_7014/D wl_0_85 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_5975 wrom0_rom_base_one_cell_7014/D wl_0_86 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_5735 wrom0_rom_base_one_cell_7014/D wl_0_88 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_6245 wrom0_rom_base_one_cell_7014/D wl_0_84 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_5860 wrom0_rom_base_one_cell_7014/D wl_0_87 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_6388 wrom0_rom_base_one_cell_7014/D wl_0_83 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_5202 wrom0_rom_base_one_cell_5656/D wl_0_92 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_4952 wrom0_rom_base_one_cell_5405/D wl_0_94 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_4554 wrom0_rom_base_one_cell_5020/D wl_0_97 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_4178 wrom0_rom_base_one_cell_4665/D wl_0_100 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_3792 wrom0_rom_base_one_cell_4360/D wl_0_103 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_3938 wrom0_rom_base_one_cell_4360/D wl_0_102 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_2991 wrom0_rom_base_one_cell_4014/D wl_0_109 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_3410 wrom0_rom_base_one_cell_4014/D wl_0_106 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_3253 wrom0_rom_base_one_cell_4014/D wl_0_107 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_3515 wrom0_rom_base_one_cell_4014/D wl_0_105 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_3121 wrom0_rom_base_one_cell_4014/D wl_0_108 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_2252 wrom0_rom_base_one_cell_2864/D wl_0_115 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_2389 wrom0_rom_base_one_cell_2864/D wl_0_114 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_2131 wrom0_rom_base_one_cell_2864/D wl_0_116 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_1999 wrom0_rom_base_one_cell_2864/D wl_0_117 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_1743 wrom0_rom_base_one_cell_2212/D wl_0_119 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_1371 wrom0_rom_base_one_cell_1958/D wl_0_122 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_1506 wrom0_rom_base_one_cell_1958/D wl_0_121 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_1240 wrom0_rom_base_one_cell_1958/D wl_0_123 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_1004 wrom0_rom_base_one_cell_781/S wl_0_125 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_879 wrom0_rom_base_one_cell_781/S wl_0_126 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_619 wrom0_rom_base_one_cell_781/S wl_0_128 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_748 wrom0_rom_base_one_cell_781/S wl_0_127 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_127 wrom0_rom_base_one_cell_646/D wl_0_132 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_261 wrom0_rom_base_one_cell_646/D wl_0_131 gnd wrom0_rom_base_zero_cell
Rw0 bl_0_10 bl_0_10_r 505.3714
Rw1 wrom0_rom_base_one_cell_16873/D wrom0_rom_base_one_cell_16873/D_r1 505.3714
Rw2 wrom0_rom_base_one_cell_16738/D wrom0_rom_base_one_cell_16738/D_r2 505.3714
Rw3 wrom0_rom_base_one_cell_16056/D wrom0_rom_base_one_cell_16056/D_r3 505.3714
Rw4 wrom0_rom_base_one_cell_15921/D wrom0_rom_base_one_cell_15921/D_r4 505.3714
Rw5 wrom0_rom_base_one_cell_15656/D wrom0_rom_base_one_cell_15656/D_r5 505.3714
Rw6 wrom0_rom_base_one_cell_15528/D wrom0_rom_base_one_cell_15528/D_r6 505.3714
Rw7 wrom0_rom_base_one_cell_15401/D wrom0_rom_base_one_cell_15401/D_r7 505.3714
Rw8 wrom0_rom_base_one_cell_15270/D wrom0_rom_base_one_cell_15270/D_r8 505.3714
Rw9 wrom0_rom_base_one_cell_14492/D wrom0_rom_base_one_cell_14492/D_r9 505.3714
Rw10 wrom0_rom_base_one_cell_13543/D wrom0_rom_base_one_cell_13543/D_r10 505.3714
Rw11 wrom0_rom_base_one_cell_13055/D wrom0_rom_base_one_cell_13055/D_r11 505.3714
Rw12 wrom0_rom_base_one_cell_12664/D wrom0_rom_base_one_cell_12664/D_r12 505.3714
Rw13 wrom0_rom_base_one_cell_12395/D wrom0_rom_base_one_cell_12395/D_r13 505.3714
Rw14 wrom0_rom_base_one_cell_12269/D wrom0_rom_base_one_cell_12269/D_r14 505.3714
Rw15 wrom0_rom_base_one_cell_11906/D wrom0_rom_base_one_cell_11906/D_r15 505.3714
Rw16 wrom0_rom_base_one_cell_11764/D wrom0_rom_base_one_cell_11764/D_r16 505.3714
Rw17 wrom0_rom_base_one_cell_11603/D wrom0_rom_base_one_cell_11603/D_r17 505.3714
Rw18 wrom0_rom_base_one_cell_11455/D wrom0_rom_base_one_cell_11455/D_r18 505.3714
Rw19 wrom0_rom_base_one_cell_11194/D wrom0_rom_base_one_cell_11194/D_r19 505.3714
Rw20 wrom0_rom_base_one_cell_11078/D wrom0_rom_base_one_cell_11078/D_r20 505.3714
Rw21 wrom0_rom_base_one_cell_9611/S wrom0_rom_base_one_cell_9611/S_r21 505.3714
Rw22 wrom0_rom_base_one_cell_9611/D wrom0_rom_base_one_cell_9611/D_r22 505.3714
Rw23 wrom0_rom_base_one_cell_9367/D wrom0_rom_base_one_cell_9367/D_r23 505.3714
Rw24 wrom0_rom_base_one_cell_8974/D wrom0_rom_base_one_cell_8974/D_r24 505.3714
Rw25 wrom0_rom_base_one_cell_8627/D wrom0_rom_base_one_cell_8627/D_r25 505.3714
Rw26 wrom0_rom_base_one_cell_8122/D wrom0_rom_base_one_cell_8122/D_r26 505.3714
Rw27 wrom0_rom_base_one_cell_8000/D wrom0_rom_base_one_cell_8000/D_r27 505.3714
Rw28 wrom0_rom_base_one_cell_7386/D wrom0_rom_base_one_cell_7386/D_r28 505.3714
Rw29 wrom0_rom_base_one_cell_7014/D wrom0_rom_base_one_cell_7014/D_r29 505.3714
Rw30 wrom0_rom_base_one_cell_5771/D wrom0_rom_base_one_cell_5771/D_r30 505.3714
Rw31 wrom0_rom_base_one_cell_5656/D wrom0_rom_base_one_cell_5656/D_r31 505.3714
Rw32 wrom0_rom_base_one_cell_5405/D wrom0_rom_base_one_cell_5405/D_r32 505.3714
Rw33 wrom0_rom_base_one_cell_5154/D wrom0_rom_base_one_cell_5154/D_r33 505.3714
Rw34 wrom0_rom_base_one_cell_5020/D wrom0_rom_base_one_cell_5020/D_r34 505.3714
Rw35 wrom0_rom_base_one_cell_4778/D wrom0_rom_base_one_cell_4778/D_r35 505.3714
Rw36 wrom0_rom_base_one_cell_4665/D wrom0_rom_base_one_cell_4665/D_r36 505.3714
Rw37 wrom0_rom_base_one_cell_4360/D wrom0_rom_base_one_cell_4360/D_r37 505.3714
Rw38 wrom0_rom_base_one_cell_4014/D wrom0_rom_base_one_cell_4014/D_r38 505.3714
Rw39 wrom0_rom_base_one_cell_3251/D wrom0_rom_base_one_cell_3251/D_r39 505.3714
Rw40 wrom0_rom_base_one_cell_3109/D wrom0_rom_base_one_cell_3109/D_r40 505.3714
Rw41 wrom0_rom_base_one_cell_2975/D wrom0_rom_base_one_cell_2975/D_r41 505.3714
Rw42 wrom0_rom_base_one_cell_2864/D wrom0_rom_base_one_cell_2864/D_r42 505.3714
Rw43 wrom0_rom_base_one_cell_2212/D wrom0_rom_base_one_cell_2212/D_r43 505.3714
Rw44 wrom0_rom_base_one_cell_1958/D wrom0_rom_base_one_cell_1958/D_r44 505.3714
Rw45 wrom0_rom_base_one_cell_781/S wrom0_rom_base_one_cell_781/S_r45 505.3714
Rw46 wrom0_rom_base_one_cell_781/D wrom0_rom_base_one_cell_781/D_r46 505.3714
Rw47 wrom0_rom_base_one_cell_646/D wrom0_rom_base_one_cell_646/D_r47 505.3714

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

.ic v(bl_0_10)={VDD}
* THE FIRST CYCLE IS NOT A MEASUREMENT (found 2026-09-20 from a waveform).
* `.ic` sets the bitline only; with `uic` the 48 internal chain nodes start at
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
+                      TARG v(bl_0_10)   VAL='VDD/2' FALL=1 TD='2.5*TCLK'
.measure tran t_dis_10 TRIG v(precharge) VAL='VDD/2' RISE=1 TD='2.5*TCLK'
+                      TARG v(bl_0_10)   VAL='0.1*VDD' FALL=1 TD='2.5*TCLK'
.measure tran t_dis_50_prev TRIG v(precharge) VAL='VDD/2' RISE=1 TD='1.5*TCLK'
+                           TARG v(bl_0_10)   VAL='VDD/2' FALL=1 TD='1.5*TCLK'

* t_pre_50: the bitline crosses the bitline-inverter trip point on the way
* back up -- this is the moment dout0 STOPS being valid after clk0 falls.
* It feeds the falling_edge arc of the .lib (gen_rom_lib.py --t-invalid).
* t_pre_90/t_pre_99 are the recharge-complete times and are much later, so
* they must NOT be used for that arc.
* These sit on the falling edge that ENDS cycle 2, i.e. after two discharges.
.measure tran t_pre_50 TRIG v(precharge) VAL='VDD/2' FALL=1 TD='1.9*TCLK'
+                      TARG v(bl_0_10)   VAL='VDD/2' RISE=1 TD='1.9*TCLK'
.measure tran t_pre_90 TRIG v(precharge) VAL='VDD/2' FALL=1 TD='1.9*TCLK'
+                      TARG v(bl_0_10)   VAL='0.9*VDD' RISE=1 TD='1.9*TCLK'
.measure tran t_pre_99 TRIG v(precharge) VAL='VDD/2' FALL=1 TD='1.9*TCLK'
+                      TARG v(bl_0_10)   VAL='0.99*VDD' RISE=1 TD='1.9*TCLK'

* 200 ps: the step is not a sensitivity here -- 100 ps against 200 ps moves
* t_dis_50 by 0.007% -- and at a 1 us phase it keeps the run under a few
* minutes.
.tran 200p '3*TCLK'
.end
