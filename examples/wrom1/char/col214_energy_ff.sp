* wrom1 kolon 214 -- AKTIF CEVRIM ENERJISI (kolon basina)
* Bir tam cevrimde VDD'den cekilen YUK integrali -> E = Q*VDD.
* Enerji FREKANSTAN BAGIMSIZ; --tclk degistirilerek dogrulanabilir.
* Toplam makro enerjisi ~ 264 x (bu deger) + cevre birimi.
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
.param TCLK=200n
Vprecharge precharge 0 PULSE(0 {VDD} {TCLK/2} 100p 100p {TCLK/2-100p} {TCLK})

* wrom1 -- GERCEK PARAZITIK C ile kolon 214 izole olcum
* 88 seri NMOS + 46 olu hucre (graf yuruyusu, isim-bagimsiz)
Xprechg_pmos bl_0_214 precharge vdd gnd wrom1_precharge_cell
Xbl_inv gnd vdd vdd bl_0_214 bl_b wrom1_pinv_dec_3
Xwrom1_rom_base_one_cell_16988 bl_0_214 wrom1_rom_base_one_cell_16988/D wl_0_3 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_16848 wrom1_rom_base_one_cell_16988/D wrom1_rom_base_one_cell_16848/D wl_0_4 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_16597 wrom1_rom_base_one_cell_16848/D wrom1_rom_base_one_cell_16597/D wl_0_6 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_16351 wrom1_rom_base_one_cell_16597/D wrom1_rom_base_one_cell_16351/D wl_0_8 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_16089 wrom1_rom_base_one_cell_16351/D wrom1_rom_base_one_cell_16089/D wl_0_10 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15964 wrom1_rom_base_one_cell_16089/D wrom1_rom_base_one_cell_15964/D wl_0_11 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15692 wrom1_rom_base_one_cell_15964/D wrom1_rom_base_one_cell_15692/D wl_0_13 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15550 wrom1_rom_base_one_cell_15692/D wrom1_rom_base_one_cell_15550/D wl_0_14 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15279 wrom1_rom_base_one_cell_15550/D wrom1_rom_base_one_cell_15279/D wl_0_16 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15147 wrom1_rom_base_one_cell_15279/D wrom1_rom_base_one_cell_15147/D wl_0_17 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_15011 wrom1_rom_base_one_cell_15147/D wrom1_rom_base_one_cell_15011/D wl_0_18 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_14872 wrom1_rom_base_one_cell_15011/D wrom1_rom_base_one_cell_14872/D wl_0_19 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_14600 wrom1_rom_base_one_cell_14872/D wrom1_rom_base_one_cell_14600/D wl_0_21 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_14363 wrom1_rom_base_one_cell_14600/D wrom1_rom_base_one_cell_14363/D wl_0_23 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_14223 wrom1_rom_base_one_cell_14363/D wrom1_rom_base_one_cell_14223/D wl_0_24 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13963 wrom1_rom_base_one_cell_14223/D wrom1_rom_base_one_cell_13963/D wl_0_26 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13730 wrom1_rom_base_one_cell_13963/D wrom1_rom_base_one_cell_13730/D wl_0_28 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13591 wrom1_rom_base_one_cell_13730/D wrom1_rom_base_one_cell_13591/D wl_0_29 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13468 wrom1_rom_base_one_cell_13591/D wrom1_rom_base_one_cell_13468/D wl_0_30 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13345 wrom1_rom_base_one_cell_13468/D wrom1_rom_base_one_cell_13345/D wl_0_31 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13213 wrom1_rom_base_one_cell_13345/D wrom1_rom_base_one_cell_13213/D wl_0_32 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_13072 wrom1_rom_base_one_cell_13213/D wrom1_rom_base_one_cell_13072/D wl_0_33 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12936 wrom1_rom_base_one_cell_13072/D wrom1_rom_base_one_cell_12936/D wl_0_34 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12829 wrom1_rom_base_one_cell_12936/D wrom1_rom_base_one_cell_12829/D wl_0_35 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12718 wrom1_rom_base_one_cell_12829/D wrom1_rom_base_one_cell_12718/D wl_0_36 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12478 wrom1_rom_base_one_cell_12718/D wrom1_rom_base_one_cell_12478/D wl_0_38 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12347 wrom1_rom_base_one_cell_12478/D wrom1_rom_base_one_cell_12347/D wl_0_39 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12245 wrom1_rom_base_one_cell_12347/D wrom1_rom_base_one_cell_12245/D wl_0_40 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_12105 wrom1_rom_base_one_cell_12245/D wrom1_rom_base_one_cell_12105/D wl_0_41 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_11980 wrom1_rom_base_one_cell_12105/D wrom1_rom_base_one_cell_11980/D wl_0_42 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_11861 wrom1_rom_base_one_cell_11980/D wrom1_rom_base_one_cell_11861/D wl_0_43 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_11736 wrom1_rom_base_one_cell_11861/D wrom1_rom_base_one_cell_11736/D wl_0_44 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_11612 wrom1_rom_base_one_cell_11736/D wrom1_rom_base_one_cell_11612/D wl_0_45 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_11342 wrom1_rom_base_one_cell_11612/D wrom1_rom_base_one_cell_11342/D wl_0_47 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_11078 wrom1_rom_base_one_cell_11342/D wrom1_rom_base_one_cell_11078/D wl_0_49 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_10954 wrom1_rom_base_one_cell_11078/D wrom1_rom_base_one_cell_10954/D wl_0_50 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_10814 wrom1_rom_base_one_cell_10954/D wrom1_rom_base_zero_cell_9962/S wl_0_51 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_10439 wrom1_rom_base_zero_cell_9962/S wrom1_rom_base_one_cell_10439/D wl_0_54 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_10302 wrom1_rom_base_one_cell_10439/D wrom1_rom_base_one_cell_10302/D wl_0_55 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_10173 wrom1_rom_base_one_cell_10302/D wrom1_rom_base_one_cell_9932/S wl_0_56 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_9932 wrom1_rom_base_one_cell_9932/S wrom1_rom_base_one_cell_9932/D wl_0_58 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_9833 wrom1_rom_base_one_cell_9932/D wrom1_rom_base_one_cell_9833/D wl_0_59 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_9712 wrom1_rom_base_one_cell_9833/D wrom1_rom_base_one_cell_9712/D wl_0_60 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_9570 wrom1_rom_base_one_cell_9712/D wrom1_rom_base_one_cell_9570/D wl_0_61 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_9325 wrom1_rom_base_one_cell_9570/D wrom1_rom_base_one_cell_9325/D wl_0_63 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_9071 wrom1_rom_base_one_cell_9325/D wrom1_rom_base_one_cell_9071/D wl_0_65 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8947 wrom1_rom_base_one_cell_9071/D wrom1_rom_base_one_cell_8947/D wl_0_66 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8819 wrom1_rom_base_one_cell_8947/D wrom1_rom_base_one_cell_8819/D wl_0_67 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8555 wrom1_rom_base_one_cell_8819/D wrom1_rom_base_one_cell_8555/D wl_0_69 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8436 wrom1_rom_base_one_cell_8555/D wrom1_rom_base_one_cell_8436/D wl_0_70 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8300 wrom1_rom_base_one_cell_8436/D wrom1_rom_base_one_cell_8300/D wl_0_71 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8149 wrom1_rom_base_one_cell_8300/D wrom1_rom_base_one_cell_8149/D wl_0_72 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_8017 wrom1_rom_base_one_cell_8149/D wrom1_rom_base_one_cell_8017/D wl_0_73 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_7743 wrom1_rom_base_one_cell_8017/D wrom1_rom_base_one_cell_7743/D wl_0_75 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_7091 wrom1_rom_base_one_cell_7743/D wrom1_rom_base_one_cell_7091/D wl_0_80 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_6827 wrom1_rom_base_one_cell_7091/D wrom1_rom_base_one_cell_6827/D wl_0_82 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_6283 wrom1_rom_base_one_cell_6827/D wrom1_rom_base_one_cell_6283/D wl_0_86 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_6146 wrom1_rom_base_one_cell_6283/D wrom1_rom_base_one_cell_6146/D wl_0_87 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_6034 wrom1_rom_base_one_cell_6146/D wrom1_rom_base_one_cell_6034/D wl_0_88 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_5901 wrom1_rom_base_one_cell_6034/D wrom1_rom_base_one_cell_5901/D wl_0_89 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_5769 wrom1_rom_base_one_cell_5901/D wrom1_rom_base_one_cell_5769/D wl_0_90 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_5515 wrom1_rom_base_one_cell_5769/D wrom1_rom_base_one_cell_5515/D wl_0_92 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_5377 wrom1_rom_base_one_cell_5515/D wrom1_rom_base_one_cell_5377/D wl_0_93 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_5115 wrom1_rom_base_one_cell_5377/D wrom1_rom_base_one_cell_5115/D wl_0_95 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_4966 wrom1_rom_base_one_cell_5115/D wrom1_rom_base_one_cell_4966/D wl_0_96 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_4582 wrom1_rom_base_one_cell_4966/D wrom1_rom_base_one_cell_4582/D wl_0_99 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_4464 wrom1_rom_base_one_cell_4582/D wrom1_rom_base_one_cell_4464/D wl_0_100 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_4046 wrom1_rom_base_one_cell_4464/D wrom1_rom_base_one_cell_4046/D wl_0_103 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_3915 wrom1_rom_base_one_cell_4046/D wrom1_rom_base_one_cell_3915/D wl_0_104 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_3807 wrom1_rom_base_one_cell_3915/D wrom1_rom_base_one_cell_3807/D wl_0_105 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_3536 wrom1_rom_base_one_cell_3807/D wrom1_rom_base_one_cell_3536/D wl_0_107 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_3281 wrom1_rom_base_one_cell_3536/D wrom1_rom_base_one_cell_3281/D wl_0_109 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_3143 wrom1_rom_base_one_cell_3281/D wrom1_rom_base_one_cell_3143/D wl_0_110 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_2880 wrom1_rom_base_one_cell_3143/D wrom1_rom_base_one_cell_2880/D wl_0_112 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_2731 wrom1_rom_base_one_cell_2880/D wrom1_rom_base_one_cell_2731/D wl_0_113 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_2479 wrom1_rom_base_one_cell_2731/D wrom1_rom_base_one_cell_2479/D wl_0_115 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_2341 wrom1_rom_base_one_cell_2479/D wrom1_rom_base_one_cell_2341/D wl_0_116 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_2235 wrom1_rom_base_one_cell_2341/D wrom1_rom_base_one_cell_2235/D wl_0_117 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1959 wrom1_rom_base_one_cell_2235/D wrom1_rom_base_one_cell_1959/D wl_0_119 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1846 wrom1_rom_base_one_cell_1959/D wrom1_rom_base_one_cell_1846/D wl_0_120 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1718 wrom1_rom_base_one_cell_1846/D wrom1_rom_base_one_cell_1718/D wl_0_121 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1581 wrom1_rom_base_one_cell_1718/D wrom1_rom_base_one_cell_1581/D wl_0_122 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1449 wrom1_rom_base_one_cell_1581/D wrom1_rom_base_one_cell_1449/D wl_0_123 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1214 wrom1_rom_base_one_cell_1449/D wrom1_rom_base_one_cell_1214/D wl_0_125 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_1078 wrom1_rom_base_one_cell_1214/D wrom1_rom_base_one_cell_652/S wl_0_126 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_652 wrom1_rom_base_one_cell_652/S wrom1_rom_base_one_cell_652/D wl_0_129 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_274 wrom1_rom_base_one_cell_652/D wrom1_rom_base_one_cell_41/S wl_0_132 gnd wrom1_rom_base_one_cell
Xwrom1_rom_base_one_cell_41 wrom1_rom_base_one_cell_41/S gnd_uq0 precharge gnd wrom1_rom_base_one_cell
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

.tran '200n/400' '4*TCLK' uic
* 2. VE 3. cevrim ayri olculur: esit cikmalari devrenin OTURDUGUNU gosterir
* (uic ile tum dugumler 0'dan basliyor, zincir yavas doluyor).
* 3. cevrim daha oturmus oldugu icin .lib'e O yazilir.
* FREKANS BAGIMSIZLIGI DOGRULANDI (2026-09-05, wrom0 kolon 155, TT):
*   TCLK=200n -> q_c3 = 2.342e-13 C
*   TCLK=400n -> q_c3 = 2.419e-13 C   (periyot 2x, yuk %3.3 farkli)
.measure tran q_c2 integ i(Vvdd) from='TCLK' to='2*TCLK'
.measure tran q_c3 integ i(Vvdd) from='2*TCLK' to='3*TCLK'
.measure tran e_col_pj param='abs(q_c3)*VDD*1e12'
.end
