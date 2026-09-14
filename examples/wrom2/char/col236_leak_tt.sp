* wrom2 kolon 236 -- IDLE SIZINTI (kolon basina)
* precharge=0: on-sarj fazi, ayak transistoru KAPALI, bitline VDD'de.
* Baskin sizinti yolu: VDD -> prechg PMOS(acik) -> zincir(acik) -> ayak(KAPALI) -> gnd
* Toplam makro sizintisi ~ 264 x (bu deger) + cevre birimi.
.lib /home/hpw/OpenLane/pdks/sky130A/libs.tech/ngspice/sky130.lib.spice tt
.temp 25
.param VDD=1.8

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

* wrom2 -- GERCEK PARAZITIK C ile kolon 236 izole olcum
* 91 seri NMOS + 43 olu hucre (graf yuruyusu, isim-bagimsiz)
Xprechg_pmos bl_0_236 precharge vdd gnd wrom2_precharge_cell
Xbl_inv gnd vdd vdd bl_0_236 bl_b wrom2_pinv_dec_3
Xwrom2_rom_base_one_cell_17154 bl_0_236 wrom2_rom_base_one_cell_17154/D wl_0_0 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_17028 wrom2_rom_base_one_cell_17154/D wrom2_rom_base_one_cell_17028/D wl_0_1 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_16778 wrom2_rom_base_one_cell_17028/D wrom2_rom_base_one_cell_16778/D wl_0_3 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_16647 wrom2_rom_base_one_cell_16778/D wrom2_rom_base_one_cell_16647/D wl_0_4 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_16531 wrom2_rom_base_one_cell_16647/D wrom2_rom_base_one_cell_16531/D wl_0_5 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_16415 wrom2_rom_base_one_cell_16531/D wrom2_rom_base_one_cell_16415/D wl_0_6 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_16282 wrom2_rom_base_one_cell_16415/D wrom2_rom_base_one_cell_16282/D wl_0_7 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_15918 wrom2_rom_base_one_cell_16282/D wrom2_rom_base_one_cell_15918/D wl_0_10 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_15655 wrom2_rom_base_one_cell_15918/D wrom2_rom_base_one_cell_15655/D wl_0_12 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_15516 wrom2_rom_base_one_cell_15655/D wrom2_rom_base_one_cell_15516/D wl_0_13 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_15123 wrom2_rom_base_one_cell_15516/D wrom2_rom_base_one_cell_15123/D wl_0_16 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_14994 wrom2_rom_base_one_cell_15123/D wrom2_rom_base_one_cell_14994/D wl_0_17 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_14588 wrom2_rom_base_one_cell_14994/D wrom2_rom_base_one_cell_14588/D wl_0_20 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_14460 wrom2_rom_base_one_cell_14588/D wrom2_rom_base_one_cell_14460/D wl_0_21 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_14346 wrom2_rom_base_one_cell_14460/D wrom2_rom_base_one_cell_14346/D wl_0_22 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_13943 wrom2_rom_base_one_cell_14346/D wrom2_rom_base_one_cell_13943/D wl_0_25 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_13816 wrom2_rom_base_one_cell_13943/D wrom2_rom_base_one_cell_13816/D wl_0_26 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_13271 wrom2_rom_base_one_cell_13816/D wrom2_rom_base_one_cell_13271/D wl_0_30 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_13137 wrom2_rom_base_one_cell_13271/D wrom2_rom_base_one_cell_13137/D wl_0_31 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_12913 wrom2_rom_base_one_cell_13137/D wrom2_rom_base_one_cell_12913/D wl_0_33 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_12661 wrom2_rom_base_one_cell_12913/D wrom2_rom_base_one_cell_12661/D wl_0_35 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_12543 wrom2_rom_base_one_cell_12661/D wrom2_rom_base_one_cell_12543/D wl_0_36 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_12405 wrom2_rom_base_one_cell_12543/D wrom2_rom_base_one_cell_12405/D wl_0_37 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_12175 wrom2_rom_base_one_cell_12405/D wrom2_rom_base_one_cell_12175/D wl_0_39 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_12064 wrom2_rom_base_one_cell_12175/D wrom2_rom_base_one_cell_12064/D wl_0_40 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_11925 wrom2_rom_base_one_cell_12064/D wrom2_rom_base_one_cell_11925/D wl_0_41 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_11805 wrom2_rom_base_one_cell_11925/D wrom2_rom_base_one_cell_11805/D wl_0_42 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_11684 wrom2_rom_base_one_cell_11805/D wrom2_rom_base_one_cell_11684/D wl_0_43 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_11545 wrom2_rom_base_one_cell_11684/D wrom2_rom_base_one_cell_11545/D wl_0_44 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_11294 wrom2_rom_base_one_cell_11545/D wrom2_rom_base_one_cell_11294/D wl_0_46 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_11017 wrom2_rom_base_one_cell_11294/D wrom2_rom_base_one_cell_11017/D wl_0_48 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_10893 wrom2_rom_base_one_cell_11017/D wrom2_rom_base_one_cell_10893/D wl_0_49 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_10764 wrom2_rom_base_one_cell_10893/D wrom2_rom_base_one_cell_10764/D wl_0_50 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_10633 wrom2_rom_base_one_cell_10764/D wrom2_rom_base_one_cell_10633/D wl_0_51 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_10499 wrom2_rom_base_one_cell_10633/D wrom2_rom_base_one_cell_10499/D wl_0_52 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_10375 wrom2_rom_base_one_cell_10499/D wrom2_rom_base_one_cell_10375/D wl_0_53 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_10248 wrom2_rom_base_one_cell_10375/D wrom2_rom_base_one_cell_10248/D wl_0_54 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_10132 wrom2_rom_base_one_cell_10248/D wrom2_rom_base_one_cell_9892/S wl_0_55 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_9892 wrom2_rom_base_one_cell_9892/S wrom2_rom_base_one_cell_9892/D wl_0_57 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_9769 wrom2_rom_base_one_cell_9892/D wrom2_rom_base_one_cell_9769/D wl_0_58 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_9492 wrom2_rom_base_one_cell_9769/D wrom2_rom_base_one_cell_9492/D wl_0_60 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_9274 wrom2_rom_base_one_cell_9492/D wrom2_rom_base_one_cell_9274/D wl_0_62 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_9156 wrom2_rom_base_one_cell_9274/D wrom2_rom_base_one_cell_9156/D wl_0_63 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_9023 wrom2_rom_base_one_cell_9156/D wrom2_rom_base_one_cell_9023/D wl_0_64 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_8904 wrom2_rom_base_one_cell_9023/D wrom2_rom_base_one_cell_8904/D wl_0_65 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_8780 wrom2_rom_base_one_cell_8904/D wrom2_rom_base_one_cell_8780/D wl_0_66 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_8651 wrom2_rom_base_one_cell_8780/D wrom2_rom_base_one_cell_8651/D wl_0_67 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_8525 wrom2_rom_base_one_cell_8651/D wrom2_rom_base_one_cell_8525/D wl_0_68 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_8406 wrom2_rom_base_one_cell_8525/D wrom2_rom_base_one_cell_8406/D wl_0_69 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_8264 wrom2_rom_base_one_cell_8406/D wrom2_rom_base_one_cell_8264/D wl_0_70 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_7615 wrom2_rom_base_one_cell_8264/D wrom2_rom_base_one_cell_7615/D wl_0_75 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_7490 wrom2_rom_base_one_cell_7615/D wrom2_rom_base_one_cell_7490/D wl_0_76 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_7350 wrom2_rom_base_one_cell_7490/D wrom2_rom_base_one_cell_7350/D wl_0_77 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_7095 wrom2_rom_base_one_cell_7350/D wrom2_rom_base_one_cell_7095/D wl_0_79 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_6952 wrom2_rom_base_one_cell_7095/D wrom2_rom_base_one_cell_6952/D wl_0_80 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_6828 wrom2_rom_base_one_cell_6952/D wrom2_rom_base_one_cell_6828/D wl_0_81 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_6681 wrom2_rom_base_one_cell_6828/D wrom2_rom_base_one_cell_6681/D wl_0_82 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_6559 wrom2_rom_base_one_cell_6681/D wrom2_rom_base_one_cell_6559/D wl_0_83 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_6434 wrom2_rom_base_one_cell_6559/D wrom2_rom_base_one_cell_6434/D wl_0_84 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_6296 wrom2_rom_base_one_cell_6434/D wrom2_rom_base_one_cell_6296/D wl_0_85 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_6036 wrom2_rom_base_one_cell_6296/D wrom2_rom_base_one_cell_6036/D wl_0_87 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_5908 wrom2_rom_base_one_cell_6036/D wrom2_rom_base_one_cell_5908/D wl_0_88 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_5780 wrom2_rom_base_one_cell_5908/D wrom2_rom_base_one_cell_5780/D wl_0_89 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_5267 wrom2_rom_base_one_cell_5780/D wrom2_rom_base_one_cell_5267/D wl_0_93 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_5157 wrom2_rom_base_one_cell_5267/D wrom2_rom_base_one_cell_5157/D wl_0_94 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_4904 wrom2_rom_base_one_cell_5157/D wrom2_rom_base_one_cell_4904/D wl_0_96 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_4634 wrom2_rom_base_one_cell_4904/D wrom2_rom_base_one_cell_4634/D wl_0_98 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_4492 wrom2_rom_base_one_cell_4634/D wrom2_rom_base_one_cell_4492/D wl_0_99 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_4103 wrom2_rom_base_one_cell_4492/D wrom2_rom_base_one_cell_4103/D wl_0_102 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_3984 wrom2_rom_base_one_cell_4103/D wrom2_rom_base_one_cell_3984/D wl_0_103 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_3592 wrom2_rom_base_one_cell_3984/D wrom2_rom_base_one_cell_3592/D wl_0_106 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_3449 wrom2_rom_base_one_cell_3592/D wrom2_rom_base_one_cell_3449/D wl_0_107 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_3198 wrom2_rom_base_one_cell_3449/D wrom2_rom_base_one_cell_3198/D wl_0_109 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_3057 wrom2_rom_base_one_cell_3198/D wrom2_rom_base_one_cell_3057/D wl_0_110 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_2933 wrom2_rom_base_one_cell_3057/D wrom2_rom_base_one_cell_2933/D wl_0_111 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_2805 wrom2_rom_base_one_cell_2933/D wrom2_rom_base_one_cell_2805/D wl_0_112 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_2437 wrom2_rom_base_one_cell_2805/D wrom2_rom_base_one_cell_2437/D wl_0_115 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_2296 wrom2_rom_base_one_cell_2437/D wrom2_rom_base_one_cell_2296/D wl_0_116 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_2155 wrom2_rom_base_one_cell_2296/D wrom2_rom_base_one_cell_2155/D wl_0_117 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_2027 wrom2_rom_base_one_cell_2155/D wrom2_rom_base_one_cell_2027/D wl_0_118 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_1915 wrom2_rom_base_one_cell_2027/D wrom2_rom_base_one_cell_1915/D wl_0_119 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_1804 wrom2_rom_base_one_cell_1915/D wrom2_rom_base_one_cell_1804/D wl_0_120 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_1554 wrom2_rom_base_one_cell_1804/D wrom2_rom_base_zero_cell_898/S wl_0_122 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_1035 wrom2_rom_base_zero_cell_898/S wrom2_rom_base_one_cell_924/S wl_0_126 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_924 wrom2_rom_base_one_cell_924/S wrom2_rom_base_one_cell_924/D wl_0_127 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_785 wrom2_rom_base_one_cell_924/D wrom2_rom_base_one_cell_785/D wl_0_128 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_656 wrom2_rom_base_one_cell_785/D wrom2_rom_base_one_cell_656/D wl_0_129 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_534 wrom2_rom_base_one_cell_656/D wrom2_rom_base_one_cell_534/D wl_0_130 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_405 wrom2_rom_base_one_cell_534/D wrom2_rom_base_one_cell_405/D wl_0_131 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_268 wrom2_rom_base_one_cell_405/D wrom2_rom_base_one_cell_19/S wl_0_132 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_19 wrom2_rom_base_one_cell_19/S gnd_uq0 precharge gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_zero_cell_16651 wrom2_rom_base_one_cell_17028/D wl_0_2 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_15837 wrom2_rom_base_one_cell_16282/D wl_0_8 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_15718 wrom2_rom_base_one_cell_16282/D wl_0_9 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_15459 wrom2_rom_base_one_cell_15918/D wl_0_11 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_15095 wrom2_rom_base_one_cell_15516/D wl_0_14 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_14973 wrom2_rom_base_one_cell_15516/D wl_0_15 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_14583 wrom2_rom_base_one_cell_14994/D wl_0_18 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_14457 wrom2_rom_base_one_cell_14994/D wl_0_19 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_13849 wrom2_rom_base_one_cell_14346/D wl_0_24 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_13977 wrom2_rom_base_one_cell_14346/D wl_0_23 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_13357 wrom2_rom_base_one_cell_13816/D wl_0_28 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_13468 wrom2_rom_base_one_cell_13816/D wl_0_27 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_13227 wrom2_rom_base_one_cell_13816/D wl_0_29 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_12847 wrom2_rom_base_one_cell_13137/D wl_0_32 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_12576 wrom2_rom_base_one_cell_12913/D wl_0_34 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_12046 wrom2_rom_base_one_cell_12405/D wl_0_38 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_11138 wrom2_rom_base_one_cell_11545/D wl_0_45 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_10885 wrom2_rom_base_one_cell_11294/D wl_0_47 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_9707 wrom2_rom_base_one_cell_9892/S wl_0_56 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_9348 wrom2_rom_base_one_cell_9769/D wl_0_59 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_9072 wrom2_rom_base_one_cell_9492/D wl_0_61 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_7631 wrom2_rom_base_one_cell_8264/D wl_0_72 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_7499 wrom2_rom_base_one_cell_8264/D wl_0_73 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_7756 wrom2_rom_base_one_cell_8264/D wl_0_71 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_7395 wrom2_rom_base_one_cell_8264/D wl_0_74 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_6864 wrom2_rom_base_one_cell_7350/D wl_0_78 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_5883 wrom2_rom_base_one_cell_6296/D wl_0_86 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_5375 wrom2_rom_base_one_cell_5780/D wl_0_90 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_5125 wrom2_rom_base_one_cell_5780/D wl_0_92 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_5261 wrom2_rom_base_one_cell_5780/D wl_0_91 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_4720 wrom2_rom_base_one_cell_5157/D wl_0_95 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_4470 wrom2_rom_base_one_cell_4904/D wl_0_97 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_3972 wrom2_rom_base_one_cell_4492/D wl_0_101 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_4109 wrom2_rom_base_one_cell_4492/D wl_0_100 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_3588 wrom2_rom_base_one_cell_3984/D wl_0_104 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_3469 wrom2_rom_base_one_cell_3984/D wl_0_105 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_3102 wrom2_rom_base_one_cell_3449/D wl_0_108 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_2320 wrom2_rom_base_one_cell_2805/D wl_0_114 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_2450 wrom2_rom_base_one_cell_2805/D wl_0_113 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_1407 wrom2_rom_base_one_cell_1804/D wl_0_121 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_898 wrom2_rom_base_zero_cell_898/S wl_0_125 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_1022 wrom2_rom_base_zero_cell_898/S wl_0_124 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_1153 wrom2_rom_base_zero_cell_898/S wl_0_123 gnd wrom2_rom_base_zero_cell
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

* gmin: ngspice'in yakinsama icin HER DUGUME ekledigi yapay iletkenlik.
* Cok buyuk secilirse sizinti olcumune KARISIR. 2026-09-05 taramasi:
*   gmin=1e-12 -> 0.656 nA   (%79 yapay!)
*   gmin=1e-15 -> 0.366 nA
*   gmin=1e-18 -> 0.366 nA   (ayni -> yakinsadi)
* 1e-15 yeterli ve guvenli.
.options gmin=1e-15 abstol=1e-15 reltol=1e-3 itl1=500
* .op KULLANILIYOR (transient DEGIL): "uic"li transient'te tum dugumler
* 0'dan baslayip 85 transistorluk direncli zincirden yavasca doluyor;
* 600 ns'de bile oturmuyordu (65->19->8.7 nA hala azaliyordu) ve sarj
* akimi sizinti sanilarak ~100x YUKSEK olculuyordu. .op bu kolonda
* (136 cihaz) yakinsiyor -- tam makroda (34k) yakinsamiyordu.
* Sonuc log'da "vvdd#branch" satirindan okunur (.measure op ngspice'te
* sayisal cikti uretmiyor).
.op
.end
