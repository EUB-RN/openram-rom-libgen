* wrom2 kolon 42 -- AKTIF CEVRIM ENERJISI (kolon basina)
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

* wrom2 -- GERCEK PARAZITIK C ile kolon 42 izole olcum
* 68 seri NMOS + 39 olu hucre (graf yuruyusu, isim-bagimsiz)
Xprechg_pmos bl_0_42 precharge vdd gnd wrom2_precharge_cell
Xbl_inv gnd vdd vdd bl_0_42 bl_b wrom2_pinv_dec_3
Xwrom2_rom_base_one_cell_17243 bl_0_42 wrom2_rom_base_one_cell_17243/D wl_0_0 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_17090 wrom2_rom_base_one_cell_17243/D wrom2_rom_base_one_cell_17090/D wl_0_1 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_16931 wrom2_rom_base_one_cell_17090/D wrom2_rom_base_one_cell_16931/D wl_0_2 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_16776 wrom2_rom_base_one_cell_16931/D wrom2_rom_base_one_cell_16776/D wl_0_3 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_16307 wrom2_rom_base_one_cell_16776/D wrom2_rom_base_one_cell_16307/D wl_0_6 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_16159 wrom2_rom_base_one_cell_16307/D wrom2_rom_base_one_cell_16159/D wl_0_7 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_15998 wrom2_rom_base_one_cell_16159/D wrom2_rom_base_one_cell_15998/D wl_0_8 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_15847 wrom2_rom_base_one_cell_15998/D wrom2_rom_base_one_cell_15847/D wl_0_9 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_15187 wrom2_rom_base_one_cell_15847/D wrom2_rom_base_one_cell_15187/D wl_0_13 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_15013 wrom2_rom_base_one_cell_15187/D wrom2_rom_base_one_cell_15013/D wl_0_14 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_14701 wrom2_rom_base_one_cell_15013/D wrom2_rom_base_one_cell_14701/D wl_0_16 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_14515 wrom2_rom_base_one_cell_14701/D wrom2_rom_base_one_cell_14515/D wl_0_17 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_14030 wrom2_rom_base_one_cell_14515/D wrom2_rom_base_one_cell_14030/D wl_0_20 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_13872 wrom2_rom_base_one_cell_14030/D wrom2_rom_base_one_cell_13872/D wl_0_21 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_13536 wrom2_rom_base_one_cell_13872/D wrom2_rom_base_one_cell_13536/D wl_0_23 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_13206 wrom2_rom_base_one_cell_13536/D wrom2_rom_base_one_cell_13206/D wl_0_25 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_13037 wrom2_rom_base_one_cell_13206/D wrom2_rom_base_one_cell_13037/D wl_0_26 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_12902 wrom2_rom_base_one_cell_13037/D wrom2_rom_base_one_cell_12902/D wl_0_27 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_12743 wrom2_rom_base_one_cell_12902/D wrom2_rom_base_one_cell_12743/D wl_0_28 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_12283 wrom2_rom_base_one_cell_12743/D wrom2_rom_base_one_cell_12283/D wl_0_31 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_12140 wrom2_rom_base_one_cell_12283/D wrom2_rom_base_one_cell_12140/D wl_0_32 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_11993 wrom2_rom_base_one_cell_12140/D wrom2_rom_base_one_cell_11993/D wl_0_33 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_11343 wrom2_rom_base_one_cell_11993/D wrom2_rom_base_one_cell_11343/D wl_0_37 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_11184 wrom2_rom_base_one_cell_11343/D wrom2_rom_base_one_cell_11184/D wl_0_38 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_10699 wrom2_rom_base_one_cell_11184/D wrom2_rom_base_one_cell_10699/D wl_0_41 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_10517 wrom2_rom_base_one_cell_10699/D wrom2_rom_base_zero_cell_9905/S wl_0_42 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_10074 wrom2_rom_base_zero_cell_9905/S wrom2_rom_base_one_cell_9914/S wl_0_45 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_9914 wrom2_rom_base_one_cell_9914/S wrom2_rom_base_one_cell_9914/D wl_0_46 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_9580 wrom2_rom_base_one_cell_9914/D wrom2_rom_base_one_cell_9580/D wl_0_48 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_9421 wrom2_rom_base_one_cell_9580/D wrom2_rom_base_one_cell_9421/D wl_0_49 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_9296 wrom2_rom_base_one_cell_9421/D wrom2_rom_base_one_cell_9296/D wl_0_50 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_9136 wrom2_rom_base_one_cell_9296/D wrom2_rom_base_one_cell_9136/D wl_0_51 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_8684 wrom2_rom_base_one_cell_9136/D wrom2_rom_base_one_cell_8684/D wl_0_54 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_8520 wrom2_rom_base_one_cell_8684/D wrom2_rom_base_one_cell_8520/D wl_0_55 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_8352 wrom2_rom_base_one_cell_8520/D wrom2_rom_base_one_cell_8352/D wl_0_56 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_8182 wrom2_rom_base_one_cell_8352/D wrom2_rom_base_one_cell_8182/D wl_0_57 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_8034 wrom2_rom_base_one_cell_8182/D wrom2_rom_base_one_cell_8034/D wl_0_58 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_7855 wrom2_rom_base_one_cell_8034/D wrom2_rom_base_one_cell_7855/D wl_0_59 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_7533 wrom2_rom_base_one_cell_7855/D wrom2_rom_base_one_cell_7533/D wl_0_61 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_7219 wrom2_rom_base_one_cell_7533/D wrom2_rom_base_one_cell_7219/D wl_0_63 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_6874 wrom2_rom_base_one_cell_7219/D wrom2_rom_base_one_cell_6874/D wl_0_65 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_6711 wrom2_rom_base_one_cell_6874/D wrom2_rom_base_one_cell_6711/D wl_0_66 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_6538 wrom2_rom_base_one_cell_6711/D wrom2_rom_base_one_cell_6538/D wl_0_67 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_6380 wrom2_rom_base_one_cell_6538/D wrom2_rom_base_one_cell_6380/D wl_0_68 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_6063 wrom2_rom_base_one_cell_6380/D wrom2_rom_base_one_cell_6063/D wl_0_70 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_5887 wrom2_rom_base_one_cell_6063/D wrom2_rom_base_one_cell_5887/D wl_0_71 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_5726 wrom2_rom_base_one_cell_5887/D wrom2_rom_base_one_cell_5726/D wl_0_72 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_5577 wrom2_rom_base_one_cell_5726/D wrom2_rom_base_one_cell_5577/D wl_0_73 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_5403 wrom2_rom_base_one_cell_5577/D wrom2_rom_base_one_cell_5403/D wl_0_74 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_4941 wrom2_rom_base_one_cell_5403/D wrom2_rom_base_one_cell_4941/D wl_0_77 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_4626 wrom2_rom_base_one_cell_4941/D wrom2_rom_base_one_cell_4626/D wl_0_79 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_4450 wrom2_rom_base_one_cell_4626/D wrom2_rom_base_one_cell_4450/D wl_0_80 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_4137 wrom2_rom_base_one_cell_4450/D wrom2_rom_base_one_cell_4137/D wl_0_82 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_3808 wrom2_rom_base_one_cell_4137/D wrom2_rom_base_one_cell_3808/D wl_0_84 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_3645 wrom2_rom_base_one_cell_3808/D wrom2_rom_base_one_cell_3645/D wl_0_85 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_3488 wrom2_rom_base_one_cell_3645/D wrom2_rom_base_one_cell_3488/D wl_0_86 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_2987 wrom2_rom_base_one_cell_3488/D wrom2_rom_base_one_cell_2987/D wl_0_89 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_2517 wrom2_rom_base_one_cell_2987/D wrom2_rom_base_one_cell_2517/D wl_0_92 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_2363 wrom2_rom_base_one_cell_2517/D wrom2_rom_base_one_cell_2363/D wl_0_93 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_2177 wrom2_rom_base_one_cell_2363/D wrom2_rom_base_one_cell_2177/D wl_0_94 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_2012 wrom2_rom_base_one_cell_2177/D wrom2_rom_base_one_cell_2012/D wl_0_95 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_1869 wrom2_rom_base_one_cell_2012/D wrom2_rom_base_one_cell_1869/D wl_0_96 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_1576 wrom2_rom_base_one_cell_1869/D wrom2_rom_base_one_cell_1576/D wl_0_98 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_1254 wrom2_rom_base_one_cell_1576/D wrom2_rom_base_one_cell_1254/D wl_0_100 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_1091 wrom2_rom_base_one_cell_1254/D wrom2_rom_base_one_cell_941/S wl_0_101 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_941 wrom2_rom_base_one_cell_941/S wrom2_rom_base_one_cell_941/D wl_0_102 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_775 wrom2_rom_base_one_cell_941/D wrom2_rom_base_one_cell_775/D wl_0_103 gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_one_cell_277 wrom2_rom_base_one_cell_775/D gnd_uq0 precharge gnd wrom2_rom_base_one_cell
Xwrom2_rom_base_zero_cell_16300 wrom2_rom_base_one_cell_16776/D wl_0_4 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_16139 wrom2_rom_base_one_cell_16776/D wl_0_5 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_15010 wrom2_rom_base_one_cell_15847/D wl_0_12 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_15188 wrom2_rom_base_one_cell_15847/D wl_0_11 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_15326 wrom2_rom_base_one_cell_15847/D wl_0_10 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_14542 wrom2_rom_base_one_cell_15013/D wl_0_15 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_13933 wrom2_rom_base_one_cell_14515/D wl_0_19 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_14077 wrom2_rom_base_one_cell_14515/D wl_0_18 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_13448 wrom2_rom_base_one_cell_13872/D wl_0_22 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_13145 wrom2_rom_base_one_cell_13536/D wl_0_24 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_12162 wrom2_rom_base_one_cell_12743/D wl_0_30 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_12323 wrom2_rom_base_one_cell_12743/D wl_0_29 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_11179 wrom2_rom_base_one_cell_11993/D wl_0_36 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_11319 wrom2_rom_base_one_cell_11993/D wl_0_35 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_11484 wrom2_rom_base_one_cell_11993/D wl_0_34 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_10709 wrom2_rom_base_one_cell_11184/D wl_0_39 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_10536 wrom2_rom_base_one_cell_11184/D wl_0_40 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_9905 wrom2_rom_base_zero_cell_9905/S wl_0_44 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_10080 wrom2_rom_base_zero_cell_9905/S wl_0_43 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_9408 wrom2_rom_base_one_cell_9914/D wl_0_47 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_8588 wrom2_rom_base_one_cell_9136/D wl_0_52 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_8403 wrom2_rom_base_one_cell_9136/D wl_0_53 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_7311 wrom2_rom_base_one_cell_7855/D wl_0_60 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_6980 wrom2_rom_base_one_cell_7533/D wl_0_62 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_6672 wrom2_rom_base_one_cell_7219/D wl_0_64 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_5892 wrom2_rom_base_one_cell_6380/D wl_0_69 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_4932 wrom2_rom_base_one_cell_5403/D wl_0_75 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_4762 wrom2_rom_base_one_cell_5403/D wl_0_76 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_4446 wrom2_rom_base_one_cell_4941/D wl_0_78 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_3986 wrom2_rom_base_one_cell_4450/D wl_0_81 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_3660 wrom2_rom_base_one_cell_4137/D wl_0_83 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_3047 wrom2_rom_base_one_cell_3488/D wl_0_87 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_2891 wrom2_rom_base_one_cell_3488/D wl_0_88 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_2402 wrom2_rom_base_one_cell_2987/D wl_0_91 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_2564 wrom2_rom_base_one_cell_2987/D wl_0_90 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_1432 wrom2_rom_base_one_cell_1869/D wl_0_97 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_1105 wrom2_rom_base_one_cell_1576/D wl_0_99 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_302 wrom2_rom_base_one_cell_775/D wl_0_104 gnd wrom2_rom_base_zero_cell
Xwrom2_rom_base_zero_cell_143 wrom2_rom_base_one_cell_775/D wl_0_105 gnd wrom2_rom_base_zero_cell
.subckt wrom2_rom_base_one_cell S D G gnd
X0 D G S gnd sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.108u ps=1.32 w=0.36 l=0.15
C0 S D 0.04533f
C1 G D 0.00394f
C2 G S 0.00394f
C3 S gnd 0.05671f
C4 D gnd 0.09245f
C5 G gnd 0.10004f
.ends
.subckt wrom2_rom_base_zero_cell S G gnd
X0 S G S gnd sky130_fd_pr__special_nfet_01v8 ad=0.108u pd=1.32 as=0.216u ps=2.64 w=0.36 l=0.15
C0 G S 0.01098f
C1 S gnd 0.169f
C2 G gnd 0.10004f
.ends
.subckt wrom2_precharge_cell D G vdd gnd
X0 D G vdd vdd sky130_fd_pr__pfet_01v8 ad=0.126u pd=1.44 as=0.126u ps=1.44 w=0.42 l=0.15
C0 D G 0.00394f
C1 vdd G 0.05763f
C2 vdd D 0.03592f
C3 D gnd 0.05546f
C4 G gnd 0.03904f
C5 vdd gnd 0.33982f
.ends
.subckt wrom2_pinv_dec_3 gnd vdd w_692_n79# A Z
X0 vdd A Z w_692_n79# sky130_fd_pr__pfet_01v8 ad=1.5u pd=10.6 as=1.5u ps=10.6 w=5 l=0.15
X1 gnd A Z gnd sky130_fd_pr__nfet_01v8 ad=0.504u pd=3.96 as=0.504u ps=3.96 w=1.68 l=0.15
C0 w_692_n79# A 0.10891f
C1 vdd Z 0.06954f
C2 Z A 0.04991f
C3 vdd A 0.01892f
C4 Z w_692_n79# 0.05333f
C5 vdd w_692_n79# 0.02783f
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
