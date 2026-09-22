* wrom1 -- isolated measurement of column 50 with REAL PARASITIC C
* 1 series NMOS + 82 dead cells (graph walk, name independent)
* wire resistance: 505.4 ohm per cell (1 x = 0.5 kohm)

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

Xprechg_pmos bl_0_50 precharge vdd gnd wrom1_precharge_cell
Xbl_inv gnd vdd vdd bl_0_50 bl_b wrom1_pinv_dec_3

Xwrom1_rom_base_one_cell_205 wrom1_rom_base_one_cell_364/D_r0 gnd_uq0 precharge gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_zero_cell_16785 bl_0_50 wl_0_0 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_16548 wrom1_rom_base_one_cell_17324/D wl_0_2 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_16027 wrom1_rom_base_one_cell_16931/D wl_0_6 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_15896 wrom1_rom_base_one_cell_16931/D wl_0_7 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_16170 wrom1_rom_base_one_cell_16931/D wl_0_5 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_15769 wrom1_rom_base_one_cell_16931/D wl_0_8 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_15267 wrom1_rom_base_one_cell_16172/D wl_0_12 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_15396 wrom1_rom_base_one_cell_16172/D wl_0_11 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_14784 wrom1_rom_base_one_cell_15497/D wl_0_16 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_14434 wrom1_rom_base_one_cell_15230/D wl_0_19 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_14190 wrom1_rom_base_one_cell_15230/D wl_0_21 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_14543 wrom1_rom_base_one_cell_15230/D wl_0_18 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_14315 wrom1_rom_base_one_cell_15230/D wl_0_20 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_13552 wrom1_rom_base_one_cell_14312/D wl_0_26 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_13683 wrom1_rom_base_one_cell_14312/D wl_0_25 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_13426 wrom1_rom_base_one_cell_14312/D wl_0_27 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_13155 wrom1_rom_base_one_cell_13810/D wl_0_29 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_12765 wrom1_rom_base_one_cell_13427/D wl_0_32 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_12528 wrom1_rom_base_one_cell_13164/D wl_0_34 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_11970 wrom1_rom_base_one_cell_13164/D wl_0_38 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_12109 wrom1_rom_base_one_cell_13164/D wl_0_37 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_12400 wrom1_rom_base_one_cell_13164/D wl_0_35 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_12244 wrom1_rom_base_one_cell_13164/D wl_0_36 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_11704 wrom1_rom_base_one_cell_13164/D wl_0_40 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_11831 wrom1_rom_base_one_cell_13164/D wl_0_39 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_10914 wrom1_rom_base_one_cell_12203/D wl_0_46 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_11039 wrom1_rom_base_one_cell_12203/D wl_0_45 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_11313 wrom1_rom_base_one_cell_12203/D wl_0_43 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_11179 wrom1_rom_base_one_cell_12203/D wl_0_44 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_11440 wrom1_rom_base_one_cell_12203/D wl_0_42 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_10536 wrom1_rom_base_one_cell_11302/D wl_0_49 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_10294 wrom1_rom_base_one_cell_11302/D wl_0_51 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_10426 wrom1_rom_base_one_cell_11302/D wl_0_50 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_9927 wrom1_rom_base_zero_cell_9927/S wl_0_54 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_10050 wrom1_rom_base_zero_cell_9927/S wl_0_53 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_8718 wrom1_rom_base_one_cell_9662/D wl_0_63 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_8851 wrom1_rom_base_one_cell_9662/D wl_0_62 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_8337 wrom1_rom_base_one_cell_9280/D wl_0_66 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_8460 wrom1_rom_base_one_cell_9280/D wl_0_65 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_8201 wrom1_rom_base_one_cell_9280/D wl_0_67 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_7682 wrom1_rom_base_one_cell_8766/D wl_0_71 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_7820 wrom1_rom_base_one_cell_8766/D wl_0_70 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_7948 wrom1_rom_base_one_cell_8766/D wl_0_69 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_7346 wrom1_rom_base_one_cell_8252/D wl_0_74 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_6980 wrom1_rom_base_one_cell_8252/D wl_0_77 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_7106 wrom1_rom_base_one_cell_8252/D wl_0_76 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_7461 wrom1_rom_base_one_cell_8252/D wl_0_73 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_7224 wrom1_rom_base_one_cell_8252/D wl_0_75 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_6730 wrom1_rom_base_one_cell_7432/D wl_0_79 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_6479 wrom1_rom_base_one_cell_7164/D wl_0_81 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_5868 wrom1_rom_base_one_cell_6511/D wl_0_86 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_5355 wrom1_rom_base_one_cell_6229/D wl_0_90 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_5106 wrom1_rom_base_one_cell_6229/D wl_0_92 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_5476 wrom1_rom_base_one_cell_6229/D wl_0_89 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_5625 wrom1_rom_base_one_cell_6229/D wl_0_88 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_5234 wrom1_rom_base_one_cell_6229/D wl_0_91 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_4504 wrom1_rom_base_one_cell_5058/D wl_0_97 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_4111 wrom1_rom_base_one_cell_4670/D wl_0_100 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_3635 wrom1_rom_base_one_cell_4417/D wl_0_104 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_2979 wrom1_rom_base_one_cell_4417/D wl_0_109 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_2736 wrom1_rom_base_one_cell_4417/D wl_0_111 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_3235 wrom1_rom_base_one_cell_4417/D wl_0_107 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_3746 wrom1_rom_base_one_cell_4417/D wl_0_103 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_2859 wrom1_rom_base_one_cell_4417/D wl_0_110 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_3347 wrom1_rom_base_one_cell_4417/D wl_0_106 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_3492 wrom1_rom_base_one_cell_4417/D wl_0_105 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_3866 wrom1_rom_base_one_cell_4417/D wl_0_102 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_3119 wrom1_rom_base_one_cell_4417/D wl_0_108 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_2393 wrom1_rom_base_one_cell_2961/D wl_0_114 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_2492 wrom1_rom_base_one_cell_2961/D wl_0_113 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_2247 wrom1_rom_base_one_cell_2961/D wl_0_115 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_2003 wrom1_rom_base_one_cell_2426/D wl_0_117 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_958 wrom1_rom_base_zero_cell_958/S wl_0_125 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_1107 wrom1_rom_base_zero_cell_958/S wl_0_124 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_1615 wrom1_rom_base_zero_cell_958/S wl_0_120 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_1468 wrom1_rom_base_zero_cell_958/S wl_0_121 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_1236 wrom1_rom_base_zero_cell_958/S wl_0_123 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_1741 wrom1_rom_base_zero_cell_958/S wl_0_119 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_1350 wrom1_rom_base_zero_cell_958/S wl_0_122 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_719 wrom1_rom_base_one_cell_889/S wl_0_127 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_477 wrom1_rom_base_one_cell_889/D wl_0_129 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_221 wrom1_rom_base_one_cell_609/D wl_0_131 gnd wrom1_rom_base_zero_cell
Rstrap0 bl_0_50 wrom1_rom_base_one_cell_17324/D 0.2411
Xsyn_zero0 bl_0_50 wl_0_1 gnd wrom1_rom_base_zero_cell
Rstrap1 wrom1_rom_base_one_cell_17324/D wrom1_rom_base_one_cell_17070/D 0.2411
Xsyn_zero1 wrom1_rom_base_one_cell_17324/D wl_0_3 gnd wrom1_rom_base_zero_cell
Rstrap2 wrom1_rom_base_one_cell_17070/D wrom1_rom_base_one_cell_16931/D 0.2411
Xsyn_zero2 wrom1_rom_base_one_cell_17070/D wl_0_4 gnd wrom1_rom_base_zero_cell
Rstrap3 wrom1_rom_base_one_cell_16931/D wrom1_rom_base_one_cell_16297/D 0.2411
Xsyn_zero3 wrom1_rom_base_one_cell_16931/D wl_0_9 gnd wrom1_rom_base_zero_cell
Rstrap4 wrom1_rom_base_one_cell_16297/D wrom1_rom_base_one_cell_16172/D 0.2411
Xsyn_zero4 wrom1_rom_base_one_cell_16297/D wl_0_10 gnd wrom1_rom_base_zero_cell
Rstrap5 wrom1_rom_base_one_cell_16172/D wrom1_rom_base_one_cell_15779/D 0.2411
Xsyn_zero5 wrom1_rom_base_one_cell_16172/D wl_0_13 gnd wrom1_rom_base_zero_cell
Rstrap6 wrom1_rom_base_one_cell_15779/D wrom1_rom_base_one_cell_15643/D 0.2411
Xsyn_zero6 wrom1_rom_base_one_cell_15779/D wl_0_14 gnd wrom1_rom_base_zero_cell
Rstrap7 wrom1_rom_base_one_cell_15643/D wrom1_rom_base_one_cell_15497/D 0.2411
Xsyn_zero7 wrom1_rom_base_one_cell_15643/D wl_0_15 gnd wrom1_rom_base_zero_cell
Rstrap8 wrom1_rom_base_one_cell_15497/D wrom1_rom_base_one_cell_15230/D 0.2411
Xsyn_zero8 wrom1_rom_base_one_cell_15497/D wl_0_17 gnd wrom1_rom_base_zero_cell
Rstrap9 wrom1_rom_base_one_cell_15230/D wrom1_rom_base_one_cell_14541/D 0.2411
Xsyn_zero9 wrom1_rom_base_one_cell_15230/D wl_0_22 gnd wrom1_rom_base_zero_cell
Rstrap10 wrom1_rom_base_one_cell_14541/D wrom1_rom_base_one_cell_14435/D 0.2411
Xsyn_zero10 wrom1_rom_base_one_cell_14541/D wl_0_23 gnd wrom1_rom_base_zero_cell
Rstrap11 wrom1_rom_base_one_cell_14435/D wrom1_rom_base_one_cell_14312/D 0.2411
Xsyn_zero11 wrom1_rom_base_one_cell_14435/D wl_0_24 gnd wrom1_rom_base_zero_cell
Rstrap12 wrom1_rom_base_one_cell_14312/D wrom1_rom_base_one_cell_13810/D 0.2411
Xsyn_zero12 wrom1_rom_base_one_cell_14312/D wl_0_28 gnd wrom1_rom_base_zero_cell
Rstrap13 wrom1_rom_base_one_cell_13810/D wrom1_rom_base_one_cell_13542/D 0.2411
Xsyn_zero13 wrom1_rom_base_one_cell_13810/D wl_0_30 gnd wrom1_rom_base_zero_cell
Rstrap14 wrom1_rom_base_one_cell_13542/D wrom1_rom_base_one_cell_13427/D 0.2411
Xsyn_zero14 wrom1_rom_base_one_cell_13542/D wl_0_31 gnd wrom1_rom_base_zero_cell
Rstrap15 wrom1_rom_base_one_cell_13427/D wrom1_rom_base_one_cell_13164/D 0.2411
Xsyn_zero15 wrom1_rom_base_one_cell_13427/D wl_0_33 gnd wrom1_rom_base_zero_cell
Rstrap16 wrom1_rom_base_one_cell_13164/D wrom1_rom_base_one_cell_12203/D 0.2411
Xsyn_zero16 wrom1_rom_base_one_cell_13164/D wl_0_41 gnd wrom1_rom_base_zero_cell
Rstrap17 wrom1_rom_base_one_cell_12203/D wrom1_rom_base_one_cell_11436/D 0.2411
Xsyn_zero17 wrom1_rom_base_one_cell_12203/D wl_0_47 gnd wrom1_rom_base_zero_cell
Rstrap18 wrom1_rom_base_one_cell_11436/D wrom1_rom_base_one_cell_11302/D 0.2411
Xsyn_zero18 wrom1_rom_base_one_cell_11436/D wl_0_48 gnd wrom1_rom_base_zero_cell
Rstrap19 wrom1_rom_base_one_cell_11302/D wrom1_rom_base_zero_cell_9927/S 0.2411
Xsyn_zero19 wrom1_rom_base_one_cell_11302/D wl_0_52 gnd wrom1_rom_base_zero_cell
Rstrap20 wrom1_rom_base_zero_cell_9927/S wrom1_rom_base_one_cell_10393/D 0.2411
Xsyn_zero20 wrom1_rom_base_zero_cell_9927/S wl_0_55 gnd wrom1_rom_base_zero_cell
Rstrap21 wrom1_rom_base_one_cell_10393/D wrom1_rom_base_one_cell_10247/D 0.2411
Xsyn_zero21 wrom1_rom_base_one_cell_10393/D wl_0_56 gnd wrom1_rom_base_zero_cell
Rstrap22 wrom1_rom_base_one_cell_10247/D wrom1_rom_base_one_cell_10137/D 0.2411
Xsyn_zero22 wrom1_rom_base_one_cell_10247/D wl_0_57 gnd wrom1_rom_base_zero_cell
Rstrap23 wrom1_rom_base_one_cell_10137/D wrom1_rom_base_one_cell_9904/S 0.2411
Xsyn_zero23 wrom1_rom_base_one_cell_10137/D wl_0_58 gnd wrom1_rom_base_zero_cell
Rstrap24 wrom1_rom_base_one_cell_9904/S wrom1_rom_base_one_cell_9904/D 0.2411
Xsyn_zero24 wrom1_rom_base_one_cell_9904/S wl_0_59 gnd wrom1_rom_base_zero_cell
Rstrap25 wrom1_rom_base_one_cell_9904/D wrom1_rom_base_one_cell_9793/D 0.2411
Xsyn_zero25 wrom1_rom_base_one_cell_9904/D wl_0_60 gnd wrom1_rom_base_zero_cell
Rstrap26 wrom1_rom_base_one_cell_9793/D wrom1_rom_base_one_cell_9662/D 0.2411
Xsyn_zero26 wrom1_rom_base_one_cell_9793/D wl_0_61 gnd wrom1_rom_base_zero_cell
Rstrap27 wrom1_rom_base_one_cell_9662/D wrom1_rom_base_one_cell_9280/D 0.2411
Xsyn_zero27 wrom1_rom_base_one_cell_9662/D wl_0_64 gnd wrom1_rom_base_zero_cell
Rstrap28 wrom1_rom_base_one_cell_9280/D wrom1_rom_base_one_cell_8766/D 0.2411
Xsyn_zero28 wrom1_rom_base_one_cell_9280/D wl_0_68 gnd wrom1_rom_base_zero_cell
Rstrap29 wrom1_rom_base_one_cell_8766/D wrom1_rom_base_one_cell_8252/D 0.2411
Xsyn_zero29 wrom1_rom_base_one_cell_8766/D wl_0_72 gnd wrom1_rom_base_zero_cell
Rstrap30 wrom1_rom_base_one_cell_8252/D wrom1_rom_base_one_cell_7432/D 0.2411
Xsyn_zero30 wrom1_rom_base_one_cell_8252/D wl_0_78 gnd wrom1_rom_base_zero_cell
Rstrap31 wrom1_rom_base_one_cell_7432/D wrom1_rom_base_one_cell_7164/D 0.2411
Xsyn_zero31 wrom1_rom_base_one_cell_7432/D wl_0_80 gnd wrom1_rom_base_zero_cell
Rstrap32 wrom1_rom_base_one_cell_7164/D wrom1_rom_base_one_cell_6911/D 0.2411
Xsyn_zero32 wrom1_rom_base_one_cell_7164/D wl_0_82 gnd wrom1_rom_base_zero_cell
Rstrap33 wrom1_rom_base_one_cell_6911/D wrom1_rom_base_one_cell_6777/D 0.2411
Xsyn_zero33 wrom1_rom_base_one_cell_6911/D wl_0_83 gnd wrom1_rom_base_zero_cell
Rstrap34 wrom1_rom_base_one_cell_6777/D wrom1_rom_base_one_cell_6646/D 0.2411
Xsyn_zero34 wrom1_rom_base_one_cell_6777/D wl_0_84 gnd wrom1_rom_base_zero_cell
Rstrap35 wrom1_rom_base_one_cell_6646/D wrom1_rom_base_one_cell_6511/D 0.2411
Xsyn_zero35 wrom1_rom_base_one_cell_6646/D wl_0_85 gnd wrom1_rom_base_zero_cell
Rstrap36 wrom1_rom_base_one_cell_6511/D wrom1_rom_base_one_cell_6229/D 0.2411
Xsyn_zero36 wrom1_rom_base_one_cell_6511/D wl_0_87 gnd wrom1_rom_base_zero_cell
Rstrap37 wrom1_rom_base_one_cell_6229/D wrom1_rom_base_one_cell_5464/D 0.2411
Xsyn_zero37 wrom1_rom_base_one_cell_6229/D wl_0_93 gnd wrom1_rom_base_zero_cell
Rstrap38 wrom1_rom_base_one_cell_5464/D wrom1_rom_base_one_cell_5324/D 0.2411
Xsyn_zero38 wrom1_rom_base_one_cell_5464/D wl_0_94 gnd wrom1_rom_base_zero_cell
Rstrap39 wrom1_rom_base_one_cell_5324/D wrom1_rom_base_one_cell_5201/D 0.2411
Xsyn_zero39 wrom1_rom_base_one_cell_5324/D wl_0_95 gnd wrom1_rom_base_zero_cell
Rstrap40 wrom1_rom_base_one_cell_5201/D wrom1_rom_base_one_cell_5058/D 0.2411
Xsyn_zero40 wrom1_rom_base_one_cell_5201/D wl_0_96 gnd wrom1_rom_base_zero_cell
Rstrap41 wrom1_rom_base_one_cell_5058/D wrom1_rom_base_one_cell_4793/D 0.2411
Xsyn_zero41 wrom1_rom_base_one_cell_5058/D wl_0_98 gnd wrom1_rom_base_zero_cell
Rstrap42 wrom1_rom_base_one_cell_4793/D wrom1_rom_base_one_cell_4670/D 0.2411
Xsyn_zero42 wrom1_rom_base_one_cell_4793/D wl_0_99 gnd wrom1_rom_base_zero_cell
Rstrap43 wrom1_rom_base_one_cell_4670/D wrom1_rom_base_one_cell_4417/D 0.2411
Xsyn_zero43 wrom1_rom_base_one_cell_4670/D wl_0_101 gnd wrom1_rom_base_zero_cell
Rstrap44 wrom1_rom_base_one_cell_4417/D wrom1_rom_base_one_cell_2961/D 0.2411
Xsyn_zero44 wrom1_rom_base_one_cell_4417/D wl_0_112 gnd wrom1_rom_base_zero_cell
Rstrap45 wrom1_rom_base_one_cell_2961/D wrom1_rom_base_one_cell_2426/D 0.2411
Xsyn_zero45 wrom1_rom_base_one_cell_2961/D wl_0_116 gnd wrom1_rom_base_zero_cell
Rstrap46 wrom1_rom_base_one_cell_2426/D wrom1_rom_base_zero_cell_958/S 0.2411
Xsyn_zero46 wrom1_rom_base_one_cell_2426/D wl_0_118 gnd wrom1_rom_base_zero_cell
Rstrap47 wrom1_rom_base_zero_cell_958/S wrom1_rom_base_one_cell_889/S 0.2411
Xsyn_zero47 wrom1_rom_base_zero_cell_958/S wl_0_126 gnd wrom1_rom_base_zero_cell
Rstrap48 wrom1_rom_base_one_cell_889/S wrom1_rom_base_one_cell_889/D 0.2411
Xsyn_zero48 wrom1_rom_base_one_cell_889/S wl_0_128 gnd wrom1_rom_base_zero_cell
Rstrap49 wrom1_rom_base_one_cell_889/D wrom1_rom_base_one_cell_609/D 0.2411
Xsyn_zero49 wrom1_rom_base_one_cell_889/D wl_0_130 gnd wrom1_rom_base_zero_cell
Rstrap50 wrom1_rom_base_one_cell_609/D wrom1_rom_base_one_cell_364/D 0.2411
Xsyn_zero50 wrom1_rom_base_one_cell_609/D wl_0_132 gnd wrom1_rom_base_zero_cell
Rw0 wrom1_rom_base_one_cell_364/D wrom1_rom_base_one_cell_364/D_r0 505.3714

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

