* wrom3 kolon 10 -- IDLE SIZINTI (kolon basina)
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

* wrom3 -- GERCEK PARAZITIK C ile kolon 10 izole olcum
* 77 seri NMOS + 57 olu hucre (graf yuruyusu, isim-bagimsiz)
Xprechg_pmos bl_0_10 precharge vdd gnd wrom3_precharge_cell
Xbl_inv gnd vdd vdd bl_0_10 bl_b wrom3_pinv_dec_3
Xwrom3_rom_base_one_cell_15730 bl_0_10 wrom3_rom_base_one_cell_15730/D wl_0_1 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_15604 wrom3_rom_base_one_cell_15730/D wrom3_rom_base_one_cell_15604/D wl_0_2 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_15488 wrom3_rom_base_one_cell_15604/D wrom3_rom_base_one_cell_15488/D wl_0_3 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_15083 wrom3_rom_base_one_cell_15488/D wrom3_rom_base_one_cell_15083/D wl_0_6 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_14841 wrom3_rom_base_one_cell_15083/D wrom3_rom_base_one_cell_14841/D wl_0_8 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_14435 wrom3_rom_base_one_cell_14841/D wrom3_rom_base_one_cell_14435/D wl_0_11 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_14182 wrom3_rom_base_one_cell_14435/D wrom3_rom_base_one_cell_14182/D wl_0_13 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_14037 wrom3_rom_base_one_cell_14182/D wrom3_rom_base_one_cell_14037/D wl_0_14 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_13925 wrom3_rom_base_one_cell_14037/D wrom3_rom_base_one_cell_13925/D wl_0_15 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_13362 wrom3_rom_base_one_cell_13925/D wrom3_rom_base_one_cell_13362/D wl_0_19 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_12837 wrom3_rom_base_one_cell_13362/D wrom3_rom_base_one_cell_12837/D wl_0_23 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_12721 wrom3_rom_base_one_cell_12837/D wrom3_rom_base_one_cell_12721/D wl_0_24 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_12108 wrom3_rom_base_one_cell_12721/D wrom3_rom_base_one_cell_12108/D wl_0_32 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_11975 wrom3_rom_base_one_cell_12108/D wrom3_rom_base_one_cell_11975/D wl_0_33 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_11595 wrom3_rom_base_one_cell_11975/D wrom3_rom_base_one_cell_11595/D wl_0_36 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_11467 wrom3_rom_base_one_cell_11595/D wrom3_rom_base_one_cell_11467/D wl_0_37 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_10959 wrom3_rom_base_one_cell_11467/D wrom3_rom_base_one_cell_10959/D wl_0_41 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_10813 wrom3_rom_base_one_cell_10959/D wrom3_rom_base_one_cell_10813/D wl_0_42 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_10689 wrom3_rom_base_one_cell_10813/D wrom3_rom_base_one_cell_10689/D wl_0_43 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_10303 wrom3_rom_base_one_cell_10689/D wrom3_rom_base_one_cell_10303/D wl_0_46 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_10178 wrom3_rom_base_one_cell_10303/D wrom3_rom_base_one_cell_10178/D wl_0_47 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_10047 wrom3_rom_base_one_cell_10178/D wrom3_rom_base_one_cell_9684/S wl_0_48 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_9684 wrom3_rom_base_one_cell_9684/S wrom3_rom_base_one_cell_9684/D wl_0_51 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_9557 wrom3_rom_base_one_cell_9684/D wrom3_rom_base_one_cell_9557/D wl_0_52 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_9201 wrom3_rom_base_one_cell_9557/D wrom3_rom_base_one_cell_9201/D wl_0_55 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_9070 wrom3_rom_base_one_cell_9201/D wrom3_rom_base_one_cell_9070/D wl_0_56 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_8935 wrom3_rom_base_one_cell_9070/D wrom3_rom_base_one_cell_8935/D wl_0_57 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_8694 wrom3_rom_base_one_cell_8935/D wrom3_rom_base_one_cell_8694/D wl_0_59 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_8417 wrom3_rom_base_one_cell_8694/D wrom3_rom_base_one_cell_8417/D wl_0_64 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_8290 wrom3_rom_base_one_cell_8417/D wrom3_rom_base_one_cell_8290/D wl_0_65 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_8028 wrom3_rom_base_one_cell_8290/D wrom3_rom_base_one_cell_8028/D wl_0_67 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7892 wrom3_rom_base_one_cell_8028/D wrom3_rom_base_one_cell_7892/D wl_0_68 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7628 wrom3_rom_base_one_cell_7892/D wrom3_rom_base_one_cell_7628/D wl_0_70 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7384 wrom3_rom_base_one_cell_7628/D wrom3_rom_base_one_cell_7384/D wl_0_72 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7257 wrom3_rom_base_one_cell_7384/D wrom3_rom_base_one_cell_7257/D wl_0_73 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7132 wrom3_rom_base_one_cell_7257/D wrom3_rom_base_one_cell_7132/D wl_0_74 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7000 wrom3_rom_base_one_cell_7132/D wrom3_rom_base_one_cell_7000/D wl_0_75 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6739 wrom3_rom_base_one_cell_7000/D wrom3_rom_base_one_cell_6739/D wl_0_77 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6603 wrom3_rom_base_one_cell_6739/D wrom3_rom_base_one_cell_6603/D wl_0_78 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6480 wrom3_rom_base_one_cell_6603/D wrom3_rom_base_one_cell_6480/D wl_0_79 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6356 wrom3_rom_base_one_cell_6480/D wrom3_rom_base_one_cell_6356/D wl_0_80 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6240 wrom3_rom_base_one_cell_6356/D wrom3_rom_base_one_cell_6240/D wl_0_81 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6123 wrom3_rom_base_one_cell_6240/D wrom3_rom_base_one_cell_6123/D wl_0_82 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_5987 wrom3_rom_base_one_cell_6123/D wrom3_rom_base_one_cell_5987/D wl_0_83 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_5850 wrom3_rom_base_one_cell_5987/D wrom3_rom_base_one_cell_5850/D wl_0_84 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_5603 wrom3_rom_base_one_cell_5850/D wrom3_rom_base_one_cell_5603/D wl_0_86 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_5487 wrom3_rom_base_one_cell_5603/D wrom3_rom_base_one_cell_5487/D wl_0_87 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_5363 wrom3_rom_base_one_cell_5487/D wrom3_rom_base_one_cell_5363/D wl_0_88 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_5230 wrom3_rom_base_one_cell_5363/D wrom3_rom_base_one_cell_5230/D wl_0_89 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_4963 wrom3_rom_base_one_cell_5230/D wrom3_rom_base_one_cell_4963/D wl_0_91 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_4839 wrom3_rom_base_one_cell_4963/D wrom3_rom_base_one_cell_4839/D wl_0_92 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_4719 wrom3_rom_base_one_cell_4839/D wrom3_rom_base_one_cell_4719/D wl_0_96 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_4590 wrom3_rom_base_one_cell_4719/D wrom3_rom_base_one_cell_4590/D wl_0_97 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_4444 wrom3_rom_base_one_cell_4590/D wrom3_rom_base_one_cell_4444/D wl_0_98 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_4176 wrom3_rom_base_one_cell_4444/D wrom3_rom_base_one_cell_4176/D wl_0_100 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_3925 wrom3_rom_base_one_cell_4176/D wrom3_rom_base_one_cell_3925/D wl_0_102 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_3548 wrom3_rom_base_one_cell_3925/D wrom3_rom_base_one_cell_3548/D wl_0_105 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_3279 wrom3_rom_base_one_cell_3548/D wrom3_rom_base_one_cell_3279/D wl_0_107 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_3144 wrom3_rom_base_one_cell_3279/D wrom3_rom_base_one_cell_3144/D wl_0_108 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2900 wrom3_rom_base_one_cell_3144/D wrom3_rom_base_one_cell_2900/D wl_0_110 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2757 wrom3_rom_base_one_cell_2900/D wrom3_rom_base_one_cell_2757/D wl_0_111 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2617 wrom3_rom_base_one_cell_2757/D wrom3_rom_base_one_cell_2617/D wl_0_112 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2469 wrom3_rom_base_one_cell_2617/D wrom3_rom_base_one_cell_2469/D wl_0_113 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2206 wrom3_rom_base_one_cell_2469/D wrom3_rom_base_one_cell_2206/D wl_0_115 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2084 wrom3_rom_base_one_cell_2206/D wrom3_rom_base_one_cell_2084/D wl_0_116 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1961 wrom3_rom_base_one_cell_2084/D wrom3_rom_base_one_cell_1961/D wl_0_117 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1833 wrom3_rom_base_one_cell_1961/D wrom3_rom_base_one_cell_1833/D wl_0_118 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1697 wrom3_rom_base_one_cell_1833/D wrom3_rom_base_one_cell_1697/D wl_0_119 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1565 wrom3_rom_base_one_cell_1697/D wrom3_rom_base_one_cell_1565/D wl_0_120 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1322 wrom3_rom_base_one_cell_1565/D wrom3_rom_base_one_cell_1322/D wl_0_122 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1192 wrom3_rom_base_one_cell_1322/D wrom3_rom_base_one_cell_925/S wl_0_123 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_925 wrom3_rom_base_one_cell_925/S wrom3_rom_base_one_cell_925/D wl_0_128 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_772 wrom3_rom_base_one_cell_925/D wrom3_rom_base_one_cell_772/D wl_0_129 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_643 wrom3_rom_base_one_cell_772/D wrom3_rom_base_one_cell_643/D wl_0_130 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_510 wrom3_rom_base_one_cell_643/D wrom3_rom_base_one_cell_510/D wl_0_131 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_364 wrom3_rom_base_one_cell_510/D wrom3_rom_base_one_cell_364/D wl_0_132 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_245 wrom3_rom_base_one_cell_364/D gnd_uq0 precharge gnd wrom3_rom_base_one_cell
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
