* wrom1 -- GERCEK PARAZITIK C ile kolon 1 izole olcum
* 63 seri NMOS + 44 olu hucre (graf yuruyusu, isim-bagimsiz)

.lib /home/hpw/OpenLane/pdks/sky130A/libs.tech/ngspice/sky130.lib.spice tt

.param VDD=1.8
.param TCLK=200n

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

Xprechg_pmos bl_0_1 precharge vdd gnd wrom1_precharge_cell
Xbl_inv gnd vdd vdd bl_0_1 bl_b wrom1_pinv_dec_3

Xwrom1_rom_base_one_cell_17486 bl_0_1 wrom1_rom_base_one_cell_17486/D wl_0_0 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_17328 wrom1_rom_base_one_cell_17486/D wrom1_rom_base_one_cell_17328/D wl_0_1 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_16999 wrom1_rom_base_one_cell_17328/D wrom1_rom_base_one_cell_16999/D wl_0_3 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_16821 wrom1_rom_base_one_cell_16999/D wrom1_rom_base_one_cell_16821/D wl_0_4 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_16665 wrom1_rom_base_one_cell_16821/D wrom1_rom_base_one_cell_16665/D wl_0_5 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_16359 wrom1_rom_base_one_cell_16665/D wrom1_rom_base_one_cell_16359/D wl_0_7 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_16190 wrom1_rom_base_one_cell_16359/D wrom1_rom_base_one_cell_16190/D wl_0_8 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_16033 wrom1_rom_base_one_cell_16190/D wrom1_rom_base_one_cell_16033/D wl_0_9 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15870 wrom1_rom_base_one_cell_16033/D wrom1_rom_base_one_cell_15870/D wl_0_10 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15698 wrom1_rom_base_one_cell_15870/D wrom1_rom_base_one_cell_15698/D wl_0_11 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15524 wrom1_rom_base_one_cell_15698/D wrom1_rom_base_one_cell_15524/D wl_0_12 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15012 wrom1_rom_base_one_cell_15524/D wrom1_rom_base_one_cell_15012/D wl_0_15 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_14195 wrom1_rom_base_one_cell_15012/D wrom1_rom_base_one_cell_14195/D wl_0_20 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13734 wrom1_rom_base_one_cell_14195/D wrom1_rom_base_one_cell_13734/D wl_0_23 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13564 wrom1_rom_base_one_cell_13734/D wrom1_rom_base_one_cell_13564/D wl_0_24 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12908 wrom1_rom_base_one_cell_13564/D wrom1_rom_base_one_cell_12908/D wl_0_28 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12780 wrom1_rom_base_one_cell_12908/D wrom1_rom_base_one_cell_12780/D wl_0_29 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12319 wrom1_rom_base_one_cell_12780/D wrom1_rom_base_one_cell_12319/D wl_0_32 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_11551 wrom1_rom_base_one_cell_12319/D wrom1_rom_base_one_cell_11551/D wl_0_37 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_11049 wrom1_rom_base_one_cell_11551/D wrom1_rom_base_zero_cell_9923/S wl_0_40 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_10414 wrom1_rom_base_zero_cell_9923/S wrom1_rom_base_one_cell_10414/D wl_0_44 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_10247 wrom1_rom_base_one_cell_10414/D wrom1_rom_base_one_cell_9649/S wl_0_45 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_9649 wrom1_rom_base_one_cell_9649/S wrom1_rom_base_one_cell_9649/D wl_0_49 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8856 wrom1_rom_base_one_cell_9649/D wrom1_rom_base_one_cell_8856/D wl_0_54 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8686 wrom1_rom_base_one_cell_8856/D wrom1_rom_base_one_cell_8686/D wl_0_55 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8370 wrom1_rom_base_one_cell_8686/D wrom1_rom_base_one_cell_8370/D wl_0_57 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8195 wrom1_rom_base_one_cell_8370/D wrom1_rom_base_one_cell_8195/D wl_0_58 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8020 wrom1_rom_base_one_cell_8195/D wrom1_rom_base_one_cell_8020/D wl_0_59 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_7679 wrom1_rom_base_one_cell_8020/D wrom1_rom_base_one_cell_7679/D wl_0_61 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_7511 wrom1_rom_base_one_cell_7679/D wrom1_rom_base_one_cell_7511/D wl_0_62 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_7354 wrom1_rom_base_one_cell_7511/D wrom1_rom_base_one_cell_7354/D wl_0_63 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_7033 wrom1_rom_base_one_cell_7354/D wrom1_rom_base_one_cell_7033/D wl_0_65 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_6866 wrom1_rom_base_one_cell_7033/D wrom1_rom_base_one_cell_6866/D wl_0_66 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_6694 wrom1_rom_base_one_cell_6866/D wrom1_rom_base_one_cell_6694/D wl_0_67 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_6369 wrom1_rom_base_one_cell_6694/D wrom1_rom_base_one_cell_6369/D wl_0_69 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_6188 wrom1_rom_base_one_cell_6369/D wrom1_rom_base_one_cell_6188/D wl_0_70 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_6045 wrom1_rom_base_one_cell_6188/D wrom1_rom_base_one_cell_6045/D wl_0_71 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_5716 wrom1_rom_base_one_cell_6045/D wrom1_rom_base_one_cell_5716/D wl_0_73 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_5555 wrom1_rom_base_one_cell_5716/D wrom1_rom_base_one_cell_5555/D wl_0_74 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_5381 wrom1_rom_base_one_cell_5555/D wrom1_rom_base_one_cell_5381/D wl_0_75 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_5040 wrom1_rom_base_one_cell_5381/D wrom1_rom_base_one_cell_5040/D wl_0_77 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_4874 wrom1_rom_base_one_cell_5040/D wrom1_rom_base_one_cell_4874/D wl_0_78 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_4403 wrom1_rom_base_one_cell_4874/D wrom1_rom_base_one_cell_4403/D wl_0_81 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_4230 wrom1_rom_base_one_cell_4403/D wrom1_rom_base_one_cell_4230/D wl_0_82 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_4054 wrom1_rom_base_one_cell_4230/D wrom1_rom_base_one_cell_4054/D wl_0_83 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_3753 wrom1_rom_base_one_cell_4054/D wrom1_rom_base_one_cell_3753/D wl_0_85 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_3589 wrom1_rom_base_one_cell_3753/D wrom1_rom_base_one_cell_3589/D wl_0_86 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_3414 wrom1_rom_base_one_cell_3589/D wrom1_rom_base_one_cell_3414/D wl_0_87 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_3082 wrom1_rom_base_one_cell_3414/D wrom1_rom_base_one_cell_3082/D wl_0_89 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_2927 wrom1_rom_base_one_cell_3082/D wrom1_rom_base_one_cell_2927/D wl_0_90 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_2747 wrom1_rom_base_one_cell_2927/D wrom1_rom_base_one_cell_2747/D wl_0_91 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_2413 wrom1_rom_base_one_cell_2747/D wrom1_rom_base_one_cell_2413/D wl_0_93 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_2268 wrom1_rom_base_one_cell_2413/D wrom1_rom_base_one_cell_2268/D wl_0_94 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_2107 wrom1_rom_base_one_cell_2268/D wrom1_rom_base_one_cell_2107/D wl_0_95 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1932 wrom1_rom_base_one_cell_2107/D wrom1_rom_base_one_cell_1932/D wl_0_96 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1795 wrom1_rom_base_one_cell_1932/D wrom1_rom_base_one_cell_1795/D wl_0_97 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1631 wrom1_rom_base_one_cell_1795/D wrom1_rom_base_one_cell_1631/D wl_0_98 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1456 wrom1_rom_base_one_cell_1631/D wrom1_rom_base_one_cell_1456/D wl_0_99 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1301 wrom1_rom_base_one_cell_1456/D wrom1_rom_base_one_cell_1301/D wl_0_100 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1150 wrom1_rom_base_one_cell_1301/D wrom1_rom_base_one_cell_986/S wl_0_101 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_986 wrom1_rom_base_one_cell_986/S wrom1_rom_base_one_cell_986/D wl_0_102 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_810 wrom1_rom_base_one_cell_986/D wrom1_rom_base_one_cell_810/D wl_0_103 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_318 wrom1_rom_base_one_cell_810/D gnd_uq0 precharge gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_zero_cell_16451 wrom1_rom_base_one_cell_17328/D wl_0_2 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_15803 wrom1_rom_base_one_cell_16665/D wl_0_6 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_14732 wrom1_rom_base_one_cell_15524/D wl_0_13 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_14573 wrom1_rom_base_one_cell_15524/D wl_0_14 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_14273 wrom1_rom_base_one_cell_15012/D wl_0_16 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_14121 wrom1_rom_base_one_cell_15012/D wl_0_17 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_13972 wrom1_rom_base_one_cell_15012/D wl_0_18 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_13791 wrom1_rom_base_one_cell_15012/D wl_0_19 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_13323 wrom1_rom_base_one_cell_14195/D wl_0_22 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_13494 wrom1_rom_base_one_cell_14195/D wl_0_21 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_12675 wrom1_rom_base_one_cell_13564/D wl_0_26 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_12825 wrom1_rom_base_one_cell_13564/D wl_0_25 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_12515 wrom1_rom_base_one_cell_13564/D wl_0_27 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_12007 wrom1_rom_base_one_cell_12780/D wl_0_30 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_11835 wrom1_rom_base_one_cell_12780/D wl_0_31 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_11011 wrom1_rom_base_one_cell_12319/D wl_0_36 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_11342 wrom1_rom_base_one_cell_12319/D wl_0_34 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_11168 wrom1_rom_base_one_cell_12319/D wl_0_35 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_11495 wrom1_rom_base_one_cell_12319/D wl_0_33 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_10532 wrom1_rom_base_one_cell_11551/D wl_0_39 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_10699 wrom1_rom_base_one_cell_11551/D wl_0_38 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_9923 wrom1_rom_base_zero_cell_9923/S wl_0_43 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_10220 wrom1_rom_base_zero_cell_9923/S wl_0_41 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_10088 wrom1_rom_base_zero_cell_9923/S wl_0_42 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_9433 wrom1_rom_base_one_cell_9649/S wl_0_46 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_9257 wrom1_rom_base_one_cell_9649/S wl_0_47 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_9068 wrom1_rom_base_one_cell_9649/S wl_0_48 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_8581 wrom1_rom_base_one_cell_9649/D wl_0_51 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_8757 wrom1_rom_base_one_cell_9649/D wl_0_50 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_8425 wrom1_rom_base_one_cell_9649/D wl_0_52 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_8268 wrom1_rom_base_one_cell_9649/D wl_0_53 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_7787 wrom1_rom_base_one_cell_8686/D wl_0_56 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_7188 wrom1_rom_base_one_cell_8020/D wl_0_60 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_6574 wrom1_rom_base_one_cell_7354/D wl_0_64 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_5951 wrom1_rom_base_one_cell_6694/D wl_0_68 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_5324 wrom1_rom_base_one_cell_6045/D wl_0_72 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_4693 wrom1_rom_base_one_cell_5381/D wl_0_76 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_4083 wrom1_rom_base_one_cell_4874/D wl_0_80 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_4235 wrom1_rom_base_one_cell_4874/D wl_0_79 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_3469 wrom1_rom_base_one_cell_4054/D wl_0_84 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_2827 wrom1_rom_base_one_cell_3414/D wl_0_88 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_2218 wrom1_rom_base_one_cell_2747/D wl_0_92 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_163 wrom1_rom_base_one_cell_810/D wl_0_105 gnd wrom1_rom_base_zero_cell
Xwrom1_rom_base_zero_cell_328 wrom1_rom_base_one_cell_810/D wl_0_104 gnd wrom1_rom_base_zero_cell