.ic v(bl_0_50)={VDD}
* THE FIRST CYCLE IS NOT A MEASUREMENT (found 2026-09-20 from a waveform).
* `.ic` sets the bitline only; with `uic` the 1 internal chain nodes start at
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
+                      TARG v(bl_0_50)   VAL='VDD/2' FALL=1 TD='2.5*TCLK'
.measure tran t_dis_10 TRIG v(precharge) VAL='VDD/2' RISE=1 TD='2.5*TCLK'
+                      TARG v(bl_0_50)   VAL='0.1*VDD' FALL=1 TD='2.5*TCLK'
.measure tran t_dis_50_prev TRIG v(precharge) VAL='VDD/2' RISE=1 TD='1.5*TCLK'
+                           TARG v(bl_0_50)   VAL='VDD/2' FALL=1 TD='1.5*TCLK'

* t_pre_50: the bitline crosses the bitline-inverter trip point on the way
* back up -- this is the moment dout0 STOPS being valid after clk0 falls.
* It feeds the falling_edge arc of the .lib (gen_rom_lib.py --t-invalid).
* t_pre_90/t_pre_99 are the recharge-complete times and are much later, so
* they must NOT be used for that arc.
* These sit on the falling edge that ENDS cycle 2, i.e. after two discharges.
.measure tran t_pre_50 TRIG v(precharge) VAL='VDD/2' FALL=1 TD='1.9*TCLK'
+                      TARG v(bl_0_50)   VAL='VDD/2' RISE=1 TD='1.9*TCLK'
.measure tran t_pre_90 TRIG v(precharge) VAL='VDD/2' FALL=1 TD='1.9*TCLK'
+                      TARG v(bl_0_50)   VAL='0.9*VDD' RISE=1 TD='1.9*TCLK'
.measure tran t_pre_99 TRIG v(precharge) VAL='VDD/2' FALL=1 TD='1.9*TCLK'
+                      TARG v(bl_0_50)   VAL='0.99*VDD' RISE=1 TD='1.9*TCLK'

* 200 ps: the step is not a sensitivity here -- 100 ps against 200 ps moves
* t_dis_50 by 0.007% -- and at a 1 us phase it keeps the run under a few
* minutes.
.tran 200p '3*TCLK'
.end
