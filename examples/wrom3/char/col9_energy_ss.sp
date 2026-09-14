* wrom3 kolon 9 -- AKTIF CEVRIM ENERJISI (kolon basina)
* Bir tam cevrimde VDD'den cekilen YUK integrali -> E = Q*VDD.
* Enerji FREKANSTAN BAGIMSIZ; --tclk degistirilerek dogrulanabilir.
* Toplam makro enerjisi ~ 264 x (bu deger) + cevre birimi.
.lib /home/hpw/OpenLane/pdks/sky130A/libs.tech/ngspice/sky130.lib.spice ss
.temp 100
.param VDD=1.6

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

* wrom3 -- GERCEK PARAZITIK C ile kolon 9 izole olcum
* 59 seri NMOS + 48 olu hucre (graf yuruyusu, isim-bagimsiz)
Xprechg_pmos bl_0_9 precharge vdd gnd wrom3_precharge_cell
Xbl_inv gnd vdd vdd bl_0_9 bl_b wrom3_pinv_dec_3
Xwrom3_rom_base_one_cell_15881 bl_0_9 wrom3_rom_base_one_cell_15881/D wl_0_0 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_15709 wrom3_rom_base_one_cell_15881/D wrom3_rom_base_one_cell_15709/D wl_0_1 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_15409 wrom3_rom_base_one_cell_15709/D wrom3_rom_base_one_cell_15409/D wl_0_3 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_15242 wrom3_rom_base_one_cell_15409/D wrom3_rom_base_one_cell_15242/D wl_0_4 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_15064 wrom3_rom_base_one_cell_15242/D wrom3_rom_base_one_cell_15064/D wl_0_5 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_14914 wrom3_rom_base_one_cell_15064/D wrom3_rom_base_one_cell_14914/D wl_0_6 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_14734 wrom3_rom_base_one_cell_14914/D wrom3_rom_base_one_cell_14734/D wl_0_7 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_14567 wrom3_rom_base_one_cell_14734/D wrom3_rom_base_one_cell_14567/D wl_0_8 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_14256 wrom3_rom_base_one_cell_14567/D wrom3_rom_base_one_cell_14256/D wl_0_10 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_14079 wrom3_rom_base_one_cell_14256/D wrom3_rom_base_one_cell_14079/D wl_0_11 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_13935 wrom3_rom_base_one_cell_14079/D wrom3_rom_base_one_cell_13935/D wl_0_12 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_13768 wrom3_rom_base_one_cell_13935/D wrom3_rom_base_one_cell_13768/D wl_0_13 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_13598 wrom3_rom_base_one_cell_13768/D wrom3_rom_base_one_cell_13598/D wl_0_14 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_13411 wrom3_rom_base_one_cell_13598/D wrom3_rom_base_one_cell_13411/D wl_0_15 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_13232 wrom3_rom_base_one_cell_13411/D wrom3_rom_base_one_cell_13232/D wl_0_16 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_13068 wrom3_rom_base_one_cell_13232/D wrom3_rom_base_one_cell_13068/D wl_0_17 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_12757 wrom3_rom_base_one_cell_13068/D wrom3_rom_base_one_cell_12757/D wl_0_19 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_12586 wrom3_rom_base_one_cell_12757/D wrom3_rom_base_one_cell_12586/D wl_0_20 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_12437 wrom3_rom_base_one_cell_12586/D wrom3_rom_base_one_cell_12437/D wl_0_21 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_11718 wrom3_rom_base_one_cell_12437/D wrom3_rom_base_one_cell_11718/D wl_0_28 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_11564 wrom3_rom_base_one_cell_11718/D wrom3_rom_base_one_cell_11564/D wl_0_29 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_11110 wrom3_rom_base_one_cell_11564/D wrom3_rom_base_one_cell_11110/D wl_0_32 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_10927 wrom3_rom_base_one_cell_11110/D wrom3_rom_base_one_cell_10927/D wl_0_33 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_10277 wrom3_rom_base_one_cell_10927/D wrom3_rom_base_one_cell_9817/S wl_0_37 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_9817 wrom3_rom_base_one_cell_9817/S wrom3_rom_base_one_cell_9817/D wl_0_40 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_9038 wrom3_rom_base_one_cell_9817/D wrom3_rom_base_one_cell_9038/D wl_0_45 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_8427 wrom3_rom_base_one_cell_9038/D wrom3_rom_base_one_cell_8427/D wl_0_51 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_8129 wrom3_rom_base_one_cell_8427/D wrom3_rom_base_one_cell_8129/D wl_0_53 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7959 wrom3_rom_base_one_cell_8129/D wrom3_rom_base_one_cell_7959/D wl_0_54 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7808 wrom3_rom_base_one_cell_7959/D wrom3_rom_base_one_cell_7808/D wl_0_55 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7481 wrom3_rom_base_one_cell_7808/D wrom3_rom_base_one_cell_7481/D wl_0_57 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7326 wrom3_rom_base_one_cell_7481/D wrom3_rom_base_one_cell_7326/D wl_0_58 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_7177 wrom3_rom_base_one_cell_7326/D wrom3_rom_base_one_cell_7177/D wl_0_59 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6846 wrom3_rom_base_one_cell_7177/D wrom3_rom_base_one_cell_6846/D wl_0_61 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6684 wrom3_rom_base_one_cell_6846/D wrom3_rom_base_one_cell_6684/D wl_0_62 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6512 wrom3_rom_base_one_cell_6684/D wrom3_rom_base_one_cell_6512/D wl_0_63 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_6221 wrom3_rom_base_one_cell_6512/D wrom3_rom_base_one_cell_6221/D wl_0_65 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_5887 wrom3_rom_base_one_cell_6221/D wrom3_rom_base_one_cell_5887/D wl_0_67 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_5438 wrom3_rom_base_one_cell_5887/D wrom3_rom_base_one_cell_5438/D wl_0_70 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_5268 wrom3_rom_base_one_cell_5438/D wrom3_rom_base_one_cell_5268/D wl_0_71 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_4733 wrom3_rom_base_one_cell_5268/D wrom3_rom_base_one_cell_4733/D wl_0_76 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_4355 wrom3_rom_base_one_cell_4733/D wrom3_rom_base_one_cell_4355/D wl_0_79 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_3727 wrom3_rom_base_one_cell_4355/D wrom3_rom_base_one_cell_3727/D wl_0_83 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_3557 wrom3_rom_base_one_cell_3727/D wrom3_rom_base_one_cell_3557/D wl_0_84 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_3383 wrom3_rom_base_one_cell_3557/D wrom3_rom_base_one_cell_3383/D wl_0_85 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_3057 wrom3_rom_base_one_cell_3383/D wrom3_rom_base_one_cell_3057/D wl_0_87 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2728 wrom3_rom_base_one_cell_3057/D wrom3_rom_base_one_cell_2728/D wl_0_89 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2383 wrom3_rom_base_one_cell_2728/D wrom3_rom_base_one_cell_2383/D wl_0_91 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2214 wrom3_rom_base_one_cell_2383/D wrom3_rom_base_one_cell_2214/D wl_0_92 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_2065 wrom3_rom_base_one_cell_2214/D wrom3_rom_base_one_cell_2065/D wl_0_93 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1740 wrom3_rom_base_one_cell_2065/D wrom3_rom_base_one_cell_1740/D wl_0_95 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1423 wrom3_rom_base_one_cell_1740/D wrom3_rom_base_one_cell_1423/D wl_0_97 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1268 wrom3_rom_base_one_cell_1423/D wrom3_rom_base_one_cell_1268/D wl_0_98 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_1108 wrom3_rom_base_one_cell_1268/D wrom3_rom_base_one_cell_938/S wl_0_99 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_938 wrom3_rom_base_one_cell_938/S wrom3_rom_base_one_cell_938/D wl_0_102 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_819 wrom3_rom_base_one_cell_938/D wrom3_rom_base_one_cell_819/D wl_0_103 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_653 wrom3_rom_base_one_cell_819/D wrom3_rom_base_one_cell_653/D wl_0_104 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_484 wrom3_rom_base_one_cell_653/D wrom3_rom_base_one_cell_484/D wl_0_105 gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_one_cell_310 wrom3_rom_base_one_cell_484/D gnd_uq0 precharge gnd wrom3_rom_base_one_cell
Xwrom3_rom_base_zero_cell_18032 wrom3_rom_base_one_cell_15709/D wl_0_2 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_16934 wrom3_rom_base_one_cell_14567/D wl_0_9 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_15561 wrom3_rom_base_one_cell_13068/D wl_0_18 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_14898 wrom3_rom_base_one_cell_12437/D wl_0_22 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_14109 wrom3_rom_base_one_cell_12437/D wl_0_25 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_13701 wrom3_rom_base_one_cell_12437/D wl_0_27 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_14427 wrom3_rom_base_one_cell_12437/D wl_0_24 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_14722 wrom3_rom_base_one_cell_12437/D wl_0_23 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_13853 wrom3_rom_base_one_cell_12437/D wl_0_26 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_13052 wrom3_rom_base_one_cell_11564/D wl_0_31 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_13217 wrom3_rom_base_one_cell_11564/D wl_0_30 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_12597 wrom3_rom_base_one_cell_10927/D wl_0_34 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_12430 wrom3_rom_base_one_cell_10927/D wl_0_35 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_12261 wrom3_rom_base_one_cell_10927/D wl_0_36 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_11770 wrom3_rom_base_one_cell_9817/S wl_0_39 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_11949 wrom3_rom_base_one_cell_9817/S wl_0_38 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_11111 wrom3_rom_base_one_cell_9817/D wl_0_43 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_11295 wrom3_rom_base_one_cell_9817/D wl_0_42 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_10939 wrom3_rom_base_one_cell_9817/D wl_0_44 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_11459 wrom3_rom_base_one_cell_9817/D wl_0_41 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_10119 wrom3_rom_base_one_cell_9038/D wl_0_49 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_9799 wrom3_rom_base_one_cell_9038/D wl_0_50 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_10294 wrom3_rom_base_one_cell_9038/D wl_0_48 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_10625 wrom3_rom_base_one_cell_9038/D wl_0_46 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_10459 wrom3_rom_base_one_cell_9038/D wl_0_47 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_9291 wrom3_rom_base_one_cell_8427/D wl_0_52 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_8673 wrom3_rom_base_one_cell_7808/D wl_0_56 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_8020 wrom3_rom_base_one_cell_7177/D wl_0_60 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_7385 wrom3_rom_base_one_cell_6512/D wl_0_64 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_7045 wrom3_rom_base_one_cell_6221/D wl_0_66 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_6565 wrom3_rom_base_one_cell_5887/D wl_0_69 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_6738 wrom3_rom_base_one_cell_5887/D wl_0_68 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_5495 wrom3_rom_base_one_cell_5268/D wl_0_75 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_5752 wrom3_rom_base_one_cell_5268/D wl_0_74 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_6083 wrom3_rom_base_one_cell_5268/D wl_0_72 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_5927 wrom3_rom_base_one_cell_5268/D wl_0_73 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_4743 wrom3_rom_base_one_cell_4733/D wl_0_78 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_4904 wrom3_rom_base_one_cell_4733/D wl_0_77 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_4112 wrom3_rom_base_one_cell_4355/D wl_0_82 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_4280 wrom3_rom_base_one_cell_4355/D wl_0_81 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_4444 wrom3_rom_base_one_cell_4355/D wl_0_80 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_3496 wrom3_rom_base_one_cell_3383/D wl_0_86 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_3161 wrom3_rom_base_one_cell_3057/D wl_0_88 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_2876 wrom3_rom_base_one_cell_2728/D wl_0_90 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_2250 wrom3_rom_base_one_cell_2065/D wl_0_94 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_1935 wrom3_rom_base_one_cell_1740/D wl_0_96 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_966 wrom3_rom_base_one_cell_938/S wl_0_101 gnd wrom3_rom_base_zero_cell
Xwrom3_rom_base_zero_cell_1286 wrom3_rom_base_one_cell_938/S wl_0_100 gnd wrom3_rom_base_zero_cell
.subckt wrom3_rom_base_one_cell S D G gnd
X0 D G S gnd sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.108u ps=1.32 w=0.36 l=0.15
C0 D S 0.04533f
C1 D G 0.00394f
C2 G S 0.00394f
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
C0 G D 0.00394f
C1 G vdd 0.05763f
C2 vdd D 0.03592f
C3 D gnd 0.05546f
C4 G gnd 0.03904f
C5 vdd gnd 0.33982f
.ends
.subckt wrom3_pinv_dec_3 gnd vdd w_692_n79# A Z
X0 vdd A Z w_692_n79# sky130_fd_pr__pfet_01v8 ad=1.5u pd=10.6 as=1.5u ps=10.6 w=5 l=0.15
X1 gnd A Z gnd sky130_fd_pr__nfet_01v8 ad=0.504u pd=3.96 as=0.504u ps=3.96 w=1.68 l=0.15
C0 w_692_n79# Z 0.05333f
C1 A Z 0.04991f
C2 w_692_n79# vdd 0.02783f
C3 A vdd 0.01892f
C4 vdd Z 0.06954f
C5 A w_692_n79# 0.10891f
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