.subckt wrom1_rom_base_one_cell S D G gnd
X0 D G S gnd sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.108u ps=1.32 w=0.36 l=0.15
C0 G D 0.00394f
C1 G S 0.00394f
C2 D S 0.04533f
C3 S gnd 0.05671f
C4 D gnd 0.09245f
C5 G gnd 0.10004f
.ends
.subckt wrom1_rom_base_zero_cell S G gnd
X0 S G S gnd sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.216u ps=2.64 w=0.36 l=0.15
C0 G S 0.01098f
C1 S gnd 0.169f
C2 G gnd 0.10004f
.ends
.subckt wrom1_precharge_cell D G vdd gnd
X0 D G vdd vdd sky130_fd_pr__pfet_01v8 ad=0.126u pd=1.44 as=0.126u ps=1.44 w=0.42 l=0.15
C0 vdd G 0.05763f
C1 vdd D 0.03592f
C2 D G 0.00394f
C3 D gnd 0.05546f
C4 G gnd 0.03904f
C5 vdd gnd 0.33982f
.ends
.subckt wrom1_pinv_dec_3 gnd vdd w_692_n79# A Z
X0 vdd A Z w_692_n79# sky130_fd_pr__pfet_01v8 ad=1.5u pd=10.6 as=1.5u ps=10.6 w=5 l=0.15
X1 gnd A Z gnd sky130_fd_pr__nfet_01v8 ad=0.504u pd=3.96 as=0.504u ps=3.96 w=1.68 l=0.15
C0 w_692_n79# Z 0.05333f
C1 w_692_n79# vdd 0.02783f
C2 vdd Z 0.06954f
C3 w_692_n79# A 0.10891f
C4 Z A 0.04991f
C5 vdd A 0.01892f
C6 vdd gnd 0.06645f
C7 Z gnd 0.35042f
C8 A gnd 0.23452f
C9 w_692_n79# gnd 1.35078f
.ends

.ic v(bl_0_1)={VDD}
.measure tran t_dis_50 TRIG v(precharge) VAL='VDD/2' RISE=1
+                      TARG v(bl_0_1)   VAL='VDD/2' FALL=1
.measure tran t_dis_10 TRIG v(precharge) VAL='VDD/2' RISE=1
+                      TARG v(bl_0_1)   VAL='0.1*VDD' FALL=1
.measure tran t_pre_90 TRIG v(precharge) VAL='VDD/2' FALL=1
+                      TARG v(bl_0_1)   VAL='0.9*VDD' RISE=1
.measure tran t_pre_99 TRIG v(precharge) VAL='VDD/2' FALL=1
+                      TARG v(bl_0_1)   VAL='0.99*VDD' RISE=1

.tran 100p '2*TCLK'
.end
