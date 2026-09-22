* wrom2 -- isolated measurement of column 79 with REAL PARASITIC C
* 1 series NMOS + 88 dead cells (graph walk, name independent)
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

Xprechg_pmos bl_0_79 precharge vdd gnd wrom2_precharge_cell
Xbl_inv gnd vdd vdd bl_0_79 bl_b wrom2_pinv_dec_3

Xwrom2_rom_base_one_cell_176 wrom2_rom_base_zero_cell_80/S_r0 gnd_uq0 precharge gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_zero_cell_16860 bl_0_79 wl_0_1 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_16994 bl_0_79 wl_0_0 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_16335 wrom2_rom_base_one_cell_16725/D wl_0_5 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_16198 wrom2_rom_base_one_cell_16725/D wl_0_6 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_15940 wrom2_rom_base_one_cell_16361/D wl_0_8 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_15541 wrom2_rom_base_one_cell_15993/D wl_0_11 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_14923 wrom2_rom_base_one_cell_15340/D wl_0_16 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_14675 wrom2_rom_base_one_cell_15070/D wl_0_18 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_14310 wrom2_rom_base_one_cell_14683/D wl_0_21 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_13678 wrom2_rom_base_one_cell_14018/D wl_0_26 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_13188 wrom2_rom_base_one_cell_13618/D wl_0_30 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_12934 wrom2_rom_base_one_cell_13618/D wl_0_32 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_13062 wrom2_rom_base_one_cell_13618/D wl_0_31 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_13310 wrom2_rom_base_one_cell_13618/D wl_0_29 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_12522 wrom2_rom_base_one_cell_12978/D wl_0_35 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_12398 wrom2_rom_base_one_cell_12978/D wl_0_36 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_12660 wrom2_rom_base_one_cell_12978/D wl_0_34 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_11989 wrom2_rom_base_one_cell_12505/D wl_0_39 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_11714 wrom2_rom_base_one_cell_12505/D wl_0_41 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_11845 wrom2_rom_base_one_cell_12505/D wl_0_40 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_12132 wrom2_rom_base_one_cell_12505/D wl_0_38 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_11328 wrom2_rom_base_one_cell_11888/D wl_0_44 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_11082 wrom2_rom_base_one_cell_11888/D wl_0_46 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_11210 wrom2_rom_base_one_cell_11888/D wl_0_45 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_11449 wrom2_rom_base_one_cell_11888/D wl_0_43 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_10709 wrom2_rom_base_one_cell_11102/D wl_0_49 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_10445 wrom2_rom_base_one_cell_11102/D wl_0_51 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_10567 wrom2_rom_base_one_cell_11102/D wl_0_50 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_9789 wrom2_rom_base_one_cell_9976/S wl_0_56 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_9938 wrom2_rom_base_one_cell_9976/S wl_0_55 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_10070 wrom2_rom_base_one_cell_9976/S wl_0_54 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_10207 wrom2_rom_base_one_cell_9976/S wl_0_53 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_9409 wrom2_rom_base_one_cell_9976/D wl_0_59 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_9530 wrom2_rom_base_one_cell_9976/D wl_0_58 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_9165 wrom2_rom_base_one_cell_9976/D wl_0_61 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_9286 wrom2_rom_base_one_cell_9976/D wl_0_60 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_8866 wrom2_rom_base_one_cell_9336/D wl_0_63 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_8476 wrom2_rom_base_one_cell_9336/D wl_0_66 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_8617 wrom2_rom_base_one_cell_9336/D wl_0_65 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_8735 wrom2_rom_base_one_cell_9336/D wl_0_64 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_7838 wrom2_rom_base_one_cell_8733/D wl_0_71 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_7954 wrom2_rom_base_one_cell_8733/D wl_0_70 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_8076 wrom2_rom_base_one_cell_8733/D wl_0_69 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_8206 wrom2_rom_base_one_cell_8733/D wl_0_68 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_7576 wrom2_rom_base_one_cell_8085/D wl_0_73 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_6955 wrom2_rom_base_one_cell_7818/D wl_0_78 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_7200 wrom2_rom_base_one_cell_7818/D wl_0_76 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_7076 wrom2_rom_base_one_cell_7818/D wl_0_77 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_7342 wrom2_rom_base_one_cell_7818/D wl_0_75 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_6592 wrom2_rom_base_one_cell_7185/D wl_0_81 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_6709 wrom2_rom_base_one_cell_7185/D wl_0_80 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_6338 wrom2_rom_base_one_cell_6776/D wl_0_83 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_5705 wrom2_rom_base_one_cell_6511/D wl_0_88 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_4801 wrom2_rom_base_one_cell_6511/D wl_0_95 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_5327 wrom2_rom_base_one_cell_6511/D wl_0_91 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_5833 wrom2_rom_base_one_cell_6511/D wl_0_87 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_4417 wrom2_rom_base_one_cell_6511/D wl_0_98 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_5460 wrom2_rom_base_one_cell_6511/D wl_0_90 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_4931 wrom2_rom_base_one_cell_6511/D wl_0_94 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_5073 wrom2_rom_base_one_cell_6511/D wl_0_93 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_4543 wrom2_rom_base_one_cell_6511/D wl_0_97 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_5962 wrom2_rom_base_one_cell_6511/D wl_0_86 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_5217 wrom2_rom_base_one_cell_6511/D wl_0_92 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_5582 wrom2_rom_base_one_cell_6511/D wl_0_89 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_6092 wrom2_rom_base_one_cell_6511/D wl_0_85 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_4660 wrom2_rom_base_one_cell_6511/D wl_0_96 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_3794 wrom2_rom_base_one_cell_4320/D wl_0_103 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_3926 wrom2_rom_base_one_cell_4320/D wl_0_102 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_3549 wrom2_rom_base_one_cell_4320/D wl_0_105 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_3655 wrom2_rom_base_one_cell_4320/D wl_0_104 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_3046 wrom2_rom_base_one_cell_3674/D wl_0_109 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_3166 wrom2_rom_base_one_cell_3674/D wl_0_108 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_3292 wrom2_rom_base_one_cell_3674/D wl_0_107 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_2529 wrom2_rom_base_one_cell_3013/D wl_0_113 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_2665 wrom2_rom_base_one_cell_3013/D wl_0_112 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_2271 wrom2_rom_base_one_cell_3013/D wl_0_115 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_2400 wrom2_rom_base_one_cell_3013/D wl_0_114 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_1775 wrom2_rom_base_one_cell_2384/D wl_0_119 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_1904 wrom2_rom_base_one_cell_2384/D wl_0_118 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_2029 wrom2_rom_base_one_cell_2384/D wl_0_117 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_1222 wrom2_rom_base_one_cell_1754/D wl_0_123 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_1097 wrom2_rom_base_one_cell_1754/D wl_0_124 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_1367 wrom2_rom_base_one_cell_1754/D wl_0_122 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_582 wrom2_rom_base_one_cell_736/S wl_0_128 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_724 wrom2_rom_base_one_cell_736/S wl_0_127 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_80 wrom2_rom_base_zero_cell_80/S wl_0_132 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_200 wrom2_rom_base_zero_cell_80/S wl_0_131 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_331 wrom2_rom_base_zero_cell_80/S wl_0_130 gnd wrom2_rom_base_zero_cell
Rstrap0 bl_0_79 wrom2_rom_base_one_cell_16979/D 0.2411
Xsyn_zero0 bl_0_79 wl_0_2 gnd wrom2_rom_base_zero_cell
Rstrap1 wrom2_rom_base_one_cell_16979/D wrom2_rom_base_one_cell_16848/D 0.2411
Xsyn_zero1 wrom2_rom_base_one_cell_16979/D wl_0_3 gnd wrom2_rom_base_zero_cell
Rstrap2 wrom2_rom_base_one_cell_16848/D wrom2_rom_base_one_cell_16725/D 0.2411
Xsyn_zero2 wrom2_rom_base_one_cell_16848/D wl_0_4 gnd wrom2_rom_base_zero_cell
Rstrap3 wrom2_rom_base_one_cell_16725/D wrom2_rom_base_one_cell_16361/D 0.2411
Xsyn_zero3 wrom2_rom_base_one_cell_16725/D wl_0_7 gnd wrom2_rom_base_zero_cell
Rstrap4 wrom2_rom_base_one_cell_16361/D wrom2_rom_base_one_cell_16122/D 0.2411
Xsyn_zero4 wrom2_rom_base_one_cell_16361/D wl_0_9 gnd wrom2_rom_base_zero_cell
Rstrap5 wrom2_rom_base_one_cell_16122/D wrom2_rom_base_one_cell_15993/D 0.2411
Xsyn_zero5 wrom2_rom_base_one_cell_16122/D wl_0_10 gnd wrom2_rom_base_zero_cell
Rstrap6 wrom2_rom_base_one_cell_15993/D wrom2_rom_base_one_cell_15731/D 0.2411
Xsyn_zero6 wrom2_rom_base_one_cell_15993/D wl_0_12 gnd wrom2_rom_base_zero_cell
Rstrap7 wrom2_rom_base_one_cell_15731/D wrom2_rom_base_one_cell_15597/D 0.2411
Xsyn_zero7 wrom2_rom_base_one_cell_15731/D wl_0_13 gnd wrom2_rom_base_zero_cell
Rstrap8 wrom2_rom_base_one_cell_15597/D wrom2_rom_base_one_cell_15455/D 0.2411
Xsyn_zero8 wrom2_rom_base_one_cell_15597/D wl_0_14 gnd wrom2_rom_base_zero_cell
Rstrap9 wrom2_rom_base_one_cell_15455/D wrom2_rom_base_one_cell_15340/D 0.2411
Xsyn_zero9 wrom2_rom_base_one_cell_15455/D wl_0_15 gnd wrom2_rom_base_zero_cell
Rstrap10 wrom2_rom_base_one_cell_15340/D wrom2_rom_base_one_cell_15070/D 0.2411
Xsyn_zero10 wrom2_rom_base_one_cell_15340/D wl_0_17 gnd wrom2_rom_base_zero_cell
Rstrap11 wrom2_rom_base_one_cell_15070/D wrom2_rom_base_one_cell_14815/D 0.2411
Xsyn_zero11 wrom2_rom_base_one_cell_15070/D wl_0_19 gnd wrom2_rom_base_zero_cell
Rstrap12 wrom2_rom_base_one_cell_14815/D wrom2_rom_base_one_cell_14683/D 0.2411
Xsyn_zero12 wrom2_rom_base_one_cell_14815/D wl_0_20 gnd wrom2_rom_base_zero_cell
Rstrap13 wrom2_rom_base_one_cell_14683/D wrom2_rom_base_one_cell_14409/D 0.2411
Xsyn_zero13 wrom2_rom_base_one_cell_14683/D wl_0_22 gnd wrom2_rom_base_zero_cell
Rstrap14 wrom2_rom_base_one_cell_14409/D wrom2_rom_base_one_cell_14285/D 0.2411
Xsyn_zero14 wrom2_rom_base_one_cell_14409/D wl_0_23 gnd wrom2_rom_base_zero_cell
Rstrap15 wrom2_rom_base_one_cell_14285/D wrom2_rom_base_one_cell_14145/D 0.2411
Xsyn_zero15 wrom2_rom_base_one_cell_14285/D wl_0_24 gnd wrom2_rom_base_zero_cell
Rstrap16 wrom2_rom_base_one_cell_14145/D wrom2_rom_base_one_cell_14018/D 0.2411
Xsyn_zero16 wrom2_rom_base_one_cell_14145/D wl_0_25 gnd wrom2_rom_base_zero_cell
Rstrap17 wrom2_rom_base_one_cell_14018/D wrom2_rom_base_one_cell_13762/D 0.2411
Xsyn_zero17 wrom2_rom_base_one_cell_14018/D wl_0_27 gnd wrom2_rom_base_zero_cell
Rstrap18 wrom2_rom_base_one_cell_13762/D wrom2_rom_base_one_cell_13618/D 0.2411
Xsyn_zero18 wrom2_rom_base_one_cell_13762/D wl_0_28 gnd wrom2_rom_base_zero_cell
Rstrap19 wrom2_rom_base_one_cell_13618/D wrom2_rom_base_one_cell_12978/D 0.2411
Xsyn_zero19 wrom2_rom_base_one_cell_13618/D wl_0_33 gnd wrom2_rom_base_zero_cell
Rstrap20 wrom2_rom_base_one_cell_12978/D wrom2_rom_base_one_cell_12505/D 0.2411
Xsyn_zero20 wrom2_rom_base_one_cell_12978/D wl_0_37 gnd wrom2_rom_base_zero_cell
Rstrap21 wrom2_rom_base_one_cell_12505/D wrom2_rom_base_one_cell_11888/D 0.2411
Xsyn_zero21 wrom2_rom_base_one_cell_12505/D wl_0_42 gnd wrom2_rom_base_zero_cell
Rstrap22 wrom2_rom_base_one_cell_11888/D wrom2_rom_base_one_cell_11238/D 0.2411
Xsyn_zero22 wrom2_rom_base_one_cell_11888/D wl_0_47 gnd wrom2_rom_base_zero_cell
Rstrap23 wrom2_rom_base_one_cell_11238/D wrom2_rom_base_one_cell_11102/D 0.2411
Xsyn_zero23 wrom2_rom_base_one_cell_11238/D wl_0_48 gnd wrom2_rom_base_zero_cell
Rstrap24 wrom2_rom_base_one_cell_11102/D wrom2_rom_base_one_cell_9976/S 0.2411
Xsyn_zero24 wrom2_rom_base_one_cell_11102/D wl_0_52 gnd wrom2_rom_base_zero_cell
Rstrap25 wrom2_rom_base_one_cell_9976/S wrom2_rom_base_one_cell_9976/D 0.2411
Xsyn_zero25 wrom2_rom_base_one_cell_9976/S wl_0_57 gnd wrom2_rom_base_zero_cell
Rstrap26 wrom2_rom_base_one_cell_9976/D wrom2_rom_base_one_cell_9336/D 0.2411
Xsyn_zero26 wrom2_rom_base_one_cell_9976/D wl_0_62 gnd wrom2_rom_base_zero_cell
Rstrap27 wrom2_rom_base_one_cell_9336/D wrom2_rom_base_one_cell_8733/D 0.2411
Xsyn_zero27 wrom2_rom_base_one_cell_9336/D wl_0_67 gnd wrom2_rom_base_zero_cell
Rstrap28 wrom2_rom_base_one_cell_8733/D wrom2_rom_base_one_cell_8085/D 0.2411
Xsyn_zero28 wrom2_rom_base_one_cell_8733/D wl_0_72 gnd wrom2_rom_base_zero_cell
Rstrap29 wrom2_rom_base_one_cell_8085/D wrom2_rom_base_one_cell_7818/D 0.2411
Xsyn_zero29 wrom2_rom_base_one_cell_8085/D wl_0_74 gnd wrom2_rom_base_zero_cell
Rstrap30 wrom2_rom_base_one_cell_7818/D wrom2_rom_base_one_cell_7185/D 0.2411
Xsyn_zero30 wrom2_rom_base_one_cell_7818/D wl_0_79 gnd wrom2_rom_base_zero_cell
Rstrap31 wrom2_rom_base_one_cell_7185/D wrom2_rom_base_one_cell_6776/D 0.2411
Xsyn_zero31 wrom2_rom_base_one_cell_7185/D wl_0_82 gnd wrom2_rom_base_zero_cell
Rstrap32 wrom2_rom_base_one_cell_6776/D wrom2_rom_base_one_cell_6511/D 0.2411
Xsyn_zero32 wrom2_rom_base_one_cell_6776/D wl_0_84 gnd wrom2_rom_base_zero_cell
Rstrap33 wrom2_rom_base_one_cell_6511/D wrom2_rom_base_one_cell_4586/D 0.2411
Xsyn_zero33 wrom2_rom_base_one_cell_6511/D wl_0_99 gnd wrom2_rom_base_zero_cell
Rstrap34 wrom2_rom_base_one_cell_4586/D wrom2_rom_base_one_cell_4443/D 0.2411
Xsyn_zero34 wrom2_rom_base_one_cell_4586/D wl_0_100 gnd wrom2_rom_base_zero_cell
Rstrap35 wrom2_rom_base_one_cell_4443/D wrom2_rom_base_one_cell_4320/D 0.2411
Xsyn_zero35 wrom2_rom_base_one_cell_4443/D wl_0_101 gnd wrom2_rom_base_zero_cell
Rstrap36 wrom2_rom_base_one_cell_4320/D wrom2_rom_base_one_cell_3674/D 0.2411
Xsyn_zero36 wrom2_rom_base_one_cell_4320/D wl_0_106 gnd wrom2_rom_base_zero_cell
Rstrap37 wrom2_rom_base_one_cell_3674/D wrom2_rom_base_one_cell_3137/D 0.2411
Xsyn_zero37 wrom2_rom_base_one_cell_3674/D wl_0_110 gnd wrom2_rom_base_zero_cell
Rstrap38 wrom2_rom_base_one_cell_3137/D wrom2_rom_base_one_cell_3013/D 0.2411
Xsyn_zero38 wrom2_rom_base_one_cell_3137/D wl_0_111 gnd wrom2_rom_base_zero_cell
Rstrap39 wrom2_rom_base_one_cell_3013/D wrom2_rom_base_one_cell_2384/D 0.2411
Xsyn_zero39 wrom2_rom_base_one_cell_3013/D wl_0_116 gnd wrom2_rom_base_zero_cell
Rstrap40 wrom2_rom_base_one_cell_2384/D wrom2_rom_base_one_cell_1869/D 0.2411
Xsyn_zero40 wrom2_rom_base_one_cell_2384/D wl_0_120 gnd wrom2_rom_base_zero_cell
Rstrap41 wrom2_rom_base_one_cell_1869/D wrom2_rom_base_one_cell_1754/D 0.2411
Xsyn_zero41 wrom2_rom_base_one_cell_1869/D wl_0_121 gnd wrom2_rom_base_zero_cell
Rstrap42 wrom2_rom_base_one_cell_1754/D wrom2_rom_base_one_cell_1250/D 0.2411
Xsyn_zero42 wrom2_rom_base_one_cell_1754/D wl_0_125 gnd wrom2_rom_base_zero_cell
Rstrap43 wrom2_rom_base_one_cell_1250/D wrom2_rom_base_one_cell_736/S 0.2411
Xsyn_zero43 wrom2_rom_base_one_cell_1250/D wl_0_126 gnd wrom2_rom_base_zero_cell
Rstrap44 wrom2_rom_base_one_cell_736/S wrom2_rom_base_zero_cell_80/S 0.2411
Xsyn_zero44 wrom2_rom_base_one_cell_736/S wl_0_129 gnd wrom2_rom_base_zero_cell
Rw0 wrom2_rom_base_zero_cell_80/S wrom2_rom_base_zero_cell_80/S_r0 505.3714

