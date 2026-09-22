* wrom3 column 10 -- IDLE LEAKAGE (per column)
* precharge=0: precharge phase, foot transistor OFF, bitline at VDD.
* Dominant leakage path: VDD -> prechg PMOS(on) -> chain(on) -> foot(OFF) -> gnd
* Whole-macro leakage ~ 256 x (this value) + periphery.
.lib /home/hpw/OpenLane/pdks/sky130A/libs.tech/ngspice/sky130.lib.spice ff
.temp -40
.param VDD=1.95

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
Vprecharge precharge 0 DC 0

* wrom3 -- isolated measurement of column 10 with REAL PARASITIC C
* 77 series NMOS + 57 dead cells (graph walk, name independent)
* wire resistance: 505.4 ohm per cell (77 x = 38.9 kohm)
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
Xprechg_pmos bl_0_10 precharge vdd gnd wrom3_precharge_cell
Xbl_inv gnd vdd vdd bl_0_10 bl_b wrom3_pinv_dec_3
Xwrom3_rom_base_one_cell_15730 bl_0_10_r wrom3_rom_base_one_cell_15730/D wl_0_1 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_15604 wrom3_rom_base_one_cell_15730/D_r1 wrom3_rom_base_one_cell_15604/D wl_0_2 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_15488 wrom3_rom_base_one_cell_15604/D_r2 wrom3_rom_base_one_cell_15488/D wl_0_3 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_15083 wrom3_rom_base_one_cell_15488/D_r3 wrom3_rom_base_one_cell_15083/D wl_0_6 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_14841 wrom3_rom_base_one_cell_15083/D_r4 wrom3_rom_base_one_cell_14841/D wl_0_8 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_14435 wrom3_rom_base_one_cell_14841/D_r5 wrom3_rom_base_one_cell_14435/D wl_0_11 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_14182 wrom3_rom_base_one_cell_14435/D_r6 wrom3_rom_base_one_cell_14182/D wl_0_13 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_14037 wrom3_rom_base_one_cell_14182/D_r7 wrom3_rom_base_one_cell_14037/D wl_0_14 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_13925 wrom3_rom_base_one_cell_14037/D_r8 wrom3_rom_base_one_cell_13925/D wl_0_15 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_13362 wrom3_rom_base_one_cell_13925/D_r9 wrom3_rom_base_one_cell_13362/D wl_0_19 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_12837 wrom3_rom_base_one_cell_13362/D_r10 wrom3_rom_base_one_cell_12837/D wl_0_23 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_12721 wrom3_rom_base_one_cell_12837/D_r11 wrom3_rom_base_one_cell_12721/D wl_0_24 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_12108 wrom3_rom_base_one_cell_12721/D_r12 wrom3_rom_base_one_cell_12108/D wl_0_32 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_11975 wrom3_rom_base_one_cell_12108/D_r13 wrom3_rom_base_one_cell_11975/D wl_0_33 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_11595 wrom3_rom_base_one_cell_11975/D_r14 wrom3_rom_base_one_cell_11595/D wl_0_36 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_11467 wrom3_rom_base_one_cell_11595/D_r15 wrom3_rom_base_one_cell_11467/D wl_0_37 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_10959 wrom3_rom_base_one_cell_11467/D_r16 wrom3_rom_base_one_cell_10959/D wl_0_41 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_10813 wrom3_rom_base_one_cell_10959/D_r17 wrom3_rom_base_one_cell_10813/D wl_0_42 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_10689 wrom3_rom_base_one_cell_10813/D_r18 wrom3_rom_base_one_cell_10689/D wl_0_43 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_10303 wrom3_rom_base_one_cell_10689/D_r19 wrom3_rom_base_one_cell_10303/D wl_0_46 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_10178 wrom3_rom_base_one_cell_10303/D_r20 wrom3_rom_base_one_cell_10178/D wl_0_47 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_10047 wrom3_rom_base_one_cell_10178/D_r21 wrom3_rom_base_one_cell_9684/S wl_0_48 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_9684 wrom3_rom_base_one_cell_9684/S_r22 wrom3_rom_base_one_cell_9684/D wl_0_51 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_9557 wrom3_rom_base_one_cell_9684/D_r23 wrom3_rom_base_one_cell_9557/D wl_0_52 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_9201 wrom3_rom_base_one_cell_9557/D_r24 wrom3_rom_base_one_cell_9201/D wl_0_55 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_9070 wrom3_rom_base_one_cell_9201/D_r25 wrom3_rom_base_one_cell_9070/D wl_0_56 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_8935 wrom3_rom_base_one_cell_9070/D_r26 wrom3_rom_base_one_cell_8935/D wl_0_57 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_8694 wrom3_rom_base_one_cell_8935/D_r27 wrom3_rom_base_one_cell_8694/D wl_0_59 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_8417 wrom3_rom_base_one_cell_8694/D_r28 wrom3_rom_base_one_cell_8417/D wl_0_64 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_8290 wrom3_rom_base_one_cell_8417/D_r29 wrom3_rom_base_one_cell_8290/D wl_0_65 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_8028 wrom3_rom_base_one_cell_8290/D_r30 wrom3_rom_base_one_cell_8028/D wl_0_67 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7892 wrom3_rom_base_one_cell_8028/D_r31 wrom3_rom_base_one_cell_7892/D wl_0_68 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7628 wrom3_rom_base_one_cell_7892/D_r32 wrom3_rom_base_one_cell_7628/D wl_0_70 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7384 wrom3_rom_base_one_cell_7628/D_r33 wrom3_rom_base_one_cell_7384/D wl_0_72 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7257 wrom3_rom_base_one_cell_7384/D_r34 wrom3_rom_base_one_cell_7257/D wl_0_73 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7132 wrom3_rom_base_one_cell_7257/D_r35 wrom3_rom_base_one_cell_7132/D wl_0_74 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7000 wrom3_rom_base_one_cell_7132/D_r36 wrom3_rom_base_one_cell_7000/D wl_0_75 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6739 wrom3_rom_base_one_cell_7000/D_r37 wrom3_rom_base_one_cell_6739/D wl_0_77 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6603 wrom3_rom_base_one_cell_6739/D_r38 wrom3_rom_base_one_cell_6603/D wl_0_78 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6480 wrom3_rom_base_one_cell_6603/D_r39 wrom3_rom_base_one_cell_6480/D wl_0_79 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6356 wrom3_rom_base_one_cell_6480/D_r40 wrom3_rom_base_one_cell_6356/D wl_0_80 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6240 wrom3_rom_base_one_cell_6356/D_r41 wrom3_rom_base_one_cell_6240/D wl_0_81 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6123 wrom3_rom_base_one_cell_6240/D_r42 wrom3_rom_base_one_cell_6123/D wl_0_82 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_5987 wrom3_rom_base_one_cell_6123/D_r43 wrom3_rom_base_one_cell_5987/D wl_0_83 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_5850 wrom3_rom_base_one_cell_5987/D_r44 wrom3_rom_base_one_cell_5850/D wl_0_84 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_5603 wrom3_rom_base_one_cell_5850/D_r45 wrom3_rom_base_one_cell_5603/D wl_0_86 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_5487 wrom3_rom_base_one_cell_5603/D_r46 wrom3_rom_base_one_cell_5487/D wl_0_87 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_5363 wrom3_rom_base_one_cell_5487/D_r47 wrom3_rom_base_one_cell_5363/D wl_0_88 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_5230 wrom3_rom_base_one_cell_5363/D_r48 wrom3_rom_base_one_cell_5230/D wl_0_89 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_4963 wrom3_rom_base_one_cell_5230/D_r49 wrom3_rom_base_one_cell_4963/D wl_0_91 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_4839 wrom3_rom_base_one_cell_4963/D_r50 wrom3_rom_base_one_cell_4839/D wl_0_92 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_4719 wrom3_rom_base_one_cell_4839/D_r51 wrom3_rom_base_one_cell_4719/D wl_0_96 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_4590 wrom3_rom_base_one_cell_4719/D_r52 wrom3_rom_base_one_cell_4590/D wl_0_97 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_4444 wrom3_rom_base_one_cell_4590/D_r53 wrom3_rom_base_one_cell_4444/D wl_0_98 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_4176 wrom3_rom_base_one_cell_4444/D_r54 wrom3_rom_base_one_cell_4176/D wl_0_100 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_3925 wrom3_rom_base_one_cell_4176/D_r55 wrom3_rom_base_one_cell_3925/D wl_0_102 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_3548 wrom3_rom_base_one_cell_3925/D_r56 wrom3_rom_base_one_cell_3548/D wl_0_105 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_3279 wrom3_rom_base_one_cell_3548/D_r57 wrom3_rom_base_one_cell_3279/D wl_0_107 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_3144 wrom3_rom_base_one_cell_3279/D_r58 wrom3_rom_base_one_cell_3144/D wl_0_108 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2900 wrom3_rom_base_one_cell_3144/D_r59 wrom3_rom_base_one_cell_2900/D wl_0_110 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2757 wrom3_rom_base_one_cell_2900/D_r60 wrom3_rom_base_one_cell_2757/D wl_0_111 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2617 wrom3_rom_base_one_cell_2757/D_r61 wrom3_rom_base_one_cell_2617/D wl_0_112 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2469 wrom3_rom_base_one_cell_2617/D_r62 wrom3_rom_base_one_cell_2469/D wl_0_113 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2206 wrom3_rom_base_one_cell_2469/D_r63 wrom3_rom_base_one_cell_2206/D wl_0_115 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2084 wrom3_rom_base_one_cell_2206/D_r64 wrom3_rom_base_one_cell_2084/D wl_0_116 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1961 wrom3_rom_base_one_cell_2084/D_r65 wrom3_rom_base_one_cell_1961/D wl_0_117 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1833 wrom3_rom_base_one_cell_1961/D_r66 wrom3_rom_base_one_cell_1833/D wl_0_118 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1697 wrom3_rom_base_one_cell_1833/D_r67 wrom3_rom_base_one_cell_1697/D wl_0_119 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1565 wrom3_rom_base_one_cell_1697/D_r68 wrom3_rom_base_one_cell_1565/D wl_0_120 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1322 wrom3_rom_base_one_cell_1565/D_r69 wrom3_rom_base_one_cell_1322/D wl_0_122 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1192 wrom3_rom_base_one_cell_1322/D_r70 wrom3_rom_base_one_cell_925/S wl_0_123 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_925 wrom3_rom_base_one_cell_925/S_r71 wrom3_rom_base_one_cell_925/D wl_0_128 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_772 wrom3_rom_base_one_cell_925/D_r72 wrom3_rom_base_one_cell_772/D wl_0_129 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_643 wrom3_rom_base_one_cell_772/D_r73 wrom3_rom_base_one_cell_643/D wl_0_130 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_510 wrom3_rom_base_one_cell_643/D_r74 wrom3_rom_base_one_cell_510/D wl_0_131 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_364 wrom3_rom_base_one_cell_510/D_r75 wrom3_rom_base_one_cell_364/D wl_0_132 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_245 wrom3_rom_base_one_cell_364/D_r76 gnd_uq0 precharge gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_zero_cell_18418 bl_0_10 wl_0_0 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_17909 wrom3_rom_base_one_cell_15488/D wl_0_4 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_17777 wrom3_rom_base_one_cell_15488/D wl_0_5 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_17530 wrom3_rom_base_one_cell_15083/D wl_0_7 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_17174 wrom3_rom_base_one_cell_14841/D wl_0_10 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_17301 wrom3_rom_base_one_cell_14841/D wl_0_9 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_16912 wrom3_rom_base_one_cell_14435/D wl_0_12 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_16282 wrom3_rom_base_one_cell_13925/D wl_0_17 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_16402 wrom3_rom_base_one_cell_13925/D wl_0_16 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_16164 wrom3_rom_base_one_cell_13925/D wl_0_18 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_15693 wrom3_rom_base_one_cell_13362/D wl_0_22 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_15824 wrom3_rom_base_one_cell_13362/D wl_0_21 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_15950 wrom3_rom_base_one_cell_13362/D wl_0_20 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_15038 wrom3_rom_base_one_cell_12721/D wl_0_27 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_15180 wrom3_rom_base_one_cell_12721/D wl_0_26 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_14498 wrom3_rom_base_one_cell_12721/D wl_0_30 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_15316 wrom3_rom_base_one_cell_12721/D wl_0_25 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_14242 wrom3_rom_base_one_cell_12721/D wl_0_31 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_14754 wrom3_rom_base_one_cell_12721/D wl_0_29 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_14904 wrom3_rom_base_one_cell_12721/D wl_0_28 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_13623 wrom3_rom_base_one_cell_11975/D wl_0_35 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_13741 wrom3_rom_base_one_cell_11975/D wl_0_34 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_13231 wrom3_rom_base_one_cell_11467/D wl_0_38 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_13089 wrom3_rom_base_one_cell_11467/D wl_0_39 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_12951 wrom3_rom_base_one_cell_11467/D wl_0_40 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_12331 wrom3_rom_base_one_cell_10689/D wl_0_45 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_12475 wrom3_rom_base_one_cell_10689/D wl_0_44 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_11683 wrom3_rom_base_one_cell_9684/S wl_0_50 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_11802 wrom3_rom_base_one_cell_9684/S wl_0_49 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_11152 wrom3_rom_base_one_cell_9557/D wl_0_54 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_11301 wrom3_rom_base_one_cell_9557/D wl_0_53 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_10636 wrom3_rom_base_one_cell_8935/D wl_0_58 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_10254 wrom3_rom_base_one_cell_8694/D wl_0_61 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_10366 wrom3_rom_base_one_cell_8694/D wl_0_60 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_9998 wrom3_rom_base_one_cell_8694/D wl_0_62 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_9742 wrom3_rom_base_one_cell_8694/D wl_0_63 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_9240 wrom3_rom_base_one_cell_8290/D wl_0_66 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_8866 wrom3_rom_base_one_cell_7892/D wl_0_69 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_8613 wrom3_rom_base_one_cell_7628/D wl_0_71 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_7970 wrom3_rom_base_one_cell_7000/D wl_0_76 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_6809 wrom3_rom_base_one_cell_5850/D wl_0_85 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_6154 wrom3_rom_base_one_cell_5230/D wl_0_90 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_5246 wrom3_rom_base_one_cell_4839/D wl_0_95 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_5758 wrom3_rom_base_one_cell_4839/D wl_0_93 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_5502 wrom3_rom_base_one_cell_4839/D wl_0_94 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_4638 wrom3_rom_base_one_cell_4444/D wl_0_99 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_4382 wrom3_rom_base_one_cell_4176/D wl_0_101 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_3982 wrom3_rom_base_one_cell_3925/D wl_0_104 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_4118 wrom3_rom_base_one_cell_3925/D wl_0_103 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_3752 wrom3_rom_base_one_cell_3548/D wl_0_106 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_3371 wrom3_rom_base_one_cell_3144/D wl_0_109 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_2777 wrom3_rom_base_one_cell_2469/D wl_0_114 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_1863 wrom3_rom_base_one_cell_1565/D wl_0_121 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_1357 wrom3_rom_base_one_cell_925/S wl_0_125 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_1101 wrom3_rom_base_one_cell_925/S wl_0_126 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_845 wrom3_rom_base_one_cell_925/S wl_0_127 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_1479 wrom3_rom_base_one_cell_925/S wl_0_124 gnd wrom3_rom_base_zero_cell
Rw0 bl_0_10 bl_0_10_r 505.3714
Rw1 wrom3_rom_base_one_cell_15730/D wrom3_rom_base_one_cell_15730/D_r1 505.3714
Rw2 wrom3_rom_base_one_cell_15604/D wrom3_rom_base_one_cell_15604/D_r2 505.3714
Rw3 wrom3_rom_base_one_cell_15488/D wrom3_rom_base_one_cell_15488/D_r3 505.3714
Rw4 wrom3_rom_base_one_cell_15083/D wrom3_rom_base_one_cell_15083/D_r4 505.3714
Rw5 wrom3_rom_base_one_cell_14841/D wrom3_rom_base_one_cell_14841/D_r5 505.3714
Rw6 wrom3_rom_base_one_cell_14435/D wrom3_rom_base_one_cell_14435/D_r6 505.3714
Rw7 wrom3_rom_base_one_cell_14182/D wrom3_rom_base_one_cell_14182/D_r7 505.3714
Rw8 wrom3_rom_base_one_cell_14037/D wrom3_rom_base_one_cell_14037/D_r8 505.3714
Rw9 wrom3_rom_base_one_cell_13925/D wrom3_rom_base_one_cell_13925/D_r9 505.3714
Rw10 wrom3_rom_base_one_cell_13362/D wrom3_rom_base_one_cell_13362/D_r10 505.3714
Rw11 wrom3_rom_base_one_cell_12837/D wrom3_rom_base_one_cell_12837/D_r11 505.3714
Rw12 wrom3_rom_base_one_cell_12721/D wrom3_rom_base_one_cell_12721/D_r12 505.3714
Rw13 wrom3_rom_base_one_cell_12108/D wrom3_rom_base_one_cell_12108/D_r13 505.3714
Rw14 wrom3_rom_base_one_cell_11975/D wrom3_rom_base_one_cell_11975/D_r14 505.3714
Rw15 wrom3_rom_base_one_cell_11595/D wrom3_rom_base_one_cell_11595/D_r15 505.3714
Rw16 wrom3_rom_base_one_cell_11467/D wrom3_rom_base_one_cell_11467/D_r16 505.3714
Rw17 wrom3_rom_base_one_cell_10959/D wrom3_rom_base_one_cell_10959/D_r17 505.3714
Rw18 wrom3_rom_base_one_cell_10813/D wrom3_rom_base_one_cell_10813/D_r18 505.3714
Rw19 wrom3_rom_base_one_cell_10689/D wrom3_rom_base_one_cell_10689/D_r19 505.3714
Rw20 wrom3_rom_base_one_cell_10303/D wrom3_rom_base_one_cell_10303/D_r20 505.3714
Rw21 wrom3_rom_base_one_cell_10178/D wrom3_rom_base_one_cell_10178/D_r21 505.3714
Rw22 wrom3_rom_base_one_cell_9684/S wrom3_rom_base_one_cell_9684/S_r22 505.3714
Rw23 wrom3_rom_base_one_cell_9684/D wrom3_rom_base_one_cell_9684/D_r23 505.3714
Rw24 wrom3_rom_base_one_cell_9557/D wrom3_rom_base_one_cell_9557/D_r24 505.3714
Rw25 wrom3_rom_base_one_cell_9201/D wrom3_rom_base_one_cell_9201/D_r25 505.3714
Rw26 wrom3_rom_base_one_cell_9070/D wrom3_rom_base_one_cell_9070/D_r26 505.3714
Rw27 wrom3_rom_base_one_cell_8935/D wrom3_rom_base_one_cell_8935/D_r27 505.3714
Rw28 wrom3_rom_base_one_cell_8694/D wrom3_rom_base_one_cell_8694/D_r28 505.3714
Rw29 wrom3_rom_base_one_cell_8417/D wrom3_rom_base_one_cell_8417/D_r29 505.3714
Rw30 wrom3_rom_base_one_cell_8290/D wrom3_rom_base_one_cell_8290/D_r30 505.3714
Rw31 wrom3_rom_base_one_cell_8028/D wrom3_rom_base_one_cell_8028/D_r31 505.3714
Rw32 wrom3_rom_base_one_cell_7892/D wrom3_rom_base_one_cell_7892/D_r32 505.3714
Rw33 wrom3_rom_base_one_cell_7628/D wrom3_rom_base_one_cell_7628/D_r33 505.3714
Rw34 wrom3_rom_base_one_cell_7384/D wrom3_rom_base_one_cell_7384/D_r34 505.3714
Rw35 wrom3_rom_base_one_cell_7257/D wrom3_rom_base_one_cell_7257/D_r35 505.3714
Rw36 wrom3_rom_base_one_cell_7132/D wrom3_rom_base_one_cell_7132/D_r36 505.3714
Rw37 wrom3_rom_base_one_cell_7000/D wrom3_rom_base_one_cell_7000/D_r37 505.3714
Rw38 wrom3_rom_base_one_cell_6739/D wrom3_rom_base_one_cell_6739/D_r38 505.3714
Rw39 wrom3_rom_base_one_cell_6603/D wrom3_rom_base_one_cell_6603/D_r39 505.3714
Rw40 wrom3_rom_base_one_cell_6480/D wrom3_rom_base_one_cell_6480/D_r40 505.3714
Rw41 wrom3_rom_base_one_cell_6356/D wrom3_rom_base_one_cell_6356/D_r41 505.3714
Rw42 wrom3_rom_base_one_cell_6240/D wrom3_rom_base_one_cell_6240/D_r42 505.3714
Rw43 wrom3_rom_base_one_cell_6123/D wrom3_rom_base_one_cell_6123/D_r43 505.3714
Rw44 wrom3_rom_base_one_cell_5987/D wrom3_rom_base_one_cell_5987/D_r44 505.3714
Rw45 wrom3_rom_base_one_cell_5850/D wrom3_rom_base_one_cell_5850/D_r45 505.3714
Rw46 wrom3_rom_base_one_cell_5603/D wrom3_rom_base_one_cell_5603/D_r46 505.3714
Rw47 wrom3_rom_base_one_cell_5487/D wrom3_rom_base_one_cell_5487/D_r47 505.3714
Rw48 wrom3_rom_base_one_cell_5363/D wrom3_rom_base_one_cell_5363/D_r48 505.3714
Rw49 wrom3_rom_base_one_cell_5230/D wrom3_rom_base_one_cell_5230/D_r49 505.3714
Rw50 wrom3_rom_base_one_cell_4963/D wrom3_rom_base_one_cell_4963/D_r50 505.3714
Rw51 wrom3_rom_base_one_cell_4839/D wrom3_rom_base_one_cell_4839/D_r51 505.3714
Rw52 wrom3_rom_base_one_cell_4719/D wrom3_rom_base_one_cell_4719/D_r52 505.3714
Rw53 wrom3_rom_base_one_cell_4590/D wrom3_rom_base_one_cell_4590/D_r53 505.3714
Rw54 wrom3_rom_base_one_cell_4444/D wrom3_rom_base_one_cell_4444/D_r54 505.3714
Rw55 wrom3_rom_base_one_cell_4176/D wrom3_rom_base_one_cell_4176/D_r55 505.3714
Rw56 wrom3_rom_base_one_cell_3925/D wrom3_rom_base_one_cell_3925/D_r56 505.3714
Rw57 wrom3_rom_base_one_cell_3548/D wrom3_rom_base_one_cell_3548/D_r57 505.3714
Rw58 wrom3_rom_base_one_cell_3279/D wrom3_rom_base_one_cell_3279/D_r58 505.3714
Rw59 wrom3_rom_base_one_cell_3144/D wrom3_rom_base_one_cell_3144/D_r59 505.3714
Rw60 wrom3_rom_base_one_cell_2900/D wrom3_rom_base_one_cell_2900/D_r60 505.3714
Rw61 wrom3_rom_base_one_cell_2757/D wrom3_rom_base_one_cell_2757/D_r61 505.3714
Rw62 wrom3_rom_base_one_cell_2617/D wrom3_rom_base_one_cell_2617/D_r62 505.3714
Rw63 wrom3_rom_base_one_cell_2469/D wrom3_rom_base_one_cell_2469/D_r63 505.3714
Rw64 wrom3_rom_base_one_cell_2206/D wrom3_rom_base_one_cell_2206/D_r64 505.3714
Rw65 wrom3_rom_base_one_cell_2084/D wrom3_rom_base_one_cell_2084/D_r65 505.3714
Rw66 wrom3_rom_base_one_cell_1961/D wrom3_rom_base_one_cell_1961/D_r66 505.3714
Rw67 wrom3_rom_base_one_cell_1833/D wrom3_rom_base_one_cell_1833/D_r67 505.3714
Rw68 wrom3_rom_base_one_cell_1697/D wrom3_rom_base_one_cell_1697/D_r68 505.3714
Rw69 wrom3_rom_base_one_cell_1565/D wrom3_rom_base_one_cell_1565/D_r69 505.3714
Rw70 wrom3_rom_base_one_cell_1322/D wrom3_rom_base_one_cell_1322/D_r70 505.3714
Rw71 wrom3_rom_base_one_cell_925/S wrom3_rom_base_one_cell_925/S_r71 505.3714
Rw72 wrom3_rom_base_one_cell_925/D wrom3_rom_base_one_cell_925/D_r72 505.3714
Rw73 wrom3_rom_base_one_cell_772/D wrom3_rom_base_one_cell_772/D_r73 505.3714
Rw74 wrom3_rom_base_one_cell_643/D wrom3_rom_base_one_cell_643/D_r74 505.3714
Rw75 wrom3_rom_base_one_cell_510/D wrom3_rom_base_one_cell_510/D_r75 505.3714
Rw76 wrom3_rom_base_one_cell_364/D wrom3_rom_base_one_cell_364/D_r76 505.3714
.subckt wrom3_rom_base_one_cell S D G gnd
X0 D G S gnd sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.108u ps=1.32 w=0.36 l=0.15
C0 D G 0.00394f
C1 S G 0.00394f
C2 S D 0.04533f
C3 S gnd 0.05671f
C4 D gnd 0.09245f
C5 G gnd 0.10004f
.ends
.subckt wrom3_rom_base_zero_cell S G gnd
X0 S G S gnd sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.216u ps=2.64 w=0.36 l=0.15
C0 S G 0.01098f
C1 S gnd 0.169f
C2 G gnd 0.10004f
.ends
.subckt wrom3_precharge_cell D G vdd gnd
X0 D G vdd vdd sky130_fd_pr__pfet_01v8 ad=0.126u pd=1.44 as=0.126u ps=1.44 w=0.42 l=0.15
C0 G vdd 0.05763f
C1 D vdd 0.03592f
C2 D G 0.00394f
C3 D gnd 0.05546f
C4 G gnd 0.03904f
C5 vdd gnd 0.33982f
.ends
.subckt wrom3_pinv_dec_3 gnd vdd w_692_n79# A Z
X0 vdd A Z w_692_n79# sky130_fd_pr__pfet_01v8 ad=1.5u pd=10.6 as=1.5u ps=10.6 w=5 l=0.15
X1 gnd A Z gnd sky130_fd_pr__nfet_01v8 ad=0.504u pd=3.96 as=0.504u ps=3.96 w=1.68 l=0.15
C0 Z vdd 0.06954f
C1 A w_692_n79# 0.10891f
C2 w_692_n79# Z 0.05333f
C3 A Z 0.04991f
C4 w_692_n79# vdd 0.02783f
C5 A vdd 0.01892f
C6 vdd gnd 0.06645f
C7 Z gnd 0.35042f
C8 A gnd 0.23452f
C9 w_692_n79# gnd 1.35078f
.ends
* THE FIRST CYCLE IS NOT A MEASUREMENT (found 2026-09-20 from a waveform).
* `.ic` sets the bitline only; with `uic` the 77 internal chain nodes start at
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

* gmin: the artificial conductance ngspice adds to EVERY node to converge.
* Set too high it CONTAMINATES the leakage measurement. Sweep of 2026-09-05:
*   gmin=1e-12 -> 0.656 nA   (79% artificial!)
*   gmin=1e-15 -> 0.366 nA
*   gmin=1e-18 -> 0.366 nA   (same -> converged)
* 1e-15 is sufficient and safe.
.options gmin=1e-15 abstol=1e-15 reltol=1e-3 itl1=500
* .op IS USED (NOT a transient): in a transient with "uic" every node starts
* at 0 and charges slowly through a resistive chain of dozens of transistors;
* even at 600 ns it had not settled (65 -> 19 -> 8.7 nA, still falling) and the
* charging current was mistaken for leakage, ~100x too high. .op converges on
* this column (136 devices) where it did not on the full macro (34k).
* The result is read from the "vvdd#branch" line of the log (`.measure op`
* produces no numeric output in ngspice).
.op
.end
