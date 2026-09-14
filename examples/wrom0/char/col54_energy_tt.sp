* wrom0 kolon 54 -- AKTIF CEVRIM ENERJISI (kolon basina)
* Bir tam cevrimde VDD'den cekilen YUK integrali -> E = Q*VDD.
* Enerji FREKANSTAN BAGIMSIZ; --tclk degistirilerek dogrulanabilir.
* Toplam makro enerjisi ~ 264 x (bu deger) + cevre birimi.
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
.param TCLK=200n
Vprecharge precharge 0 PULSE(0 {VDD} {TCLK/2} 100p 100p {TCLK/2-100p} {TCLK})

* wrom0 -- GERCEK PARAZITIK C ile kolon 54 izole olcum
* 71 seri NMOS + 36 olu hucre (graf yuruyusu, isim-bagimsiz)
Xprechg_pmos bl_0_54 precharge vdd gnd wrom0_precharge_cell
Xbl_inv gnd vdd vdd bl_0_54 bl_b wrom0_pinv_dec_3
Xwrom0_rom_base_one_cell_16742 bl_0_54 wrom0_rom_base_one_cell_16742/D wl_0_3 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_16587 wrom0_rom_base_one_cell_16742/D wrom0_rom_base_one_cell_16587/D wl_0_4 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_16254 wrom0_rom_base_one_cell_16587/D wrom0_rom_base_one_cell_16254/D wl_0_6 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15902 wrom0_rom_base_one_cell_16254/D wrom0_rom_base_one_cell_15902/D wl_0_8 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15738 wrom0_rom_base_one_cell_15902/D wrom0_rom_base_one_cell_15738/D wl_0_9 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15567 wrom0_rom_base_one_cell_15738/D wrom0_rom_base_one_cell_15567/D wl_0_10 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15403 wrom0_rom_base_one_cell_15567/D wrom0_rom_base_one_cell_15403/D wl_0_11 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_15067 wrom0_rom_base_one_cell_15403/D wrom0_rom_base_one_cell_15067/D wl_0_13 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_14911 wrom0_rom_base_one_cell_15067/D wrom0_rom_base_one_cell_14911/D wl_0_14 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_14763 wrom0_rom_base_one_cell_14911/D wrom0_rom_base_one_cell_14763/D wl_0_15 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_14600 wrom0_rom_base_one_cell_14763/D wrom0_rom_base_one_cell_14600/D wl_0_16 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_14441 wrom0_rom_base_one_cell_14600/D wrom0_rom_base_one_cell_14441/D wl_0_17 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_14268 wrom0_rom_base_one_cell_14441/D wrom0_rom_base_one_cell_14268/D wl_0_18 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_13946 wrom0_rom_base_one_cell_14268/D wrom0_rom_base_one_cell_13946/D wl_0_20 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_13602 wrom0_rom_base_one_cell_13946/D wrom0_rom_base_one_cell_13602/D wl_0_22 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_13439 wrom0_rom_base_one_cell_13602/D wrom0_rom_base_one_cell_13439/D wl_0_23 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_12641 wrom0_rom_base_one_cell_13439/D wrom0_rom_base_one_cell_12641/D wl_0_28 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_12488 wrom0_rom_base_one_cell_12641/D wrom0_rom_base_one_cell_12488/D wl_0_29 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_12308 wrom0_rom_base_one_cell_12488/D wrom0_rom_base_one_cell_12308/D wl_0_30 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_11846 wrom0_rom_base_one_cell_12308/D wrom0_rom_base_one_cell_11846/D wl_0_33 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_11471 wrom0_rom_base_one_cell_11846/D wrom0_rom_base_one_cell_11471/D wl_0_35 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_11318 wrom0_rom_base_one_cell_11471/D wrom0_rom_base_one_cell_11318/D wl_0_36 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_11145 wrom0_rom_base_one_cell_11318/D wrom0_rom_base_one_cell_11145/D wl_0_37 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_10839 wrom0_rom_base_one_cell_11145/D wrom0_rom_base_one_cell_10839/D wl_0_39 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_10673 wrom0_rom_base_one_cell_10839/D wrom0_rom_base_one_cell_10673/D wl_0_40 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_10533 wrom0_rom_base_one_cell_10673/D wrom0_rom_base_one_cell_10533/D wl_0_41 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_10392 wrom0_rom_base_one_cell_10533/D wrom0_rom_base_one_cell_10392/D wl_0_42 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_10217 wrom0_rom_base_one_cell_10392/D wrom0_rom_base_one_cell_10217/D wl_0_43 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_10058 wrom0_rom_base_one_cell_10217/D wrom0_rom_base_one_cell_9905/S wl_0_44 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_9905 wrom0_rom_base_one_cell_9905/S wrom0_rom_base_one_cell_9905/D wl_0_45 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_9614 wrom0_rom_base_one_cell_9905/D wrom0_rom_base_one_cell_9614/D wl_0_47 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_9475 wrom0_rom_base_one_cell_9614/D wrom0_rom_base_one_cell_9475/D wl_0_48 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_9325 wrom0_rom_base_one_cell_9475/D wrom0_rom_base_one_cell_9325/D wl_0_49 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_9147 wrom0_rom_base_one_cell_9325/D wrom0_rom_base_one_cell_9147/D wl_0_50 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_8994 wrom0_rom_base_one_cell_9147/D wrom0_rom_base_one_cell_8994/D wl_0_51 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_8851 wrom0_rom_base_one_cell_8994/D wrom0_rom_base_one_cell_8851/D wl_0_52 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_8710 wrom0_rom_base_one_cell_8851/D wrom0_rom_base_one_cell_8710/D wl_0_53 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_8218 wrom0_rom_base_one_cell_8710/D wrom0_rom_base_one_cell_8218/D wl_0_56 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_8072 wrom0_rom_base_one_cell_8218/D wrom0_rom_base_one_cell_8072/D wl_0_57 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_7923 wrom0_rom_base_one_cell_8072/D wrom0_rom_base_one_cell_7923/D wl_0_58 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_7775 wrom0_rom_base_one_cell_7923/D wrom0_rom_base_one_cell_7775/D wl_0_59 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_7626 wrom0_rom_base_one_cell_7775/D wrom0_rom_base_one_cell_7626/D wl_0_60 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_7294 wrom0_rom_base_one_cell_7626/D wrom0_rom_base_one_cell_7294/D wl_0_62 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_7150 wrom0_rom_base_one_cell_7294/D wrom0_rom_base_one_cell_7150/D wl_0_63 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_6690 wrom0_rom_base_one_cell_7150/D wrom0_rom_base_one_cell_6690/D wl_0_66 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_6552 wrom0_rom_base_one_cell_6690/D wrom0_rom_base_one_cell_6552/D wl_0_67 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_6250 wrom0_rom_base_one_cell_6552/D wrom0_rom_base_one_cell_6250/D wl_0_69 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_6080 wrom0_rom_base_one_cell_6250/D wrom0_rom_base_one_cell_6080/D wl_0_70 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_5915 wrom0_rom_base_one_cell_6080/D wrom0_rom_base_one_cell_5915/D wl_0_71 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_5455 wrom0_rom_base_one_cell_5915/D wrom0_rom_base_one_cell_5455/D wl_0_74 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_5290 wrom0_rom_base_one_cell_5455/D wrom0_rom_base_one_cell_5290/D wl_0_75 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_5135 wrom0_rom_base_one_cell_5290/D wrom0_rom_base_one_cell_5135/D wl_0_76 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_4679 wrom0_rom_base_one_cell_5135/D wrom0_rom_base_one_cell_4679/D wl_0_79 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_4179 wrom0_rom_base_one_cell_4679/D wrom0_rom_base_one_cell_4179/D wl_0_82 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_4029 wrom0_rom_base_one_cell_4179/D wrom0_rom_base_one_cell_4029/D wl_0_83 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_3881 wrom0_rom_base_one_cell_4029/D wrom0_rom_base_one_cell_3881/D wl_0_84 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_3709 wrom0_rom_base_one_cell_3881/D wrom0_rom_base_one_cell_3709/D wl_0_85 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_3578 wrom0_rom_base_one_cell_3709/D wrom0_rom_base_one_cell_3578/D wl_0_86 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_3411 wrom0_rom_base_one_cell_3578/D wrom0_rom_base_one_cell_3411/D wl_0_87 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_3055 wrom0_rom_base_one_cell_3411/D wrom0_rom_base_one_cell_3055/D wl_0_89 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_2902 wrom0_rom_base_one_cell_3055/D wrom0_rom_base_one_cell_2902/D wl_0_90 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_2586 wrom0_rom_base_one_cell_2902/D wrom0_rom_base_one_cell_2586/D wl_0_92 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_2257 wrom0_rom_base_one_cell_2586/D wrom0_rom_base_one_cell_2257/D wl_0_94 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_2087 wrom0_rom_base_one_cell_2257/D wrom0_rom_base_one_cell_2087/D wl_0_95 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_1938 wrom0_rom_base_one_cell_2087/D wrom0_rom_base_one_cell_1938/D wl_0_96 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_1770 wrom0_rom_base_one_cell_1938/D wrom0_rom_base_one_cell_1770/D wl_0_97 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_1611 wrom0_rom_base_one_cell_1770/D wrom0_rom_base_one_cell_1611/D wl_0_98 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_1446 wrom0_rom_base_one_cell_1611/D wrom0_rom_base_one_cell_1446/D wl_0_99 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_1267 wrom0_rom_base_one_cell_1446/D wrom0_rom_base_one_cell_1267/D wl_0_100 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_1110 wrom0_rom_base_one_cell_1267/D wrom0_rom_base_one_cell_265/S wl_0_101 gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_one_cell_265 wrom0_rom_base_one_cell_265/S gnd_uq0 precharge gnd wrom0_rom_base_one_cell
Xwrom0_rom_base_zero_cell_16613 bl_0_54 wl_0_2 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_16749 bl_0_54 wl_0_1 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_16894 bl_0_54 wl_0_0 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_16177 wrom0_rom_base_one_cell_16587/D wl_0_5 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_15872 wrom0_rom_base_one_cell_16254/D wl_0_7 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_15098 wrom0_rom_base_one_cell_15403/D wl_0_12 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_13992 wrom0_rom_base_one_cell_14268/D wl_0_19 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_13681 wrom0_rom_base_one_cell_13946/D wl_0_21 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_13043 wrom0_rom_base_one_cell_13439/D wl_0_25 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_12727 wrom0_rom_base_one_cell_13439/D wl_0_27 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_13206 wrom0_rom_base_one_cell_13439/D wl_0_24 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_12873 wrom0_rom_base_one_cell_13439/D wl_0_26 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_12119 wrom0_rom_base_one_cell_12308/D wl_0_31 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_11937 wrom0_rom_base_one_cell_12308/D wl_0_32 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_11636 wrom0_rom_base_one_cell_11846/D wl_0_34 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_11030 wrom0_rom_base_one_cell_11145/D wl_0_38 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_9696 wrom0_rom_base_one_cell_9905/D wl_0_46 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_8368 wrom0_rom_base_one_cell_8710/D wl_0_54 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_8199 wrom0_rom_base_one_cell_8710/D wl_0_55 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_7198 wrom0_rom_base_one_cell_7626/D wl_0_61 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_6539 wrom0_rom_base_one_cell_7150/D wl_0_65 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_6705 wrom0_rom_base_one_cell_7150/D wl_0_64 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_6011 wrom0_rom_base_one_cell_6552/D wl_0_68 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_5217 wrom0_rom_base_one_cell_5915/D wl_0_73 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_5386 wrom0_rom_base_one_cell_5915/D wl_0_72 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_4393 wrom0_rom_base_one_cell_5135/D wl_0_78 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_4567 wrom0_rom_base_one_cell_5135/D wl_0_77 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_3945 wrom0_rom_base_one_cell_4679/D wl_0_81 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_4093 wrom0_rom_base_one_cell_4679/D wl_0_80 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_2798 wrom0_rom_base_one_cell_3411/D wl_0_88 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_2319 wrom0_rom_base_one_cell_2902/D wl_0_91 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_2010 wrom0_rom_base_one_cell_2586/D wl_0_93 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_135 wrom0_rom_base_one_cell_265/S wl_0_105 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_602 wrom0_rom_base_one_cell_265/S wl_0_102 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_274 wrom0_rom_base_one_cell_265/S wl_0_104 gnd wrom0_rom_base_zero_cell
Xwrom0_rom_base_zero_cell_428 wrom0_rom_base_one_cell_265/S wl_0_103 gnd wrom0_rom_base_zero_cell
.subckt wrom0_rom_base_one_cell S D G gnd
X0 D G S gnd sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.108u ps=1.32 w=0.36 l=0.15
C0 S D 0.04533f
C1 S G 0.00394f
C2 G D 0.00394f
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
C0 D G 0.00394f
C1 D vdd 0.03592f
C2 vdd G 0.05763f
C3 D gnd 0.05546f
C4 G gnd 0.03904f
C5 vdd gnd 0.33982f
.ends
.subckt wrom0_pinv_dec_3 gnd vdd w_692_n79# A Z
X0 vdd A Z w_692_n79# sky130_fd_pr__pfet_01v8 ad=1.5u pd=10.6 as=1.5u ps=10.6 w=5 l=0.15
X1 gnd A Z gnd sky130_fd_pr__nfet_01v8 ad=0.504u pd=3.96 as=0.504u ps=3.96 w=1.68 l=0.15
C0 Z vdd 0.06954f
C1 A w_692_n79# 0.10891f
C2 vdd A 0.01892f
C3 Z A 0.04991f
C4 vdd w_692_n79# 0.02783f
C5 Z w_692_n79# 0.05333f
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