.subckt wrom2_rom_base_one_cell S D G gnd
X0 D G S gnd sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.108u ps=1.32 w=0.36 l=0.15
C0 D G 0.00394f
C1 S G 0.00394f
C2 D S 0.04533f
C3 S gnd 0.05671f
C4 D gnd 0.09245f
C5 G gnd 0.10004f
.ends
.subckt wrom2_rom_base_zero_cell S G gnd
X0 S G S gnd sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.216u ps=2.64 w=0.36 l=0.15
C0 S G 0.01098f
C1 S gnd 0.169f
C2 G gnd 0.10004f
.ends
.subckt wrom2_precharge_cell D G vdd gnd
X0 D G vdd vdd sky130_fd_pr__pfet_01v8 ad=0.126u pd=1.44 as=0.126u ps=1.44 w=0.42 l=0.15
C0 G vdd 0.05763f
C1 D vdd 0.03592f
C2 G D 0.00394f
C3 D gnd 0.05546f
C4 G gnd 0.03904f
C5 vdd gnd 0.33982f
.ends
.subckt wrom2_pinv_dec_3 gnd vdd w_692_n79# A Z
X0 vdd A Z w_692_n79# sky130_fd_pr__pfet_01v8 ad=1.5u pd=10.6 as=1.5u ps=10.6 w=5 l=0.15
X1 gnd A Z gnd sky130_fd_pr__nfet_01v8 ad=0.504u pd=3.96 as=0.504u ps=3.96 w=1.68 l=0.15
C0 w_692_n79# A 0.10891f
C1 Z w_692_n79# 0.05333f
C2 Z A 0.04991f
C3 vdd w_692_n79# 0.02783f
C4 vdd A 0.01892f
C5 vdd Z 0.06954f
C6 vdd gnd 0.06645f
C7 Z gnd 0.35042f
C8 A gnd 0.23452f
C9 w_692_n79# gnd 1.35078f
.ends

.ic v(bl_0_79)={VDD}
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
+                      TARG v(bl_0_79)   VAL='VDD/2' FALL=1 TD='2.5*TCLK'
.measure tran t_dis_10 TRIG v(precharge) VAL='VDD/2' RISE=1 TD='2.5*TCLK'
+                      TARG v(bl_0_79)   VAL='0.1*VDD' FALL=1 TD='2.5*TCLK'
.measure tran t_dis_50_prev TRIG v(precharge) VAL='VDD/2' RISE=1 TD='1.5*TCLK'
+                           TARG v(bl_0_79)   VAL='VDD/2' FALL=1 TD='1.5*TCLK'

* t_pre_50: the bitline crosses the bitline-inverter trip point on the way
* back up -- this is the moment dout0 STOPS being valid after clk0 falls.
* It feeds the falling_edge arc of the .lib (gen_rom_lib.py --t-invalid).
* t_pre_90/t_pre_99 are the recharge-complete times and are much later, so
* they must NOT be used for that arc.
* These sit on the falling edge that ENDS cycle 2, i.e. after two discharges.
.measure tran t_pre_50 TRIG v(precharge) VAL='VDD/2' FALL=1 TD='1.9*TCLK'
+                      TARG v(bl_0_79)   VAL='VDD/2' RISE=1 TD='1.9*TCLK'
.measure tran t_pre_90 TRIG v(precharge) VAL='VDD/2' FALL=1 TD='1.9*TCLK'
+                      TARG v(bl_0_79)   VAL='0.9*VDD' RISE=1 TD='1.9*TCLK'
.measure tran t_pre_99 TRIG v(precharge) VAL='VDD/2' FALL=1 TD='1.9*TCLK'
+                      TARG v(bl_0_79)   VAL='0.99*VDD' RISE=1 TD='1.9*TCLK'

* 200 ps: the step is not a sensitivity here -- 100 ps against 200 ps moves
* t_dis_50 by 0.007% -- and at a 1 us phase it keeps the run under a few
* minutes.
.tran 200p '3*TCLK'
.end
