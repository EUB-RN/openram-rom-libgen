*FIRST LINE IS A COMMENT

* spice ptx X{0} {1} sky130_fd_pr__pfet_01v8 m=1 w=3.0 l=0.15 pd=6.30 ps=6.30 as=1.12u ad=1.12u

* spice ptx X{0} {1} sky130_fd_pr__nfet_01v8 m=1 w=0.74 l=0.15 pd=1.78 ps=1.78 as=0.28u ad=0.28u

.SUBCKT rom_256b_inv_array_mod
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* size: 1.9600000000000002
Xpinv_pmos Z A vdd vdd sky130_fd_pr__pfet_01v8 m=1 w=3.0u l=0.15u
Xpinv_nmos Z A gnd gnd sky130_fd_pr__nfet_01v8 m=1 w=0.74u l=0.15u
.ENDS rom_256b_inv_array_mod
* Copyright 2020 The SkyWater PDK Authors
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     https://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
* SPDX-License-Identifier: Apache-2.0

* NGSPICE file created from sky130_fd_bd_sram__openram_sp_nand2_dec.ext - technology: EFS8A


* Top level circuit sky130_fd_bd_sram__openram_sp_nand2_dec
.subckt sky130_fd_bd_sram__openram_sp_nand2_dec A B Z VDD GND

X1001 Z B VDD VDD sky130_fd_pr__pfet_01v8 W=1.12u L=0.15u m=1
X1002 VDD A Z VDD sky130_fd_pr__pfet_01v8 W=1.12u L=0.15u m=1
X1000 Z A a_n722_276# GND sky130_fd_pr__nfet_01v8 W=0.74u L=0.15u m=1
X1003 a_n722_276# B GND GND sky130_fd_pr__nfet_01v8 W=0.74u L=0.15u m=1
.ends


.SUBCKT rom_256b_rom_address_control_buf
+ A_in A_out Abar_out clk vdd gnd
* INPUT : A_in 
* INOUT : A_out 
* OUTPUT: Abar_out 
* INPUT : clk 
* POWER : vdd 
* GROUND: gnd 
XXinvAbar
+ A_in Abar_internal vdd gnd
+ rom_256b_inv_array_mod
XXnand_addr
+ clk Abar_internal A_out vdd gnd
+ sky130_fd_bd_sram__openram_sp_nand2_dec
XXnand_addr_bar
+ clk A_out Abar_out vdd gnd
+ sky130_fd_bd_sram__openram_sp_nand2_dec
.ENDS rom_256b_rom_address_control_buf

.SUBCKT rom_256b_rom_address_control_array
+ A0_in A1_in A2_in A0_out A1_out A2_out Abar0_out Abar1_out Abar2_out
+ clk vdd gnd
* INPUT : A0_in 
* INPUT : A1_in 
* INPUT : A2_in 
* OUTPUT: A0_out 
* OUTPUT: A1_out 
* OUTPUT: A2_out 
* OUTPUT: Abar0_out 
* OUTPUT: Abar1_out 
* OUTPUT: Abar2_out 
* INPUT : clk 
* POWER : vdd 
* GROUND: gnd 
XXaddr_buf_0
+ A0_in A0_out Abar0_out clk vdd gnd
+ rom_256b_rom_address_control_buf
XXaddr_buf_1
+ A1_in A1_out Abar1_out clk vdd gnd
+ rom_256b_rom_address_control_buf
XXaddr_buf_2
+ A2_in A2_out Abar2_out clk vdd gnd
+ rom_256b_rom_address_control_buf
.ENDS rom_256b_rom_address_control_array

* spice ptx X{0} {1} sky130_fd_pr__pfet_01v8 m=1 w=0.42 l=0.15 pd=1.14 ps=1.14 as=0.16u ad=0.16u

.SUBCKT rom_256b_precharge_cell
+ vdd gate bitline
* POWER : vdd 
* INPUT : gate 
* OUTPUT: bitline 
Xprecharge_pmos bitline gate vdd vdd sky130_fd_pr__pfet_01v8 m=1 w=0.42u l=0.15u
.ENDS rom_256b_precharge_cell

.SUBCKT rom_256b_rom_precharge_array_0
+ pre_bl0_out pre_bl1_out pre_bl2_out pre_bl3_out pre_bl4_out
+ pre_bl5_out pre_bl6_out pre_bl7_out gate vdd
* OUTPUT: pre_bl0_out 
* OUTPUT: pre_bl1_out 
* OUTPUT: pre_bl2_out 
* OUTPUT: pre_bl3_out 
* OUTPUT: pre_bl4_out 
* OUTPUT: pre_bl5_out 
* OUTPUT: pre_bl6_out 
* OUTPUT: pre_bl7_out 
* INPUT : gate 
* POWER : vdd 
Xpmos_c0
+ vdd gate pre_bl0_out
+ rom_256b_precharge_cell
Xpmos_c1
+ vdd gate pre_bl1_out
+ rom_256b_precharge_cell
Xpmos_c2
+ vdd gate pre_bl2_out
+ rom_256b_precharge_cell
Xpmos_c3
+ vdd gate pre_bl3_out
+ rom_256b_precharge_cell
Xpmos_c4
+ vdd gate pre_bl4_out
+ rom_256b_precharge_cell
Xpmos_c5
+ vdd gate pre_bl5_out
+ rom_256b_precharge_cell
Xpmos_c6
+ vdd gate pre_bl6_out
+ rom_256b_precharge_cell
Xpmos_c7
+ vdd gate pre_bl7_out
+ rom_256b_precharge_cell
.ENDS rom_256b_rom_precharge_array_0

* spice ptx X{0} {1} sky130_fd_pr__nfet_01v8 m=1 w=0.36 l=0.15 pd=1.02 ps=1.02 as=0.14u ad=0.14u

.SUBCKT rom_256b_rom_base_one_cell
+ bl_h bl_l wl gnd
* INOUT : bl_h 
* INOUT : bl_l 
* INPUT : wl 
* GROUND: gnd 
Xrom_256b_rom_base_one_cell_nmos bl_h wl bl_l gnd sky130_fd_pr__nfet_01v8 m=1 w=0.36u l=0.15u
.ENDS rom_256b_rom_base_one_cell

.SUBCKT rom_256b_rom_base_zero_cell
+ bl wl gnd
* INOUT : bl 
* INPUT : wl 
* GROUND: gnd 
Xrom_256b_rom_base_zero_cell_nmos bl wl bl gnd sky130_fd_pr__nfet_01v8 m=1 w=0.36u l=0.15u
.ENDS rom_256b_rom_base_zero_cell

.SUBCKT rom_256b_rom_row_decode_array
+ bl_0_0 bl_0_1 bl_0_2 bl_0_3 bl_0_4 bl_0_5 bl_0_6 bl_0_7 wl_0_0 wl_0_1
+ wl_0_2 wl_0_3 wl_0_4 wl_0_5 precharge vdd gnd
* OUTPUT: bl_0_0 
* OUTPUT: bl_0_1 
* OUTPUT: bl_0_2 
* OUTPUT: bl_0_3 
* OUTPUT: bl_0_4 
* OUTPUT: bl_0_5 
* OUTPUT: bl_0_6 
* OUTPUT: bl_0_7 
* INPUT : wl_0_0 
* INPUT : wl_0_1 
* INPUT : wl_0_2 
* INPUT : wl_0_3 
* INPUT : wl_0_4 
* INPUT : wl_0_5 
* INPUT : precharge 
* POWER : vdd 
* GROUND: gnd 
Xbit_r0_c0
+ bl_int_0_0 bl_0_0 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c1
+ bl_int_0_1 bl_0_1 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c2
+ bl_int_0_2 bl_0_2 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c3
+ bl_int_0_3 bl_0_3 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c4
+ bl_0_4 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c5
+ bl_0_5 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c6
+ bl_0_6 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c7
+ bl_0_7 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c0
+ bl_int_0_0 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c1
+ bl_int_0_1 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c2
+ bl_int_0_2 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c3
+ bl_int_0_3 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c4
+ bl_int_1_4 bl_0_4 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c5
+ bl_int_1_5 bl_0_5 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c6
+ bl_int_1_6 bl_0_6 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c7
+ bl_int_1_7 bl_0_7 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c0
+ bl_int_2_0 bl_int_0_0 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c1
+ bl_int_2_1 bl_int_0_1 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c2
+ bl_int_0_2 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c3
+ bl_int_0_3 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c4
+ bl_int_2_4 bl_int_1_4 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c5
+ bl_int_2_5 bl_int_1_5 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c6
+ bl_int_1_6 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c7
+ bl_int_1_7 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c0
+ bl_int_2_0 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c1
+ bl_int_2_1 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c2
+ bl_int_3_2 bl_int_0_2 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c3
+ bl_int_3_3 bl_int_0_3 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c4
+ bl_int_2_4 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c5
+ bl_int_2_5 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c6
+ bl_int_3_6 bl_int_1_6 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c7
+ bl_int_3_7 bl_int_1_7 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c0
+ bl_int_4_0 bl_int_2_0 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c1
+ bl_int_2_1 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c2
+ bl_int_4_2 bl_int_3_2 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c3
+ bl_int_3_3 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c4
+ bl_int_4_4 bl_int_2_4 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c5
+ bl_int_2_5 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c6
+ bl_int_4_6 bl_int_3_6 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c7
+ bl_int_3_7 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c0
+ bl_int_4_0 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c1
+ bl_int_5_1 bl_int_2_1 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c2
+ bl_int_4_2 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c3
+ bl_int_5_3 bl_int_3_3 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c4
+ bl_int_4_4 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c5
+ bl_int_5_5 bl_int_2_5 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c6
+ bl_int_4_6 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c7
+ bl_int_5_7 bl_int_3_7 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c0
+ gnd bl_int_4_0 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c1
+ gnd bl_int_5_1 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c2
+ gnd bl_int_4_2 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c3
+ gnd bl_int_5_3 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c4
+ gnd bl_int_4_4 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c5
+ gnd bl_int_5_5 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c6
+ gnd bl_int_4_6 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c7
+ gnd bl_int_5_7 precharge gnd
+ rom_256b_rom_base_one_cell
Xbitcell_array_precharge
+ bl_0_0 bl_0_1 bl_0_2 bl_0_3 bl_0_4 bl_0_5 bl_0_6 bl_0_7 precharge vdd
+ rom_256b_rom_precharge_array_0
.ENDS rom_256b_rom_row_decode_array

* spice ptx X{0} {1} sky130_fd_pr__nfet_01v8 m=1 w=7.0 l=0.15 pd=14.30 ps=14.30 as=2.62u ad=2.62u

* spice ptx X{0} {1} sky130_fd_pr__pfet_01v8 m=1 w=7.0 l=0.15 pd=14.30 ps=14.30 as=2.62u ad=2.62u

.SUBCKT rom_256b_pinv_dec_1
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* size: 32
Xpinv_pmos Z A vdd vdd sky130_fd_pr__pfet_01v8 m=1 w=7.0u l=0.15u
Xpinv_nmos Z A gnd gnd sky130_fd_pr__nfet_01v8 m=1 w=7.0u l=0.15u
.ENDS rom_256b_pinv_dec_1

* spice ptx X{0} {1} sky130_fd_pr__nfet_01v8 m=1 w=3.0 l=0.15 pd=6.30 ps=6.30 as=1.12u ad=1.12u

.SUBCKT rom_256b_pinv_dec_0
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* size: 8
Xpinv_pmos Z A vdd vdd sky130_fd_pr__pfet_01v8 m=1 w=7.0u l=0.15u
Xpinv_nmos Z A gnd gnd sky130_fd_pr__nfet_01v8 m=1 w=3.0u l=0.15u
.ENDS rom_256b_pinv_dec_0

.SUBCKT rom_256b_pbuf_dec
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* size: 32
Xbuf_inv1
+ A zb_int vdd gnd
+ rom_256b_pinv_dec_0
Xbuf_inv2
+ zb_int Z vdd gnd
+ rom_256b_pinv_dec_1
.ENDS rom_256b_pbuf_dec

.SUBCKT rom_256b_rom_row_decode_wordline_buffer
+ in_0 in_1 in_2 in_3 in_4 in_5 in_6 in_7 out_0 out_1 out_2 out_3 out_4
+ out_5 out_6 out_7 vdd gnd
* INPUT : in_0 
* INPUT : in_1 
* INPUT : in_2 
* INPUT : in_3 
* INPUT : in_4 
* INPUT : in_5 
* INPUT : in_6 
* INPUT : in_7 
* OUTPUT: out_0 
* OUTPUT: out_1 
* OUTPUT: out_2 
* OUTPUT: out_3 
* OUTPUT: out_4 
* OUTPUT: out_5 
* OUTPUT: out_6 
* OUTPUT: out_7 
* POWER : vdd 
* GROUND: gnd 
* rows: 8 Buffer size of: 32
Xwld0
+ in_0 out_0 vdd gnd
+ rom_256b_pbuf_dec
Xwld1
+ in_1 out_1 vdd gnd
+ rom_256b_pbuf_dec
Xwld2
+ in_2 out_2 vdd gnd
+ rom_256b_pbuf_dec
Xwld3
+ in_3 out_3 vdd gnd
+ rom_256b_pbuf_dec
Xwld4
+ in_4 out_4 vdd gnd
+ rom_256b_pbuf_dec
Xwld5
+ in_5 out_5 vdd gnd
+ rom_256b_pbuf_dec
Xwld6
+ in_6 out_6 vdd gnd
+ rom_256b_pbuf_dec
Xwld7
+ in_7 out_7 vdd gnd
+ rom_256b_pbuf_dec
.ENDS rom_256b_rom_row_decode_wordline_buffer

.SUBCKT rom_256b_rom_row_decode
+ A0 A1 A2 wl_0 wl_1 wl_2 wl_3 wl_4 wl_5 wl_6 wl_7 precharge clk vdd gnd
* INPUT : A0 
* INPUT : A1 
* INPUT : A2 
* OUTPUT: wl_0 
* OUTPUT: wl_1 
* OUTPUT: wl_2 
* OUTPUT: wl_3 
* OUTPUT: wl_4 
* OUTPUT: wl_5 
* OUTPUT: wl_6 
* OUTPUT: wl_7 
* INPUT : precharge 
* INPUT : clk 
* POWER : vdd 
* GROUND: gnd 
Xdecode_array_inst
+ wl_int0 wl_int1 wl_int2 wl_int3 wl_int4 wl_int5 wl_int6 wl_int7
+ Ab_int_2 A_int_2 Ab_int_1 A_int_1 Ab_int_0 A_int_0 precharge vdd gnd
+ rom_256b_rom_row_decode_array
Xpre_control_array
+ A0 A1 A2 A_int_0 A_int_1 A_int_2 Ab_int_0 Ab_int_1 Ab_int_2 clk vdd
+ gnd
+ rom_256b_rom_address_control_array
Xrom_wordline_driver
+ wl_int0 wl_int1 wl_int2 wl_int3 wl_int4 wl_int5 wl_int6 wl_int7 wl_0
+ wl_1 wl_2 wl_3 wl_4 wl_5 wl_6 wl_7 vdd gnd
+ rom_256b_rom_row_decode_wordline_buffer
.ENDS rom_256b_rom_row_decode

* spice ptx X{0} {1} sky130_fd_pr__pfet_01v8 m=1 w=5.0 l=0.15 pd=10.30 ps=10.30 as=1.88u ad=1.88u

* spice ptx X{0} {1} sky130_fd_pr__nfet_01v8 m=1 w=1.68 l=0.15 pd=3.66 ps=3.66 as=0.63u ad=0.63u

.SUBCKT rom_256b_pinv_dec_3
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* size: 4
Xpinv_pmos Z A vdd vdd sky130_fd_pr__pfet_01v8 m=1 w=5.0u l=0.15u
Xpinv_nmos Z A gnd gnd sky130_fd_pr__nfet_01v8 m=1 w=1.68u l=0.15u
.ENDS rom_256b_pinv_dec_3

.SUBCKT rom_256b_rom_bitline_inverter
+ in_0 in_1 in_2 in_3 in_4 in_5 in_6 in_7 in_8 in_9 in_10 in_11 in_12
+ in_13 in_14 in_15 in_16 in_17 in_18 in_19 in_20 in_21 in_22 in_23
+ in_24 in_25 in_26 in_27 in_28 in_29 in_30 in_31 in_32 in_33 in_34
+ in_35 in_36 in_37 in_38 in_39 in_40 in_41 in_42 in_43 in_44 in_45
+ in_46 in_47 in_48 in_49 in_50 in_51 in_52 in_53 in_54 in_55 in_56
+ in_57 in_58 in_59 in_60 in_61 in_62 in_63 in_64 in_65 in_66 in_67
+ in_68 in_69 in_70 in_71 in_72 in_73 in_74 in_75 in_76 in_77 in_78
+ in_79 in_80 in_81 in_82 in_83 in_84 in_85 in_86 in_87 in_88 in_89
+ in_90 in_91 in_92 in_93 in_94 in_95 in_96 in_97 in_98 in_99 in_100
+ in_101 in_102 in_103 in_104 in_105 in_106 in_107 in_108 in_109 in_110
+ in_111 in_112 in_113 in_114 in_115 in_116 in_117 in_118 in_119 in_120
+ in_121 in_122 in_123 in_124 in_125 in_126 in_127 in_128 in_129 in_130
+ in_131 in_132 in_133 in_134 in_135 in_136 in_137 in_138 in_139 in_140
+ in_141 in_142 in_143 in_144 in_145 in_146 in_147 in_148 in_149 in_150
+ in_151 in_152 in_153 in_154 in_155 in_156 in_157 in_158 in_159 in_160
+ in_161 in_162 in_163 in_164 in_165 in_166 in_167 in_168 in_169 in_170
+ in_171 in_172 in_173 in_174 in_175 in_176 in_177 in_178 in_179 in_180
+ in_181 in_182 in_183 in_184 in_185 in_186 in_187 in_188 in_189 in_190
+ in_191 in_192 in_193 in_194 in_195 in_196 in_197 in_198 in_199 in_200
+ in_201 in_202 in_203 in_204 in_205 in_206 in_207 in_208 in_209 in_210
+ in_211 in_212 in_213 in_214 in_215 in_216 in_217 in_218 in_219 in_220
+ in_221 in_222 in_223 in_224 in_225 in_226 in_227 in_228 in_229 in_230
+ in_231 in_232 in_233 in_234 in_235 in_236 in_237 in_238 in_239 in_240
+ in_241 in_242 in_243 in_244 in_245 in_246 in_247 in_248 in_249 in_250
+ in_251 in_252 in_253 in_254 in_255 out_0 out_1 out_2 out_3 out_4 out_5
+ out_6 out_7 out_8 out_9 out_10 out_11 out_12 out_13 out_14 out_15
+ out_16 out_17 out_18 out_19 out_20 out_21 out_22 out_23 out_24 out_25
+ out_26 out_27 out_28 out_29 out_30 out_31 out_32 out_33 out_34 out_35
+ out_36 out_37 out_38 out_39 out_40 out_41 out_42 out_43 out_44 out_45
+ out_46 out_47 out_48 out_49 out_50 out_51 out_52 out_53 out_54 out_55
+ out_56 out_57 out_58 out_59 out_60 out_61 out_62 out_63 out_64 out_65
+ out_66 out_67 out_68 out_69 out_70 out_71 out_72 out_73 out_74 out_75
+ out_76 out_77 out_78 out_79 out_80 out_81 out_82 out_83 out_84 out_85
+ out_86 out_87 out_88 out_89 out_90 out_91 out_92 out_93 out_94 out_95
+ out_96 out_97 out_98 out_99 out_100 out_101 out_102 out_103 out_104
+ out_105 out_106 out_107 out_108 out_109 out_110 out_111 out_112
+ out_113 out_114 out_115 out_116 out_117 out_118 out_119 out_120
+ out_121 out_122 out_123 out_124 out_125 out_126 out_127 out_128
+ out_129 out_130 out_131 out_132 out_133 out_134 out_135 out_136
+ out_137 out_138 out_139 out_140 out_141 out_142 out_143 out_144
+ out_145 out_146 out_147 out_148 out_149 out_150 out_151 out_152
+ out_153 out_154 out_155 out_156 out_157 out_158 out_159 out_160
+ out_161 out_162 out_163 out_164 out_165 out_166 out_167 out_168
+ out_169 out_170 out_171 out_172 out_173 out_174 out_175 out_176
+ out_177 out_178 out_179 out_180 out_181 out_182 out_183 out_184
+ out_185 out_186 out_187 out_188 out_189 out_190 out_191 out_192
+ out_193 out_194 out_195 out_196 out_197 out_198 out_199 out_200
+ out_201 out_202 out_203 out_204 out_205 out_206 out_207 out_208
+ out_209 out_210 out_211 out_212 out_213 out_214 out_215 out_216
+ out_217 out_218 out_219 out_220 out_221 out_222 out_223 out_224
+ out_225 out_226 out_227 out_228 out_229 out_230 out_231 out_232
+ out_233 out_234 out_235 out_236 out_237 out_238 out_239 out_240
+ out_241 out_242 out_243 out_244 out_245 out_246 out_247 out_248
+ out_249 out_250 out_251 out_252 out_253 out_254 out_255 vdd gnd
* INPUT : in_0 
* INPUT : in_1 
* INPUT : in_2 
* INPUT : in_3 
* INPUT : in_4 
* INPUT : in_5 
* INPUT : in_6 
* INPUT : in_7 
* INPUT : in_8 
* INPUT : in_9 
* INPUT : in_10 
* INPUT : in_11 
* INPUT : in_12 
* INPUT : in_13 
* INPUT : in_14 
* INPUT : in_15 
* INPUT : in_16 
* INPUT : in_17 
* INPUT : in_18 
* INPUT : in_19 
* INPUT : in_20 
* INPUT : in_21 
* INPUT : in_22 
* INPUT : in_23 
* INPUT : in_24 
* INPUT : in_25 
* INPUT : in_26 
* INPUT : in_27 
* INPUT : in_28 
* INPUT : in_29 
* INPUT : in_30 
* INPUT : in_31 
* INPUT : in_32 
* INPUT : in_33 
* INPUT : in_34 
* INPUT : in_35 
* INPUT : in_36 
* INPUT : in_37 
* INPUT : in_38 
* INPUT : in_39 
* INPUT : in_40 
* INPUT : in_41 
* INPUT : in_42 
* INPUT : in_43 
* INPUT : in_44 
* INPUT : in_45 
* INPUT : in_46 
* INPUT : in_47 
* INPUT : in_48 
* INPUT : in_49 
* INPUT : in_50 
* INPUT : in_51 
* INPUT : in_52 
* INPUT : in_53 
* INPUT : in_54 
* INPUT : in_55 
* INPUT : in_56 
* INPUT : in_57 
* INPUT : in_58 
* INPUT : in_59 
* INPUT : in_60 
* INPUT : in_61 
* INPUT : in_62 
* INPUT : in_63 
* INPUT : in_64 
* INPUT : in_65 
* INPUT : in_66 
* INPUT : in_67 
* INPUT : in_68 
* INPUT : in_69 
* INPUT : in_70 
* INPUT : in_71 
* INPUT : in_72 
* INPUT : in_73 
* INPUT : in_74 
* INPUT : in_75 
* INPUT : in_76 
* INPUT : in_77 
* INPUT : in_78 
* INPUT : in_79 
* INPUT : in_80 
* INPUT : in_81 
* INPUT : in_82 
* INPUT : in_83 
* INPUT : in_84 
* INPUT : in_85 
* INPUT : in_86 
* INPUT : in_87 
* INPUT : in_88 
* INPUT : in_89 
* INPUT : in_90 
* INPUT : in_91 
* INPUT : in_92 
* INPUT : in_93 
* INPUT : in_94 
* INPUT : in_95 
* INPUT : in_96 
* INPUT : in_97 
* INPUT : in_98 
* INPUT : in_99 
* INPUT : in_100 
* INPUT : in_101 
* INPUT : in_102 
* INPUT : in_103 
* INPUT : in_104 
* INPUT : in_105 
* INPUT : in_106 
* INPUT : in_107 
* INPUT : in_108 
* INPUT : in_109 
* INPUT : in_110 
* INPUT : in_111 
* INPUT : in_112 
* INPUT : in_113 
* INPUT : in_114 
* INPUT : in_115 
* INPUT : in_116 
* INPUT : in_117 
* INPUT : in_118 
* INPUT : in_119 
* INPUT : in_120 
* INPUT : in_121 
* INPUT : in_122 
* INPUT : in_123 
* INPUT : in_124 
* INPUT : in_125 
* INPUT : in_126 
* INPUT : in_127 
* INPUT : in_128 
* INPUT : in_129 
* INPUT : in_130 
* INPUT : in_131 
* INPUT : in_132 
* INPUT : in_133 
* INPUT : in_134 
* INPUT : in_135 
* INPUT : in_136 
* INPUT : in_137 
* INPUT : in_138 
* INPUT : in_139 
* INPUT : in_140 
* INPUT : in_141 
* INPUT : in_142 
* INPUT : in_143 
* INPUT : in_144 
* INPUT : in_145 
* INPUT : in_146 
* INPUT : in_147 
* INPUT : in_148 
* INPUT : in_149 
* INPUT : in_150 
* INPUT : in_151 
* INPUT : in_152 
* INPUT : in_153 
* INPUT : in_154 
* INPUT : in_155 
* INPUT : in_156 
* INPUT : in_157 
* INPUT : in_158 
* INPUT : in_159 
* INPUT : in_160 
* INPUT : in_161 
* INPUT : in_162 
* INPUT : in_163 
* INPUT : in_164 
* INPUT : in_165 
* INPUT : in_166 
* INPUT : in_167 
* INPUT : in_168 
* INPUT : in_169 
* INPUT : in_170 
* INPUT : in_171 
* INPUT : in_172 
* INPUT : in_173 
* INPUT : in_174 
* INPUT : in_175 
* INPUT : in_176 
* INPUT : in_177 
* INPUT : in_178 
* INPUT : in_179 
* INPUT : in_180 
* INPUT : in_181 
* INPUT : in_182 
* INPUT : in_183 
* INPUT : in_184 
* INPUT : in_185 
* INPUT : in_186 
* INPUT : in_187 
* INPUT : in_188 
* INPUT : in_189 
* INPUT : in_190 
* INPUT : in_191 
* INPUT : in_192 
* INPUT : in_193 
* INPUT : in_194 
* INPUT : in_195 
* INPUT : in_196 
* INPUT : in_197 
* INPUT : in_198 
* INPUT : in_199 
* INPUT : in_200 
* INPUT : in_201 
* INPUT : in_202 
* INPUT : in_203 
* INPUT : in_204 
* INPUT : in_205 
* INPUT : in_206 
* INPUT : in_207 
* INPUT : in_208 
* INPUT : in_209 
* INPUT : in_210 
* INPUT : in_211 
* INPUT : in_212 
* INPUT : in_213 
* INPUT : in_214 
* INPUT : in_215 
* INPUT : in_216 
* INPUT : in_217 
* INPUT : in_218 
* INPUT : in_219 
* INPUT : in_220 
* INPUT : in_221 
* INPUT : in_222 
* INPUT : in_223 
* INPUT : in_224 
* INPUT : in_225 
* INPUT : in_226 
* INPUT : in_227 
* INPUT : in_228 
* INPUT : in_229 
* INPUT : in_230 
* INPUT : in_231 
* INPUT : in_232 
* INPUT : in_233 
* INPUT : in_234 
* INPUT : in_235 
* INPUT : in_236 
* INPUT : in_237 
* INPUT : in_238 
* INPUT : in_239 
* INPUT : in_240 
* INPUT : in_241 
* INPUT : in_242 
* INPUT : in_243 
* INPUT : in_244 
* INPUT : in_245 
* INPUT : in_246 
* INPUT : in_247 
* INPUT : in_248 
* INPUT : in_249 
* INPUT : in_250 
* INPUT : in_251 
* INPUT : in_252 
* INPUT : in_253 
* INPUT : in_254 
* INPUT : in_255 
* OUTPUT: out_0 
* OUTPUT: out_1 
* OUTPUT: out_2 
* OUTPUT: out_3 
* OUTPUT: out_4 
* OUTPUT: out_5 
* OUTPUT: out_6 
* OUTPUT: out_7 
* OUTPUT: out_8 
* OUTPUT: out_9 
* OUTPUT: out_10 
* OUTPUT: out_11 
* OUTPUT: out_12 
* OUTPUT: out_13 
* OUTPUT: out_14 
* OUTPUT: out_15 
* OUTPUT: out_16 
* OUTPUT: out_17 
* OUTPUT: out_18 
* OUTPUT: out_19 
* OUTPUT: out_20 
* OUTPUT: out_21 
* OUTPUT: out_22 
* OUTPUT: out_23 
* OUTPUT: out_24 
* OUTPUT: out_25 
* OUTPUT: out_26 
* OUTPUT: out_27 
* OUTPUT: out_28 
* OUTPUT: out_29 
* OUTPUT: out_30 
* OUTPUT: out_31 
* OUTPUT: out_32 
* OUTPUT: out_33 
* OUTPUT: out_34 
* OUTPUT: out_35 
* OUTPUT: out_36 
* OUTPUT: out_37 
* OUTPUT: out_38 
* OUTPUT: out_39 
* OUTPUT: out_40 
* OUTPUT: out_41 
* OUTPUT: out_42 
* OUTPUT: out_43 
* OUTPUT: out_44 
* OUTPUT: out_45 
* OUTPUT: out_46 
* OUTPUT: out_47 
* OUTPUT: out_48 
* OUTPUT: out_49 
* OUTPUT: out_50 
* OUTPUT: out_51 
* OUTPUT: out_52 
* OUTPUT: out_53 
* OUTPUT: out_54 
* OUTPUT: out_55 
* OUTPUT: out_56 
* OUTPUT: out_57 
* OUTPUT: out_58 
* OUTPUT: out_59 
* OUTPUT: out_60 
* OUTPUT: out_61 
* OUTPUT: out_62 
* OUTPUT: out_63 
* OUTPUT: out_64 
* OUTPUT: out_65 
* OUTPUT: out_66 
* OUTPUT: out_67 
* OUTPUT: out_68 
* OUTPUT: out_69 
* OUTPUT: out_70 
* OUTPUT: out_71 
* OUTPUT: out_72 
* OUTPUT: out_73 
* OUTPUT: out_74 
* OUTPUT: out_75 
* OUTPUT: out_76 
* OUTPUT: out_77 
* OUTPUT: out_78 
* OUTPUT: out_79 
* OUTPUT: out_80 
* OUTPUT: out_81 
* OUTPUT: out_82 
* OUTPUT: out_83 
* OUTPUT: out_84 
* OUTPUT: out_85 
* OUTPUT: out_86 
* OUTPUT: out_87 
* OUTPUT: out_88 
* OUTPUT: out_89 
* OUTPUT: out_90 
* OUTPUT: out_91 
* OUTPUT: out_92 
* OUTPUT: out_93 
* OUTPUT: out_94 
* OUTPUT: out_95 
* OUTPUT: out_96 
* OUTPUT: out_97 
* OUTPUT: out_98 
* OUTPUT: out_99 
* OUTPUT: out_100 
* OUTPUT: out_101 
* OUTPUT: out_102 
* OUTPUT: out_103 
* OUTPUT: out_104 
* OUTPUT: out_105 
* OUTPUT: out_106 
* OUTPUT: out_107 
* OUTPUT: out_108 
* OUTPUT: out_109 
* OUTPUT: out_110 
* OUTPUT: out_111 
* OUTPUT: out_112 
* OUTPUT: out_113 
* OUTPUT: out_114 
* OUTPUT: out_115 
* OUTPUT: out_116 
* OUTPUT: out_117 
* OUTPUT: out_118 
* OUTPUT: out_119 
* OUTPUT: out_120 
* OUTPUT: out_121 
* OUTPUT: out_122 
* OUTPUT: out_123 
* OUTPUT: out_124 
* OUTPUT: out_125 
* OUTPUT: out_126 
* OUTPUT: out_127 
* OUTPUT: out_128 
* OUTPUT: out_129 
* OUTPUT: out_130 
* OUTPUT: out_131 
* OUTPUT: out_132 
* OUTPUT: out_133 
* OUTPUT: out_134 
* OUTPUT: out_135 
* OUTPUT: out_136 
* OUTPUT: out_137 
* OUTPUT: out_138 
* OUTPUT: out_139 
* OUTPUT: out_140 
* OUTPUT: out_141 
* OUTPUT: out_142 
* OUTPUT: out_143 
* OUTPUT: out_144 
* OUTPUT: out_145 
* OUTPUT: out_146 
* OUTPUT: out_147 
* OUTPUT: out_148 
* OUTPUT: out_149 
* OUTPUT: out_150 
* OUTPUT: out_151 
* OUTPUT: out_152 
* OUTPUT: out_153 
* OUTPUT: out_154 
* OUTPUT: out_155 
* OUTPUT: out_156 
* OUTPUT: out_157 
* OUTPUT: out_158 
* OUTPUT: out_159 
* OUTPUT: out_160 
* OUTPUT: out_161 
* OUTPUT: out_162 
* OUTPUT: out_163 
* OUTPUT: out_164 
* OUTPUT: out_165 
* OUTPUT: out_166 
* OUTPUT: out_167 
* OUTPUT: out_168 
* OUTPUT: out_169 
* OUTPUT: out_170 
* OUTPUT: out_171 
* OUTPUT: out_172 
* OUTPUT: out_173 
* OUTPUT: out_174 
* OUTPUT: out_175 
* OUTPUT: out_176 
* OUTPUT: out_177 
* OUTPUT: out_178 
* OUTPUT: out_179 
* OUTPUT: out_180 
* OUTPUT: out_181 
* OUTPUT: out_182 
* OUTPUT: out_183 
* OUTPUT: out_184 
* OUTPUT: out_185 
* OUTPUT: out_186 
* OUTPUT: out_187 
* OUTPUT: out_188 
* OUTPUT: out_189 
* OUTPUT: out_190 
* OUTPUT: out_191 
* OUTPUT: out_192 
* OUTPUT: out_193 
* OUTPUT: out_194 
* OUTPUT: out_195 
* OUTPUT: out_196 
* OUTPUT: out_197 
* OUTPUT: out_198 
* OUTPUT: out_199 
* OUTPUT: out_200 
* OUTPUT: out_201 
* OUTPUT: out_202 
* OUTPUT: out_203 
* OUTPUT: out_204 
* OUTPUT: out_205 
* OUTPUT: out_206 
* OUTPUT: out_207 
* OUTPUT: out_208 
* OUTPUT: out_209 
* OUTPUT: out_210 
* OUTPUT: out_211 
* OUTPUT: out_212 
* OUTPUT: out_213 
* OUTPUT: out_214 
* OUTPUT: out_215 
* OUTPUT: out_216 
* OUTPUT: out_217 
* OUTPUT: out_218 
* OUTPUT: out_219 
* OUTPUT: out_220 
* OUTPUT: out_221 
* OUTPUT: out_222 
* OUTPUT: out_223 
* OUTPUT: out_224 
* OUTPUT: out_225 
* OUTPUT: out_226 
* OUTPUT: out_227 
* OUTPUT: out_228 
* OUTPUT: out_229 
* OUTPUT: out_230 
* OUTPUT: out_231 
* OUTPUT: out_232 
* OUTPUT: out_233 
* OUTPUT: out_234 
* OUTPUT: out_235 
* OUTPUT: out_236 
* OUTPUT: out_237 
* OUTPUT: out_238 
* OUTPUT: out_239 
* OUTPUT: out_240 
* OUTPUT: out_241 
* OUTPUT: out_242 
* OUTPUT: out_243 
* OUTPUT: out_244 
* OUTPUT: out_245 
* OUTPUT: out_246 
* OUTPUT: out_247 
* OUTPUT: out_248 
* OUTPUT: out_249 
* OUTPUT: out_250 
* OUTPUT: out_251 
* OUTPUT: out_252 
* OUTPUT: out_253 
* OUTPUT: out_254 
* OUTPUT: out_255 
* POWER : vdd 
* GROUND: gnd 
* rows: 256 Buffer size of: 4
Xwld0
+ in_0 out_0 vdd gnd
+ rom_256b_pinv_dec_3
Xwld1
+ in_1 out_1 vdd gnd
+ rom_256b_pinv_dec_3
Xwld2
+ in_2 out_2 vdd gnd
+ rom_256b_pinv_dec_3
Xwld3
+ in_3 out_3 vdd gnd
+ rom_256b_pinv_dec_3
Xwld4
+ in_4 out_4 vdd gnd
+ rom_256b_pinv_dec_3
Xwld5
+ in_5 out_5 vdd gnd
+ rom_256b_pinv_dec_3
Xwld6
+ in_6 out_6 vdd gnd
+ rom_256b_pinv_dec_3
Xwld7
+ in_7 out_7 vdd gnd
+ rom_256b_pinv_dec_3
Xwld8
+ in_8 out_8 vdd gnd
+ rom_256b_pinv_dec_3
Xwld9
+ in_9 out_9 vdd gnd
+ rom_256b_pinv_dec_3
Xwld10
+ in_10 out_10 vdd gnd
+ rom_256b_pinv_dec_3
Xwld11
+ in_11 out_11 vdd gnd
+ rom_256b_pinv_dec_3
Xwld12
+ in_12 out_12 vdd gnd
+ rom_256b_pinv_dec_3
Xwld13
+ in_13 out_13 vdd gnd
+ rom_256b_pinv_dec_3
Xwld14
+ in_14 out_14 vdd gnd
+ rom_256b_pinv_dec_3
Xwld15
+ in_15 out_15 vdd gnd
+ rom_256b_pinv_dec_3
Xwld16
+ in_16 out_16 vdd gnd
+ rom_256b_pinv_dec_3
Xwld17
+ in_17 out_17 vdd gnd
+ rom_256b_pinv_dec_3
Xwld18
+ in_18 out_18 vdd gnd
+ rom_256b_pinv_dec_3
Xwld19
+ in_19 out_19 vdd gnd
+ rom_256b_pinv_dec_3
Xwld20
+ in_20 out_20 vdd gnd
+ rom_256b_pinv_dec_3
Xwld21
+ in_21 out_21 vdd gnd
+ rom_256b_pinv_dec_3
Xwld22
+ in_22 out_22 vdd gnd
+ rom_256b_pinv_dec_3
Xwld23
+ in_23 out_23 vdd gnd
+ rom_256b_pinv_dec_3
Xwld24
+ in_24 out_24 vdd gnd
+ rom_256b_pinv_dec_3
Xwld25
+ in_25 out_25 vdd gnd
+ rom_256b_pinv_dec_3
Xwld26
+ in_26 out_26 vdd gnd
+ rom_256b_pinv_dec_3
Xwld27
+ in_27 out_27 vdd gnd
+ rom_256b_pinv_dec_3
Xwld28
+ in_28 out_28 vdd gnd
+ rom_256b_pinv_dec_3
Xwld29
+ in_29 out_29 vdd gnd
+ rom_256b_pinv_dec_3
Xwld30
+ in_30 out_30 vdd gnd
+ rom_256b_pinv_dec_3
Xwld31
+ in_31 out_31 vdd gnd
+ rom_256b_pinv_dec_3
Xwld32
+ in_32 out_32 vdd gnd
+ rom_256b_pinv_dec_3
Xwld33
+ in_33 out_33 vdd gnd
+ rom_256b_pinv_dec_3
Xwld34
+ in_34 out_34 vdd gnd
+ rom_256b_pinv_dec_3
Xwld35
+ in_35 out_35 vdd gnd
+ rom_256b_pinv_dec_3
Xwld36
+ in_36 out_36 vdd gnd
+ rom_256b_pinv_dec_3
Xwld37
+ in_37 out_37 vdd gnd
+ rom_256b_pinv_dec_3
Xwld38
+ in_38 out_38 vdd gnd
+ rom_256b_pinv_dec_3
Xwld39
+ in_39 out_39 vdd gnd
+ rom_256b_pinv_dec_3
Xwld40
+ in_40 out_40 vdd gnd
+ rom_256b_pinv_dec_3
Xwld41
+ in_41 out_41 vdd gnd
+ rom_256b_pinv_dec_3
Xwld42
+ in_42 out_42 vdd gnd
+ rom_256b_pinv_dec_3
Xwld43
+ in_43 out_43 vdd gnd
+ rom_256b_pinv_dec_3
Xwld44
+ in_44 out_44 vdd gnd
+ rom_256b_pinv_dec_3
Xwld45
+ in_45 out_45 vdd gnd
+ rom_256b_pinv_dec_3
Xwld46
+ in_46 out_46 vdd gnd
+ rom_256b_pinv_dec_3
Xwld47
+ in_47 out_47 vdd gnd
+ rom_256b_pinv_dec_3
Xwld48
+ in_48 out_48 vdd gnd
+ rom_256b_pinv_dec_3
Xwld49
+ in_49 out_49 vdd gnd
+ rom_256b_pinv_dec_3
Xwld50
+ in_50 out_50 vdd gnd
+ rom_256b_pinv_dec_3
Xwld51
+ in_51 out_51 vdd gnd
+ rom_256b_pinv_dec_3
Xwld52
+ in_52 out_52 vdd gnd
+ rom_256b_pinv_dec_3
Xwld53
+ in_53 out_53 vdd gnd
+ rom_256b_pinv_dec_3
Xwld54
+ in_54 out_54 vdd gnd
+ rom_256b_pinv_dec_3
Xwld55
+ in_55 out_55 vdd gnd
+ rom_256b_pinv_dec_3
Xwld56
+ in_56 out_56 vdd gnd
+ rom_256b_pinv_dec_3
Xwld57
+ in_57 out_57 vdd gnd
+ rom_256b_pinv_dec_3
Xwld58
+ in_58 out_58 vdd gnd
+ rom_256b_pinv_dec_3
Xwld59
+ in_59 out_59 vdd gnd
+ rom_256b_pinv_dec_3
Xwld60
+ in_60 out_60 vdd gnd
+ rom_256b_pinv_dec_3
Xwld61
+ in_61 out_61 vdd gnd
+ rom_256b_pinv_dec_3
Xwld62
+ in_62 out_62 vdd gnd
+ rom_256b_pinv_dec_3
Xwld63
+ in_63 out_63 vdd gnd
+ rom_256b_pinv_dec_3
Xwld64
+ in_64 out_64 vdd gnd
+ rom_256b_pinv_dec_3
Xwld65
+ in_65 out_65 vdd gnd
+ rom_256b_pinv_dec_3
Xwld66
+ in_66 out_66 vdd gnd
+ rom_256b_pinv_dec_3
Xwld67
+ in_67 out_67 vdd gnd
+ rom_256b_pinv_dec_3
Xwld68
+ in_68 out_68 vdd gnd
+ rom_256b_pinv_dec_3
Xwld69
+ in_69 out_69 vdd gnd
+ rom_256b_pinv_dec_3
Xwld70
+ in_70 out_70 vdd gnd
+ rom_256b_pinv_dec_3
Xwld71
+ in_71 out_71 vdd gnd
+ rom_256b_pinv_dec_3
Xwld72
+ in_72 out_72 vdd gnd
+ rom_256b_pinv_dec_3
Xwld73
+ in_73 out_73 vdd gnd
+ rom_256b_pinv_dec_3
Xwld74
+ in_74 out_74 vdd gnd
+ rom_256b_pinv_dec_3
Xwld75
+ in_75 out_75 vdd gnd
+ rom_256b_pinv_dec_3
Xwld76
+ in_76 out_76 vdd gnd
+ rom_256b_pinv_dec_3
Xwld77
+ in_77 out_77 vdd gnd
+ rom_256b_pinv_dec_3
Xwld78
+ in_78 out_78 vdd gnd
+ rom_256b_pinv_dec_3
Xwld79
+ in_79 out_79 vdd gnd
+ rom_256b_pinv_dec_3
Xwld80
+ in_80 out_80 vdd gnd
+ rom_256b_pinv_dec_3
Xwld81
+ in_81 out_81 vdd gnd
+ rom_256b_pinv_dec_3
Xwld82
+ in_82 out_82 vdd gnd
+ rom_256b_pinv_dec_3
Xwld83
+ in_83 out_83 vdd gnd
+ rom_256b_pinv_dec_3
Xwld84
+ in_84 out_84 vdd gnd
+ rom_256b_pinv_dec_3
Xwld85
+ in_85 out_85 vdd gnd
+ rom_256b_pinv_dec_3
Xwld86
+ in_86 out_86 vdd gnd
+ rom_256b_pinv_dec_3
Xwld87
+ in_87 out_87 vdd gnd
+ rom_256b_pinv_dec_3
Xwld88
+ in_88 out_88 vdd gnd
+ rom_256b_pinv_dec_3
Xwld89
+ in_89 out_89 vdd gnd
+ rom_256b_pinv_dec_3
Xwld90
+ in_90 out_90 vdd gnd
+ rom_256b_pinv_dec_3
Xwld91
+ in_91 out_91 vdd gnd
+ rom_256b_pinv_dec_3
Xwld92
+ in_92 out_92 vdd gnd
+ rom_256b_pinv_dec_3
Xwld93
+ in_93 out_93 vdd gnd
+ rom_256b_pinv_dec_3
Xwld94
+ in_94 out_94 vdd gnd
+ rom_256b_pinv_dec_3
Xwld95
+ in_95 out_95 vdd gnd
+ rom_256b_pinv_dec_3
Xwld96
+ in_96 out_96 vdd gnd
+ rom_256b_pinv_dec_3
Xwld97
+ in_97 out_97 vdd gnd
+ rom_256b_pinv_dec_3
Xwld98
+ in_98 out_98 vdd gnd
+ rom_256b_pinv_dec_3
Xwld99
+ in_99 out_99 vdd gnd
+ rom_256b_pinv_dec_3
Xwld100
+ in_100 out_100 vdd gnd
+ rom_256b_pinv_dec_3
Xwld101
+ in_101 out_101 vdd gnd
+ rom_256b_pinv_dec_3
Xwld102
+ in_102 out_102 vdd gnd
+ rom_256b_pinv_dec_3
Xwld103
+ in_103 out_103 vdd gnd
+ rom_256b_pinv_dec_3
Xwld104
+ in_104 out_104 vdd gnd
+ rom_256b_pinv_dec_3
Xwld105
+ in_105 out_105 vdd gnd
+ rom_256b_pinv_dec_3
Xwld106
+ in_106 out_106 vdd gnd
+ rom_256b_pinv_dec_3
Xwld107
+ in_107 out_107 vdd gnd
+ rom_256b_pinv_dec_3
Xwld108
+ in_108 out_108 vdd gnd
+ rom_256b_pinv_dec_3
Xwld109
+ in_109 out_109 vdd gnd
+ rom_256b_pinv_dec_3
Xwld110
+ in_110 out_110 vdd gnd
+ rom_256b_pinv_dec_3
Xwld111
+ in_111 out_111 vdd gnd
+ rom_256b_pinv_dec_3
Xwld112
+ in_112 out_112 vdd gnd
+ rom_256b_pinv_dec_3
Xwld113
+ in_113 out_113 vdd gnd
+ rom_256b_pinv_dec_3
Xwld114
+ in_114 out_114 vdd gnd
+ rom_256b_pinv_dec_3
Xwld115
+ in_115 out_115 vdd gnd
+ rom_256b_pinv_dec_3
Xwld116
+ in_116 out_116 vdd gnd
+ rom_256b_pinv_dec_3
Xwld117
+ in_117 out_117 vdd gnd
+ rom_256b_pinv_dec_3
Xwld118
+ in_118 out_118 vdd gnd
+ rom_256b_pinv_dec_3
Xwld119
+ in_119 out_119 vdd gnd
+ rom_256b_pinv_dec_3
Xwld120
+ in_120 out_120 vdd gnd
+ rom_256b_pinv_dec_3
Xwld121
+ in_121 out_121 vdd gnd
+ rom_256b_pinv_dec_3
Xwld122
+ in_122 out_122 vdd gnd
+ rom_256b_pinv_dec_3
Xwld123
+ in_123 out_123 vdd gnd
+ rom_256b_pinv_dec_3
Xwld124
+ in_124 out_124 vdd gnd
+ rom_256b_pinv_dec_3
Xwld125
+ in_125 out_125 vdd gnd
+ rom_256b_pinv_dec_3
Xwld126
+ in_126 out_126 vdd gnd
+ rom_256b_pinv_dec_3
Xwld127
+ in_127 out_127 vdd gnd
+ rom_256b_pinv_dec_3
Xwld128
+ in_128 out_128 vdd gnd
+ rom_256b_pinv_dec_3
Xwld129
+ in_129 out_129 vdd gnd
+ rom_256b_pinv_dec_3
Xwld130
+ in_130 out_130 vdd gnd
+ rom_256b_pinv_dec_3
Xwld131
+ in_131 out_131 vdd gnd
+ rom_256b_pinv_dec_3
Xwld132
+ in_132 out_132 vdd gnd
+ rom_256b_pinv_dec_3
Xwld133
+ in_133 out_133 vdd gnd
+ rom_256b_pinv_dec_3
Xwld134
+ in_134 out_134 vdd gnd
+ rom_256b_pinv_dec_3
Xwld135
+ in_135 out_135 vdd gnd
+ rom_256b_pinv_dec_3
Xwld136
+ in_136 out_136 vdd gnd
+ rom_256b_pinv_dec_3
Xwld137
+ in_137 out_137 vdd gnd
+ rom_256b_pinv_dec_3
Xwld138
+ in_138 out_138 vdd gnd
+ rom_256b_pinv_dec_3
Xwld139
+ in_139 out_139 vdd gnd
+ rom_256b_pinv_dec_3
Xwld140
+ in_140 out_140 vdd gnd
+ rom_256b_pinv_dec_3
Xwld141
+ in_141 out_141 vdd gnd
+ rom_256b_pinv_dec_3
Xwld142
+ in_142 out_142 vdd gnd
+ rom_256b_pinv_dec_3
Xwld143
+ in_143 out_143 vdd gnd
+ rom_256b_pinv_dec_3
Xwld144
+ in_144 out_144 vdd gnd
+ rom_256b_pinv_dec_3
Xwld145
+ in_145 out_145 vdd gnd
+ rom_256b_pinv_dec_3
Xwld146
+ in_146 out_146 vdd gnd
+ rom_256b_pinv_dec_3
Xwld147
+ in_147 out_147 vdd gnd
+ rom_256b_pinv_dec_3
Xwld148
+ in_148 out_148 vdd gnd
+ rom_256b_pinv_dec_3
Xwld149
+ in_149 out_149 vdd gnd
+ rom_256b_pinv_dec_3
Xwld150
+ in_150 out_150 vdd gnd
+ rom_256b_pinv_dec_3
Xwld151
+ in_151 out_151 vdd gnd
+ rom_256b_pinv_dec_3
Xwld152
+ in_152 out_152 vdd gnd
+ rom_256b_pinv_dec_3
Xwld153
+ in_153 out_153 vdd gnd
+ rom_256b_pinv_dec_3
Xwld154
+ in_154 out_154 vdd gnd
+ rom_256b_pinv_dec_3
Xwld155
+ in_155 out_155 vdd gnd
+ rom_256b_pinv_dec_3
Xwld156
+ in_156 out_156 vdd gnd
+ rom_256b_pinv_dec_3
Xwld157
+ in_157 out_157 vdd gnd
+ rom_256b_pinv_dec_3
Xwld158
+ in_158 out_158 vdd gnd
+ rom_256b_pinv_dec_3
Xwld159
+ in_159 out_159 vdd gnd
+ rom_256b_pinv_dec_3
Xwld160
+ in_160 out_160 vdd gnd
+ rom_256b_pinv_dec_3
Xwld161
+ in_161 out_161 vdd gnd
+ rom_256b_pinv_dec_3
Xwld162
+ in_162 out_162 vdd gnd
+ rom_256b_pinv_dec_3
Xwld163
+ in_163 out_163 vdd gnd
+ rom_256b_pinv_dec_3
Xwld164
+ in_164 out_164 vdd gnd
+ rom_256b_pinv_dec_3
Xwld165
+ in_165 out_165 vdd gnd
+ rom_256b_pinv_dec_3
Xwld166
+ in_166 out_166 vdd gnd
+ rom_256b_pinv_dec_3
Xwld167
+ in_167 out_167 vdd gnd
+ rom_256b_pinv_dec_3
Xwld168
+ in_168 out_168 vdd gnd
+ rom_256b_pinv_dec_3
Xwld169
+ in_169 out_169 vdd gnd
+ rom_256b_pinv_dec_3
Xwld170
+ in_170 out_170 vdd gnd
+ rom_256b_pinv_dec_3
Xwld171
+ in_171 out_171 vdd gnd
+ rom_256b_pinv_dec_3
Xwld172
+ in_172 out_172 vdd gnd
+ rom_256b_pinv_dec_3
Xwld173
+ in_173 out_173 vdd gnd
+ rom_256b_pinv_dec_3
Xwld174
+ in_174 out_174 vdd gnd
+ rom_256b_pinv_dec_3
Xwld175
+ in_175 out_175 vdd gnd
+ rom_256b_pinv_dec_3
Xwld176
+ in_176 out_176 vdd gnd
+ rom_256b_pinv_dec_3
Xwld177
+ in_177 out_177 vdd gnd
+ rom_256b_pinv_dec_3
Xwld178
+ in_178 out_178 vdd gnd
+ rom_256b_pinv_dec_3
Xwld179
+ in_179 out_179 vdd gnd
+ rom_256b_pinv_dec_3
Xwld180
+ in_180 out_180 vdd gnd
+ rom_256b_pinv_dec_3
Xwld181
+ in_181 out_181 vdd gnd
+ rom_256b_pinv_dec_3
Xwld182
+ in_182 out_182 vdd gnd
+ rom_256b_pinv_dec_3
Xwld183
+ in_183 out_183 vdd gnd
+ rom_256b_pinv_dec_3
Xwld184
+ in_184 out_184 vdd gnd
+ rom_256b_pinv_dec_3
Xwld185
+ in_185 out_185 vdd gnd
+ rom_256b_pinv_dec_3
Xwld186
+ in_186 out_186 vdd gnd
+ rom_256b_pinv_dec_3
Xwld187
+ in_187 out_187 vdd gnd
+ rom_256b_pinv_dec_3
Xwld188
+ in_188 out_188 vdd gnd
+ rom_256b_pinv_dec_3
Xwld189
+ in_189 out_189 vdd gnd
+ rom_256b_pinv_dec_3
Xwld190
+ in_190 out_190 vdd gnd
+ rom_256b_pinv_dec_3
Xwld191
+ in_191 out_191 vdd gnd
+ rom_256b_pinv_dec_3
Xwld192
+ in_192 out_192 vdd gnd
+ rom_256b_pinv_dec_3
Xwld193
+ in_193 out_193 vdd gnd
+ rom_256b_pinv_dec_3
Xwld194
+ in_194 out_194 vdd gnd
+ rom_256b_pinv_dec_3
Xwld195
+ in_195 out_195 vdd gnd
+ rom_256b_pinv_dec_3
Xwld196
+ in_196 out_196 vdd gnd
+ rom_256b_pinv_dec_3
Xwld197
+ in_197 out_197 vdd gnd
+ rom_256b_pinv_dec_3
Xwld198
+ in_198 out_198 vdd gnd
+ rom_256b_pinv_dec_3
Xwld199
+ in_199 out_199 vdd gnd
+ rom_256b_pinv_dec_3
Xwld200
+ in_200 out_200 vdd gnd
+ rom_256b_pinv_dec_3
Xwld201
+ in_201 out_201 vdd gnd
+ rom_256b_pinv_dec_3
Xwld202
+ in_202 out_202 vdd gnd
+ rom_256b_pinv_dec_3
Xwld203
+ in_203 out_203 vdd gnd
+ rom_256b_pinv_dec_3
Xwld204
+ in_204 out_204 vdd gnd
+ rom_256b_pinv_dec_3
Xwld205
+ in_205 out_205 vdd gnd
+ rom_256b_pinv_dec_3
Xwld206
+ in_206 out_206 vdd gnd
+ rom_256b_pinv_dec_3
Xwld207
+ in_207 out_207 vdd gnd
+ rom_256b_pinv_dec_3
Xwld208
+ in_208 out_208 vdd gnd
+ rom_256b_pinv_dec_3
Xwld209
+ in_209 out_209 vdd gnd
+ rom_256b_pinv_dec_3
Xwld210
+ in_210 out_210 vdd gnd
+ rom_256b_pinv_dec_3
Xwld211
+ in_211 out_211 vdd gnd
+ rom_256b_pinv_dec_3
Xwld212
+ in_212 out_212 vdd gnd
+ rom_256b_pinv_dec_3
Xwld213
+ in_213 out_213 vdd gnd
+ rom_256b_pinv_dec_3
Xwld214
+ in_214 out_214 vdd gnd
+ rom_256b_pinv_dec_3
Xwld215
+ in_215 out_215 vdd gnd
+ rom_256b_pinv_dec_3
Xwld216
+ in_216 out_216 vdd gnd
+ rom_256b_pinv_dec_3
Xwld217
+ in_217 out_217 vdd gnd
+ rom_256b_pinv_dec_3
Xwld218
+ in_218 out_218 vdd gnd
+ rom_256b_pinv_dec_3
Xwld219
+ in_219 out_219 vdd gnd
+ rom_256b_pinv_dec_3
Xwld220
+ in_220 out_220 vdd gnd
+ rom_256b_pinv_dec_3
Xwld221
+ in_221 out_221 vdd gnd
+ rom_256b_pinv_dec_3
Xwld222
+ in_222 out_222 vdd gnd
+ rom_256b_pinv_dec_3
Xwld223
+ in_223 out_223 vdd gnd
+ rom_256b_pinv_dec_3
Xwld224
+ in_224 out_224 vdd gnd
+ rom_256b_pinv_dec_3
Xwld225
+ in_225 out_225 vdd gnd
+ rom_256b_pinv_dec_3
Xwld226
+ in_226 out_226 vdd gnd
+ rom_256b_pinv_dec_3
Xwld227
+ in_227 out_227 vdd gnd
+ rom_256b_pinv_dec_3
Xwld228
+ in_228 out_228 vdd gnd
+ rom_256b_pinv_dec_3
Xwld229
+ in_229 out_229 vdd gnd
+ rom_256b_pinv_dec_3
Xwld230
+ in_230 out_230 vdd gnd
+ rom_256b_pinv_dec_3
Xwld231
+ in_231 out_231 vdd gnd
+ rom_256b_pinv_dec_3
Xwld232
+ in_232 out_232 vdd gnd
+ rom_256b_pinv_dec_3
Xwld233
+ in_233 out_233 vdd gnd
+ rom_256b_pinv_dec_3
Xwld234
+ in_234 out_234 vdd gnd
+ rom_256b_pinv_dec_3
Xwld235
+ in_235 out_235 vdd gnd
+ rom_256b_pinv_dec_3
Xwld236
+ in_236 out_236 vdd gnd
+ rom_256b_pinv_dec_3
Xwld237
+ in_237 out_237 vdd gnd
+ rom_256b_pinv_dec_3
Xwld238
+ in_238 out_238 vdd gnd
+ rom_256b_pinv_dec_3
Xwld239
+ in_239 out_239 vdd gnd
+ rom_256b_pinv_dec_3
Xwld240
+ in_240 out_240 vdd gnd
+ rom_256b_pinv_dec_3
Xwld241
+ in_241 out_241 vdd gnd
+ rom_256b_pinv_dec_3
Xwld242
+ in_242 out_242 vdd gnd
+ rom_256b_pinv_dec_3
Xwld243
+ in_243 out_243 vdd gnd
+ rom_256b_pinv_dec_3
Xwld244
+ in_244 out_244 vdd gnd
+ rom_256b_pinv_dec_3
Xwld245
+ in_245 out_245 vdd gnd
+ rom_256b_pinv_dec_3
Xwld246
+ in_246 out_246 vdd gnd
+ rom_256b_pinv_dec_3
Xwld247
+ in_247 out_247 vdd gnd
+ rom_256b_pinv_dec_3
Xwld248
+ in_248 out_248 vdd gnd
+ rom_256b_pinv_dec_3
Xwld249
+ in_249 out_249 vdd gnd
+ rom_256b_pinv_dec_3
Xwld250
+ in_250 out_250 vdd gnd
+ rom_256b_pinv_dec_3
Xwld251
+ in_251 out_251 vdd gnd
+ rom_256b_pinv_dec_3
Xwld252
+ in_252 out_252 vdd gnd
+ rom_256b_pinv_dec_3
Xwld253
+ in_253 out_253 vdd gnd
+ rom_256b_pinv_dec_3
Xwld254
+ in_254 out_254 vdd gnd
+ rom_256b_pinv_dec_3
Xwld255
+ in_255 out_255 vdd gnd
+ rom_256b_pinv_dec_3
.ENDS rom_256b_rom_bitline_inverter

* spice ptx X{0} {1} sky130_fd_pr__nfet_01v8 m=1 w=2.88 l=0.15 pd=6.06 ps=6.06 as=1.08u ad=1.08u

.SUBCKT rom_256b_rom_column_mux
+ bl bl_out sel gnd
* INOUT : bl 
* INOUT : bl_out 
* INOUT : sel 
* INOUT : gnd 
Xmux_tx1 bl sel bl_out gnd sky130_fd_pr__nfet_01v8 m=1 w=2.88u l=0.15u
.ENDS rom_256b_rom_column_mux

.SUBCKT rom_256b_rom_column_mux_array
+ bl_0 bl_1 bl_2 bl_3 bl_4 bl_5 bl_6 bl_7 bl_8 bl_9 bl_10 bl_11 bl_12
+ bl_13 bl_14 bl_15 bl_16 bl_17 bl_18 bl_19 bl_20 bl_21 bl_22 bl_23
+ bl_24 bl_25 bl_26 bl_27 bl_28 bl_29 bl_30 bl_31 bl_32 bl_33 bl_34
+ bl_35 bl_36 bl_37 bl_38 bl_39 bl_40 bl_41 bl_42 bl_43 bl_44 bl_45
+ bl_46 bl_47 bl_48 bl_49 bl_50 bl_51 bl_52 bl_53 bl_54 bl_55 bl_56
+ bl_57 bl_58 bl_59 bl_60 bl_61 bl_62 bl_63 bl_64 bl_65 bl_66 bl_67
+ bl_68 bl_69 bl_70 bl_71 bl_72 bl_73 bl_74 bl_75 bl_76 bl_77 bl_78
+ bl_79 bl_80 bl_81 bl_82 bl_83 bl_84 bl_85 bl_86 bl_87 bl_88 bl_89
+ bl_90 bl_91 bl_92 bl_93 bl_94 bl_95 bl_96 bl_97 bl_98 bl_99 bl_100
+ bl_101 bl_102 bl_103 bl_104 bl_105 bl_106 bl_107 bl_108 bl_109 bl_110
+ bl_111 bl_112 bl_113 bl_114 bl_115 bl_116 bl_117 bl_118 bl_119 bl_120
+ bl_121 bl_122 bl_123 bl_124 bl_125 bl_126 bl_127 bl_128 bl_129 bl_130
+ bl_131 bl_132 bl_133 bl_134 bl_135 bl_136 bl_137 bl_138 bl_139 bl_140
+ bl_141 bl_142 bl_143 bl_144 bl_145 bl_146 bl_147 bl_148 bl_149 bl_150
+ bl_151 bl_152 bl_153 bl_154 bl_155 bl_156 bl_157 bl_158 bl_159 bl_160
+ bl_161 bl_162 bl_163 bl_164 bl_165 bl_166 bl_167 bl_168 bl_169 bl_170
+ bl_171 bl_172 bl_173 bl_174 bl_175 bl_176 bl_177 bl_178 bl_179 bl_180
+ bl_181 bl_182 bl_183 bl_184 bl_185 bl_186 bl_187 bl_188 bl_189 bl_190
+ bl_191 bl_192 bl_193 bl_194 bl_195 bl_196 bl_197 bl_198 bl_199 bl_200
+ bl_201 bl_202 bl_203 bl_204 bl_205 bl_206 bl_207 bl_208 bl_209 bl_210
+ bl_211 bl_212 bl_213 bl_214 bl_215 bl_216 bl_217 bl_218 bl_219 bl_220
+ bl_221 bl_222 bl_223 bl_224 bl_225 bl_226 bl_227 bl_228 bl_229 bl_230
+ bl_231 bl_232 bl_233 bl_234 bl_235 bl_236 bl_237 bl_238 bl_239 bl_240
+ bl_241 bl_242 bl_243 bl_244 bl_245 bl_246 bl_247 bl_248 bl_249 bl_250
+ bl_251 bl_252 bl_253 bl_254 bl_255 sel_0 sel_1 sel_2 sel_3 sel_4 sel_5
+ sel_6 sel_7 bl_out_0 bl_out_1 bl_out_2 bl_out_3 bl_out_4 bl_out_5
+ bl_out_6 bl_out_7 bl_out_8 bl_out_9 bl_out_10 bl_out_11 bl_out_12
+ bl_out_13 bl_out_14 bl_out_15 bl_out_16 bl_out_17 bl_out_18 bl_out_19
+ bl_out_20 bl_out_21 bl_out_22 bl_out_23 bl_out_24 bl_out_25 bl_out_26
+ bl_out_27 bl_out_28 bl_out_29 bl_out_30 bl_out_31 gnd
* INOUT : bl_0 
* INOUT : bl_1 
* INOUT : bl_2 
* INOUT : bl_3 
* INOUT : bl_4 
* INOUT : bl_5 
* INOUT : bl_6 
* INOUT : bl_7 
* INOUT : bl_8 
* INOUT : bl_9 
* INOUT : bl_10 
* INOUT : bl_11 
* INOUT : bl_12 
* INOUT : bl_13 
* INOUT : bl_14 
* INOUT : bl_15 
* INOUT : bl_16 
* INOUT : bl_17 
* INOUT : bl_18 
* INOUT : bl_19 
* INOUT : bl_20 
* INOUT : bl_21 
* INOUT : bl_22 
* INOUT : bl_23 
* INOUT : bl_24 
* INOUT : bl_25 
* INOUT : bl_26 
* INOUT : bl_27 
* INOUT : bl_28 
* INOUT : bl_29 
* INOUT : bl_30 
* INOUT : bl_31 
* INOUT : bl_32 
* INOUT : bl_33 
* INOUT : bl_34 
* INOUT : bl_35 
* INOUT : bl_36 
* INOUT : bl_37 
* INOUT : bl_38 
* INOUT : bl_39 
* INOUT : bl_40 
* INOUT : bl_41 
* INOUT : bl_42 
* INOUT : bl_43 
* INOUT : bl_44 
* INOUT : bl_45 
* INOUT : bl_46 
* INOUT : bl_47 
* INOUT : bl_48 
* INOUT : bl_49 
* INOUT : bl_50 
* INOUT : bl_51 
* INOUT : bl_52 
* INOUT : bl_53 
* INOUT : bl_54 
* INOUT : bl_55 
* INOUT : bl_56 
* INOUT : bl_57 
* INOUT : bl_58 
* INOUT : bl_59 
* INOUT : bl_60 
* INOUT : bl_61 
* INOUT : bl_62 
* INOUT : bl_63 
* INOUT : bl_64 
* INOUT : bl_65 
* INOUT : bl_66 
* INOUT : bl_67 
* INOUT : bl_68 
* INOUT : bl_69 
* INOUT : bl_70 
* INOUT : bl_71 
* INOUT : bl_72 
* INOUT : bl_73 
* INOUT : bl_74 
* INOUT : bl_75 
* INOUT : bl_76 
* INOUT : bl_77 
* INOUT : bl_78 
* INOUT : bl_79 
* INOUT : bl_80 
* INOUT : bl_81 
* INOUT : bl_82 
* INOUT : bl_83 
* INOUT : bl_84 
* INOUT : bl_85 
* INOUT : bl_86 
* INOUT : bl_87 
* INOUT : bl_88 
* INOUT : bl_89 
* INOUT : bl_90 
* INOUT : bl_91 
* INOUT : bl_92 
* INOUT : bl_93 
* INOUT : bl_94 
* INOUT : bl_95 
* INOUT : bl_96 
* INOUT : bl_97 
* INOUT : bl_98 
* INOUT : bl_99 
* INOUT : bl_100 
* INOUT : bl_101 
* INOUT : bl_102 
* INOUT : bl_103 
* INOUT : bl_104 
* INOUT : bl_105 
* INOUT : bl_106 
* INOUT : bl_107 
* INOUT : bl_108 
* INOUT : bl_109 
* INOUT : bl_110 
* INOUT : bl_111 
* INOUT : bl_112 
* INOUT : bl_113 
* INOUT : bl_114 
* INOUT : bl_115 
* INOUT : bl_116 
* INOUT : bl_117 
* INOUT : bl_118 
* INOUT : bl_119 
* INOUT : bl_120 
* INOUT : bl_121 
* INOUT : bl_122 
* INOUT : bl_123 
* INOUT : bl_124 
* INOUT : bl_125 
* INOUT : bl_126 
* INOUT : bl_127 
* INOUT : bl_128 
* INOUT : bl_129 
* INOUT : bl_130 
* INOUT : bl_131 
* INOUT : bl_132 
* INOUT : bl_133 
* INOUT : bl_134 
* INOUT : bl_135 
* INOUT : bl_136 
* INOUT : bl_137 
* INOUT : bl_138 
* INOUT : bl_139 
* INOUT : bl_140 
* INOUT : bl_141 
* INOUT : bl_142 
* INOUT : bl_143 
* INOUT : bl_144 
* INOUT : bl_145 
* INOUT : bl_146 
* INOUT : bl_147 
* INOUT : bl_148 
* INOUT : bl_149 
* INOUT : bl_150 
* INOUT : bl_151 
* INOUT : bl_152 
* INOUT : bl_153 
* INOUT : bl_154 
* INOUT : bl_155 
* INOUT : bl_156 
* INOUT : bl_157 
* INOUT : bl_158 
* INOUT : bl_159 
* INOUT : bl_160 
* INOUT : bl_161 
* INOUT : bl_162 
* INOUT : bl_163 
* INOUT : bl_164 
* INOUT : bl_165 
* INOUT : bl_166 
* INOUT : bl_167 
* INOUT : bl_168 
* INOUT : bl_169 
* INOUT : bl_170 
* INOUT : bl_171 
* INOUT : bl_172 
* INOUT : bl_173 
* INOUT : bl_174 
* INOUT : bl_175 
* INOUT : bl_176 
* INOUT : bl_177 
* INOUT : bl_178 
* INOUT : bl_179 
* INOUT : bl_180 
* INOUT : bl_181 
* INOUT : bl_182 
* INOUT : bl_183 
* INOUT : bl_184 
* INOUT : bl_185 
* INOUT : bl_186 
* INOUT : bl_187 
* INOUT : bl_188 
* INOUT : bl_189 
* INOUT : bl_190 
* INOUT : bl_191 
* INOUT : bl_192 
* INOUT : bl_193 
* INOUT : bl_194 
* INOUT : bl_195 
* INOUT : bl_196 
* INOUT : bl_197 
* INOUT : bl_198 
* INOUT : bl_199 
* INOUT : bl_200 
* INOUT : bl_201 
* INOUT : bl_202 
* INOUT : bl_203 
* INOUT : bl_204 
* INOUT : bl_205 
* INOUT : bl_206 
* INOUT : bl_207 
* INOUT : bl_208 
* INOUT : bl_209 
* INOUT : bl_210 
* INOUT : bl_211 
* INOUT : bl_212 
* INOUT : bl_213 
* INOUT : bl_214 
* INOUT : bl_215 
* INOUT : bl_216 
* INOUT : bl_217 
* INOUT : bl_218 
* INOUT : bl_219 
* INOUT : bl_220 
* INOUT : bl_221 
* INOUT : bl_222 
* INOUT : bl_223 
* INOUT : bl_224 
* INOUT : bl_225 
* INOUT : bl_226 
* INOUT : bl_227 
* INOUT : bl_228 
* INOUT : bl_229 
* INOUT : bl_230 
* INOUT : bl_231 
* INOUT : bl_232 
* INOUT : bl_233 
* INOUT : bl_234 
* INOUT : bl_235 
* INOUT : bl_236 
* INOUT : bl_237 
* INOUT : bl_238 
* INOUT : bl_239 
* INOUT : bl_240 
* INOUT : bl_241 
* INOUT : bl_242 
* INOUT : bl_243 
* INOUT : bl_244 
* INOUT : bl_245 
* INOUT : bl_246 
* INOUT : bl_247 
* INOUT : bl_248 
* INOUT : bl_249 
* INOUT : bl_250 
* INOUT : bl_251 
* INOUT : bl_252 
* INOUT : bl_253 
* INOUT : bl_254 
* INOUT : bl_255 
* INOUT : sel_0 
* INOUT : sel_1 
* INOUT : sel_2 
* INOUT : sel_3 
* INOUT : sel_4 
* INOUT : sel_5 
* INOUT : sel_6 
* INOUT : sel_7 
* INOUT : bl_out_0 
* INOUT : bl_out_1 
* INOUT : bl_out_2 
* INOUT : bl_out_3 
* INOUT : bl_out_4 
* INOUT : bl_out_5 
* INOUT : bl_out_6 
* INOUT : bl_out_7 
* INOUT : bl_out_8 
* INOUT : bl_out_9 
* INOUT : bl_out_10 
* INOUT : bl_out_11 
* INOUT : bl_out_12 
* INOUT : bl_out_13 
* INOUT : bl_out_14 
* INOUT : bl_out_15 
* INOUT : bl_out_16 
* INOUT : bl_out_17 
* INOUT : bl_out_18 
* INOUT : bl_out_19 
* INOUT : bl_out_20 
* INOUT : bl_out_21 
* INOUT : bl_out_22 
* INOUT : bl_out_23 
* INOUT : bl_out_24 
* INOUT : bl_out_25 
* INOUT : bl_out_26 
* INOUT : bl_out_27 
* INOUT : bl_out_28 
* INOUT : bl_out_29 
* INOUT : bl_out_30 
* INOUT : bl_out_31 
* INOUT : gnd 
* cols: 256 word_size: 32 
XXMUX0
+ bl_0 bl_out_0 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX1
+ bl_1 bl_out_0 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX2
+ bl_2 bl_out_0 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX3
+ bl_3 bl_out_0 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX4
+ bl_4 bl_out_0 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX5
+ bl_5 bl_out_0 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX6
+ bl_6 bl_out_0 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX7
+ bl_7 bl_out_0 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX8
+ bl_8 bl_out_1 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX9
+ bl_9 bl_out_1 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX10
+ bl_10 bl_out_1 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX11
+ bl_11 bl_out_1 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX12
+ bl_12 bl_out_1 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX13
+ bl_13 bl_out_1 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX14
+ bl_14 bl_out_1 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX15
+ bl_15 bl_out_1 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX16
+ bl_16 bl_out_2 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX17
+ bl_17 bl_out_2 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX18
+ bl_18 bl_out_2 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX19
+ bl_19 bl_out_2 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX20
+ bl_20 bl_out_2 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX21
+ bl_21 bl_out_2 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX22
+ bl_22 bl_out_2 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX23
+ bl_23 bl_out_2 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX24
+ bl_24 bl_out_3 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX25
+ bl_25 bl_out_3 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX26
+ bl_26 bl_out_3 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX27
+ bl_27 bl_out_3 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX28
+ bl_28 bl_out_3 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX29
+ bl_29 bl_out_3 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX30
+ bl_30 bl_out_3 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX31
+ bl_31 bl_out_3 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX32
+ bl_32 bl_out_4 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX33
+ bl_33 bl_out_4 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX34
+ bl_34 bl_out_4 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX35
+ bl_35 bl_out_4 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX36
+ bl_36 bl_out_4 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX37
+ bl_37 bl_out_4 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX38
+ bl_38 bl_out_4 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX39
+ bl_39 bl_out_4 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX40
+ bl_40 bl_out_5 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX41
+ bl_41 bl_out_5 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX42
+ bl_42 bl_out_5 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX43
+ bl_43 bl_out_5 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX44
+ bl_44 bl_out_5 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX45
+ bl_45 bl_out_5 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX46
+ bl_46 bl_out_5 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX47
+ bl_47 bl_out_5 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX48
+ bl_48 bl_out_6 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX49
+ bl_49 bl_out_6 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX50
+ bl_50 bl_out_6 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX51
+ bl_51 bl_out_6 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX52
+ bl_52 bl_out_6 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX53
+ bl_53 bl_out_6 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX54
+ bl_54 bl_out_6 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX55
+ bl_55 bl_out_6 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX56
+ bl_56 bl_out_7 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX57
+ bl_57 bl_out_7 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX58
+ bl_58 bl_out_7 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX59
+ bl_59 bl_out_7 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX60
+ bl_60 bl_out_7 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX61
+ bl_61 bl_out_7 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX62
+ bl_62 bl_out_7 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX63
+ bl_63 bl_out_7 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX64
+ bl_64 bl_out_8 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX65
+ bl_65 bl_out_8 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX66
+ bl_66 bl_out_8 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX67
+ bl_67 bl_out_8 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX68
+ bl_68 bl_out_8 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX69
+ bl_69 bl_out_8 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX70
+ bl_70 bl_out_8 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX71
+ bl_71 bl_out_8 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX72
+ bl_72 bl_out_9 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX73
+ bl_73 bl_out_9 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX74
+ bl_74 bl_out_9 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX75
+ bl_75 bl_out_9 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX76
+ bl_76 bl_out_9 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX77
+ bl_77 bl_out_9 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX78
+ bl_78 bl_out_9 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX79
+ bl_79 bl_out_9 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX80
+ bl_80 bl_out_10 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX81
+ bl_81 bl_out_10 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX82
+ bl_82 bl_out_10 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX83
+ bl_83 bl_out_10 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX84
+ bl_84 bl_out_10 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX85
+ bl_85 bl_out_10 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX86
+ bl_86 bl_out_10 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX87
+ bl_87 bl_out_10 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX88
+ bl_88 bl_out_11 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX89
+ bl_89 bl_out_11 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX90
+ bl_90 bl_out_11 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX91
+ bl_91 bl_out_11 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX92
+ bl_92 bl_out_11 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX93
+ bl_93 bl_out_11 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX94
+ bl_94 bl_out_11 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX95
+ bl_95 bl_out_11 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX96
+ bl_96 bl_out_12 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX97
+ bl_97 bl_out_12 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX98
+ bl_98 bl_out_12 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX99
+ bl_99 bl_out_12 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX100
+ bl_100 bl_out_12 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX101
+ bl_101 bl_out_12 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX102
+ bl_102 bl_out_12 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX103
+ bl_103 bl_out_12 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX104
+ bl_104 bl_out_13 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX105
+ bl_105 bl_out_13 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX106
+ bl_106 bl_out_13 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX107
+ bl_107 bl_out_13 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX108
+ bl_108 bl_out_13 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX109
+ bl_109 bl_out_13 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX110
+ bl_110 bl_out_13 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX111
+ bl_111 bl_out_13 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX112
+ bl_112 bl_out_14 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX113
+ bl_113 bl_out_14 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX114
+ bl_114 bl_out_14 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX115
+ bl_115 bl_out_14 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX116
+ bl_116 bl_out_14 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX117
+ bl_117 bl_out_14 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX118
+ bl_118 bl_out_14 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX119
+ bl_119 bl_out_14 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX120
+ bl_120 bl_out_15 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX121
+ bl_121 bl_out_15 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX122
+ bl_122 bl_out_15 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX123
+ bl_123 bl_out_15 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX124
+ bl_124 bl_out_15 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX125
+ bl_125 bl_out_15 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX126
+ bl_126 bl_out_15 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX127
+ bl_127 bl_out_15 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX128
+ bl_128 bl_out_16 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX129
+ bl_129 bl_out_16 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX130
+ bl_130 bl_out_16 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX131
+ bl_131 bl_out_16 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX132
+ bl_132 bl_out_16 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX133
+ bl_133 bl_out_16 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX134
+ bl_134 bl_out_16 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX135
+ bl_135 bl_out_16 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX136
+ bl_136 bl_out_17 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX137
+ bl_137 bl_out_17 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX138
+ bl_138 bl_out_17 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX139
+ bl_139 bl_out_17 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX140
+ bl_140 bl_out_17 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX141
+ bl_141 bl_out_17 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX142
+ bl_142 bl_out_17 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX143
+ bl_143 bl_out_17 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX144
+ bl_144 bl_out_18 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX145
+ bl_145 bl_out_18 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX146
+ bl_146 bl_out_18 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX147
+ bl_147 bl_out_18 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX148
+ bl_148 bl_out_18 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX149
+ bl_149 bl_out_18 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX150
+ bl_150 bl_out_18 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX151
+ bl_151 bl_out_18 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX152
+ bl_152 bl_out_19 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX153
+ bl_153 bl_out_19 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX154
+ bl_154 bl_out_19 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX155
+ bl_155 bl_out_19 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX156
+ bl_156 bl_out_19 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX157
+ bl_157 bl_out_19 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX158
+ bl_158 bl_out_19 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX159
+ bl_159 bl_out_19 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX160
+ bl_160 bl_out_20 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX161
+ bl_161 bl_out_20 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX162
+ bl_162 bl_out_20 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX163
+ bl_163 bl_out_20 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX164
+ bl_164 bl_out_20 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX165
+ bl_165 bl_out_20 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX166
+ bl_166 bl_out_20 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX167
+ bl_167 bl_out_20 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX168
+ bl_168 bl_out_21 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX169
+ bl_169 bl_out_21 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX170
+ bl_170 bl_out_21 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX171
+ bl_171 bl_out_21 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX172
+ bl_172 bl_out_21 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX173
+ bl_173 bl_out_21 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX174
+ bl_174 bl_out_21 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX175
+ bl_175 bl_out_21 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX176
+ bl_176 bl_out_22 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX177
+ bl_177 bl_out_22 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX178
+ bl_178 bl_out_22 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX179
+ bl_179 bl_out_22 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX180
+ bl_180 bl_out_22 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX181
+ bl_181 bl_out_22 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX182
+ bl_182 bl_out_22 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX183
+ bl_183 bl_out_22 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX184
+ bl_184 bl_out_23 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX185
+ bl_185 bl_out_23 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX186
+ bl_186 bl_out_23 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX187
+ bl_187 bl_out_23 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX188
+ bl_188 bl_out_23 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX189
+ bl_189 bl_out_23 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX190
+ bl_190 bl_out_23 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX191
+ bl_191 bl_out_23 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX192
+ bl_192 bl_out_24 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX193
+ bl_193 bl_out_24 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX194
+ bl_194 bl_out_24 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX195
+ bl_195 bl_out_24 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX196
+ bl_196 bl_out_24 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX197
+ bl_197 bl_out_24 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX198
+ bl_198 bl_out_24 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX199
+ bl_199 bl_out_24 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX200
+ bl_200 bl_out_25 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX201
+ bl_201 bl_out_25 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX202
+ bl_202 bl_out_25 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX203
+ bl_203 bl_out_25 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX204
+ bl_204 bl_out_25 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX205
+ bl_205 bl_out_25 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX206
+ bl_206 bl_out_25 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX207
+ bl_207 bl_out_25 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX208
+ bl_208 bl_out_26 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX209
+ bl_209 bl_out_26 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX210
+ bl_210 bl_out_26 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX211
+ bl_211 bl_out_26 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX212
+ bl_212 bl_out_26 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX213
+ bl_213 bl_out_26 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX214
+ bl_214 bl_out_26 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX215
+ bl_215 bl_out_26 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX216
+ bl_216 bl_out_27 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX217
+ bl_217 bl_out_27 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX218
+ bl_218 bl_out_27 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX219
+ bl_219 bl_out_27 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX220
+ bl_220 bl_out_27 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX221
+ bl_221 bl_out_27 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX222
+ bl_222 bl_out_27 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX223
+ bl_223 bl_out_27 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX224
+ bl_224 bl_out_28 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX225
+ bl_225 bl_out_28 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX226
+ bl_226 bl_out_28 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX227
+ bl_227 bl_out_28 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX228
+ bl_228 bl_out_28 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX229
+ bl_229 bl_out_28 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX230
+ bl_230 bl_out_28 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX231
+ bl_231 bl_out_28 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX232
+ bl_232 bl_out_29 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX233
+ bl_233 bl_out_29 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX234
+ bl_234 bl_out_29 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX235
+ bl_235 bl_out_29 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX236
+ bl_236 bl_out_29 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX237
+ bl_237 bl_out_29 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX238
+ bl_238 bl_out_29 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX239
+ bl_239 bl_out_29 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX240
+ bl_240 bl_out_30 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX241
+ bl_241 bl_out_30 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX242
+ bl_242 bl_out_30 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX243
+ bl_243 bl_out_30 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX244
+ bl_244 bl_out_30 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX245
+ bl_245 bl_out_30 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX246
+ bl_246 bl_out_30 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX247
+ bl_247 bl_out_30 sel_7 gnd
+ rom_256b_rom_column_mux
XXMUX248
+ bl_248 bl_out_31 sel_0 gnd
+ rom_256b_rom_column_mux
XXMUX249
+ bl_249 bl_out_31 sel_1 gnd
+ rom_256b_rom_column_mux
XXMUX250
+ bl_250 bl_out_31 sel_2 gnd
+ rom_256b_rom_column_mux
XXMUX251
+ bl_251 bl_out_31 sel_3 gnd
+ rom_256b_rom_column_mux
XXMUX252
+ bl_252 bl_out_31 sel_4 gnd
+ rom_256b_rom_column_mux
XXMUX253
+ bl_253 bl_out_31 sel_5 gnd
+ rom_256b_rom_column_mux
XXMUX254
+ bl_254 bl_out_31 sel_6 gnd
+ rom_256b_rom_column_mux
XXMUX255
+ bl_255 bl_out_31 sel_7 gnd
+ rom_256b_rom_column_mux
.ENDS rom_256b_rom_column_mux_array

.SUBCKT rom_256b_rom_precharge_array
+ pre_bl0_out pre_bl1_out pre_bl2_out pre_bl3_out pre_bl4_out
+ pre_bl5_out pre_bl6_out pre_bl7_out pre_bl8_out pre_bl9_out
+ pre_bl10_out pre_bl11_out pre_bl12_out pre_bl13_out pre_bl14_out
+ pre_bl15_out pre_bl16_out pre_bl17_out pre_bl18_out pre_bl19_out
+ pre_bl20_out pre_bl21_out pre_bl22_out pre_bl23_out pre_bl24_out
+ pre_bl25_out pre_bl26_out pre_bl27_out pre_bl28_out pre_bl29_out
+ pre_bl30_out pre_bl31_out pre_bl32_out pre_bl33_out pre_bl34_out
+ pre_bl35_out pre_bl36_out pre_bl37_out pre_bl38_out pre_bl39_out
+ pre_bl40_out pre_bl41_out pre_bl42_out pre_bl43_out pre_bl44_out
+ pre_bl45_out pre_bl46_out pre_bl47_out pre_bl48_out pre_bl49_out
+ pre_bl50_out pre_bl51_out pre_bl52_out pre_bl53_out pre_bl54_out
+ pre_bl55_out pre_bl56_out pre_bl57_out pre_bl58_out pre_bl59_out
+ pre_bl60_out pre_bl61_out pre_bl62_out pre_bl63_out pre_bl64_out
+ pre_bl65_out pre_bl66_out pre_bl67_out pre_bl68_out pre_bl69_out
+ pre_bl70_out pre_bl71_out pre_bl72_out pre_bl73_out pre_bl74_out
+ pre_bl75_out pre_bl76_out pre_bl77_out pre_bl78_out pre_bl79_out
+ pre_bl80_out pre_bl81_out pre_bl82_out pre_bl83_out pre_bl84_out
+ pre_bl85_out pre_bl86_out pre_bl87_out pre_bl88_out pre_bl89_out
+ pre_bl90_out pre_bl91_out pre_bl92_out pre_bl93_out pre_bl94_out
+ pre_bl95_out pre_bl96_out pre_bl97_out pre_bl98_out pre_bl99_out
+ pre_bl100_out pre_bl101_out pre_bl102_out pre_bl103_out pre_bl104_out
+ pre_bl105_out pre_bl106_out pre_bl107_out pre_bl108_out pre_bl109_out
+ pre_bl110_out pre_bl111_out pre_bl112_out pre_bl113_out pre_bl114_out
+ pre_bl115_out pre_bl116_out pre_bl117_out pre_bl118_out pre_bl119_out
+ pre_bl120_out pre_bl121_out pre_bl122_out pre_bl123_out pre_bl124_out
+ pre_bl125_out pre_bl126_out pre_bl127_out pre_bl128_out pre_bl129_out
+ pre_bl130_out pre_bl131_out pre_bl132_out pre_bl133_out pre_bl134_out
+ pre_bl135_out pre_bl136_out pre_bl137_out pre_bl138_out pre_bl139_out
+ pre_bl140_out pre_bl141_out pre_bl142_out pre_bl143_out pre_bl144_out
+ pre_bl145_out pre_bl146_out pre_bl147_out pre_bl148_out pre_bl149_out
+ pre_bl150_out pre_bl151_out pre_bl152_out pre_bl153_out pre_bl154_out
+ pre_bl155_out pre_bl156_out pre_bl157_out pre_bl158_out pre_bl159_out
+ pre_bl160_out pre_bl161_out pre_bl162_out pre_bl163_out pre_bl164_out
+ pre_bl165_out pre_bl166_out pre_bl167_out pre_bl168_out pre_bl169_out
+ pre_bl170_out pre_bl171_out pre_bl172_out pre_bl173_out pre_bl174_out
+ pre_bl175_out pre_bl176_out pre_bl177_out pre_bl178_out pre_bl179_out
+ pre_bl180_out pre_bl181_out pre_bl182_out pre_bl183_out pre_bl184_out
+ pre_bl185_out pre_bl186_out pre_bl187_out pre_bl188_out pre_bl189_out
+ pre_bl190_out pre_bl191_out pre_bl192_out pre_bl193_out pre_bl194_out
+ pre_bl195_out pre_bl196_out pre_bl197_out pre_bl198_out pre_bl199_out
+ pre_bl200_out pre_bl201_out pre_bl202_out pre_bl203_out pre_bl204_out
+ pre_bl205_out pre_bl206_out pre_bl207_out pre_bl208_out pre_bl209_out
+ pre_bl210_out pre_bl211_out pre_bl212_out pre_bl213_out pre_bl214_out
+ pre_bl215_out pre_bl216_out pre_bl217_out pre_bl218_out pre_bl219_out
+ pre_bl220_out pre_bl221_out pre_bl222_out pre_bl223_out pre_bl224_out
+ pre_bl225_out pre_bl226_out pre_bl227_out pre_bl228_out pre_bl229_out
+ pre_bl230_out pre_bl231_out pre_bl232_out pre_bl233_out pre_bl234_out
+ pre_bl235_out pre_bl236_out pre_bl237_out pre_bl238_out pre_bl239_out
+ pre_bl240_out pre_bl241_out pre_bl242_out pre_bl243_out pre_bl244_out
+ pre_bl245_out pre_bl246_out pre_bl247_out pre_bl248_out pre_bl249_out
+ pre_bl250_out pre_bl251_out pre_bl252_out pre_bl253_out pre_bl254_out
+ pre_bl255_out gate vdd
* OUTPUT: pre_bl0_out 
* OUTPUT: pre_bl1_out 
* OUTPUT: pre_bl2_out 
* OUTPUT: pre_bl3_out 
* OUTPUT: pre_bl4_out 
* OUTPUT: pre_bl5_out 
* OUTPUT: pre_bl6_out 
* OUTPUT: pre_bl7_out 
* OUTPUT: pre_bl8_out 
* OUTPUT: pre_bl9_out 
* OUTPUT: pre_bl10_out 
* OUTPUT: pre_bl11_out 
* OUTPUT: pre_bl12_out 
* OUTPUT: pre_bl13_out 
* OUTPUT: pre_bl14_out 
* OUTPUT: pre_bl15_out 
* OUTPUT: pre_bl16_out 
* OUTPUT: pre_bl17_out 
* OUTPUT: pre_bl18_out 
* OUTPUT: pre_bl19_out 
* OUTPUT: pre_bl20_out 
* OUTPUT: pre_bl21_out 
* OUTPUT: pre_bl22_out 
* OUTPUT: pre_bl23_out 
* OUTPUT: pre_bl24_out 
* OUTPUT: pre_bl25_out 
* OUTPUT: pre_bl26_out 
* OUTPUT: pre_bl27_out 
* OUTPUT: pre_bl28_out 
* OUTPUT: pre_bl29_out 
* OUTPUT: pre_bl30_out 
* OUTPUT: pre_bl31_out 
* OUTPUT: pre_bl32_out 
* OUTPUT: pre_bl33_out 
* OUTPUT: pre_bl34_out 
* OUTPUT: pre_bl35_out 
* OUTPUT: pre_bl36_out 
* OUTPUT: pre_bl37_out 
* OUTPUT: pre_bl38_out 
* OUTPUT: pre_bl39_out 
* OUTPUT: pre_bl40_out 
* OUTPUT: pre_bl41_out 
* OUTPUT: pre_bl42_out 
* OUTPUT: pre_bl43_out 
* OUTPUT: pre_bl44_out 
* OUTPUT: pre_bl45_out 
* OUTPUT: pre_bl46_out 
* OUTPUT: pre_bl47_out 
* OUTPUT: pre_bl48_out 
* OUTPUT: pre_bl49_out 
* OUTPUT: pre_bl50_out 
* OUTPUT: pre_bl51_out 
* OUTPUT: pre_bl52_out 
* OUTPUT: pre_bl53_out 
* OUTPUT: pre_bl54_out 
* OUTPUT: pre_bl55_out 
* OUTPUT: pre_bl56_out 
* OUTPUT: pre_bl57_out 
* OUTPUT: pre_bl58_out 
* OUTPUT: pre_bl59_out 
* OUTPUT: pre_bl60_out 
* OUTPUT: pre_bl61_out 
* OUTPUT: pre_bl62_out 
* OUTPUT: pre_bl63_out 
* OUTPUT: pre_bl64_out 
* OUTPUT: pre_bl65_out 
* OUTPUT: pre_bl66_out 
* OUTPUT: pre_bl67_out 
* OUTPUT: pre_bl68_out 
* OUTPUT: pre_bl69_out 
* OUTPUT: pre_bl70_out 
* OUTPUT: pre_bl71_out 
* OUTPUT: pre_bl72_out 
* OUTPUT: pre_bl73_out 
* OUTPUT: pre_bl74_out 
* OUTPUT: pre_bl75_out 
* OUTPUT: pre_bl76_out 
* OUTPUT: pre_bl77_out 
* OUTPUT: pre_bl78_out 
* OUTPUT: pre_bl79_out 
* OUTPUT: pre_bl80_out 
* OUTPUT: pre_bl81_out 
* OUTPUT: pre_bl82_out 
* OUTPUT: pre_bl83_out 
* OUTPUT: pre_bl84_out 
* OUTPUT: pre_bl85_out 
* OUTPUT: pre_bl86_out 
* OUTPUT: pre_bl87_out 
* OUTPUT: pre_bl88_out 
* OUTPUT: pre_bl89_out 
* OUTPUT: pre_bl90_out 
* OUTPUT: pre_bl91_out 
* OUTPUT: pre_bl92_out 
* OUTPUT: pre_bl93_out 
* OUTPUT: pre_bl94_out 
* OUTPUT: pre_bl95_out 
* OUTPUT: pre_bl96_out 
* OUTPUT: pre_bl97_out 
* OUTPUT: pre_bl98_out 
* OUTPUT: pre_bl99_out 
* OUTPUT: pre_bl100_out 
* OUTPUT: pre_bl101_out 
* OUTPUT: pre_bl102_out 
* OUTPUT: pre_bl103_out 
* OUTPUT: pre_bl104_out 
* OUTPUT: pre_bl105_out 
* OUTPUT: pre_bl106_out 
* OUTPUT: pre_bl107_out 
* OUTPUT: pre_bl108_out 
* OUTPUT: pre_bl109_out 
* OUTPUT: pre_bl110_out 
* OUTPUT: pre_bl111_out 
* OUTPUT: pre_bl112_out 
* OUTPUT: pre_bl113_out 
* OUTPUT: pre_bl114_out 
* OUTPUT: pre_bl115_out 
* OUTPUT: pre_bl116_out 
* OUTPUT: pre_bl117_out 
* OUTPUT: pre_bl118_out 
* OUTPUT: pre_bl119_out 
* OUTPUT: pre_bl120_out 
* OUTPUT: pre_bl121_out 
* OUTPUT: pre_bl122_out 
* OUTPUT: pre_bl123_out 
* OUTPUT: pre_bl124_out 
* OUTPUT: pre_bl125_out 
* OUTPUT: pre_bl126_out 
* OUTPUT: pre_bl127_out 
* OUTPUT: pre_bl128_out 
* OUTPUT: pre_bl129_out 
* OUTPUT: pre_bl130_out 
* OUTPUT: pre_bl131_out 
* OUTPUT: pre_bl132_out 
* OUTPUT: pre_bl133_out 
* OUTPUT: pre_bl134_out 
* OUTPUT: pre_bl135_out 
* OUTPUT: pre_bl136_out 
* OUTPUT: pre_bl137_out 
* OUTPUT: pre_bl138_out 
* OUTPUT: pre_bl139_out 
* OUTPUT: pre_bl140_out 
* OUTPUT: pre_bl141_out 
* OUTPUT: pre_bl142_out 
* OUTPUT: pre_bl143_out 
* OUTPUT: pre_bl144_out 
* OUTPUT: pre_bl145_out 
* OUTPUT: pre_bl146_out 
* OUTPUT: pre_bl147_out 
* OUTPUT: pre_bl148_out 
* OUTPUT: pre_bl149_out 
* OUTPUT: pre_bl150_out 
* OUTPUT: pre_bl151_out 
* OUTPUT: pre_bl152_out 
* OUTPUT: pre_bl153_out 
* OUTPUT: pre_bl154_out 
* OUTPUT: pre_bl155_out 
* OUTPUT: pre_bl156_out 
* OUTPUT: pre_bl157_out 
* OUTPUT: pre_bl158_out 
* OUTPUT: pre_bl159_out 
* OUTPUT: pre_bl160_out 
* OUTPUT: pre_bl161_out 
* OUTPUT: pre_bl162_out 
* OUTPUT: pre_bl163_out 
* OUTPUT: pre_bl164_out 
* OUTPUT: pre_bl165_out 
* OUTPUT: pre_bl166_out 
* OUTPUT: pre_bl167_out 
* OUTPUT: pre_bl168_out 
* OUTPUT: pre_bl169_out 
* OUTPUT: pre_bl170_out 
* OUTPUT: pre_bl171_out 
* OUTPUT: pre_bl172_out 
* OUTPUT: pre_bl173_out 
* OUTPUT: pre_bl174_out 
* OUTPUT: pre_bl175_out 
* OUTPUT: pre_bl176_out 
* OUTPUT: pre_bl177_out 
* OUTPUT: pre_bl178_out 
* OUTPUT: pre_bl179_out 
* OUTPUT: pre_bl180_out 
* OUTPUT: pre_bl181_out 
* OUTPUT: pre_bl182_out 
* OUTPUT: pre_bl183_out 
* OUTPUT: pre_bl184_out 
* OUTPUT: pre_bl185_out 
* OUTPUT: pre_bl186_out 
* OUTPUT: pre_bl187_out 
* OUTPUT: pre_bl188_out 
* OUTPUT: pre_bl189_out 
* OUTPUT: pre_bl190_out 
* OUTPUT: pre_bl191_out 
* OUTPUT: pre_bl192_out 
* OUTPUT: pre_bl193_out 
* OUTPUT: pre_bl194_out 
* OUTPUT: pre_bl195_out 
* OUTPUT: pre_bl196_out 
* OUTPUT: pre_bl197_out 
* OUTPUT: pre_bl198_out 
* OUTPUT: pre_bl199_out 
* OUTPUT: pre_bl200_out 
* OUTPUT: pre_bl201_out 
* OUTPUT: pre_bl202_out 
* OUTPUT: pre_bl203_out 
* OUTPUT: pre_bl204_out 
* OUTPUT: pre_bl205_out 
* OUTPUT: pre_bl206_out 
* OUTPUT: pre_bl207_out 
* OUTPUT: pre_bl208_out 
* OUTPUT: pre_bl209_out 
* OUTPUT: pre_bl210_out 
* OUTPUT: pre_bl211_out 
* OUTPUT: pre_bl212_out 
* OUTPUT: pre_bl213_out 
* OUTPUT: pre_bl214_out 
* OUTPUT: pre_bl215_out 
* OUTPUT: pre_bl216_out 
* OUTPUT: pre_bl217_out 
* OUTPUT: pre_bl218_out 
* OUTPUT: pre_bl219_out 
* OUTPUT: pre_bl220_out 
* OUTPUT: pre_bl221_out 
* OUTPUT: pre_bl222_out 
* OUTPUT: pre_bl223_out 
* OUTPUT: pre_bl224_out 
* OUTPUT: pre_bl225_out 
* OUTPUT: pre_bl226_out 
* OUTPUT: pre_bl227_out 
* OUTPUT: pre_bl228_out 
* OUTPUT: pre_bl229_out 
* OUTPUT: pre_bl230_out 
* OUTPUT: pre_bl231_out 
* OUTPUT: pre_bl232_out 
* OUTPUT: pre_bl233_out 
* OUTPUT: pre_bl234_out 
* OUTPUT: pre_bl235_out 
* OUTPUT: pre_bl236_out 
* OUTPUT: pre_bl237_out 
* OUTPUT: pre_bl238_out 
* OUTPUT: pre_bl239_out 
* OUTPUT: pre_bl240_out 
* OUTPUT: pre_bl241_out 
* OUTPUT: pre_bl242_out 
* OUTPUT: pre_bl243_out 
* OUTPUT: pre_bl244_out 
* OUTPUT: pre_bl245_out 
* OUTPUT: pre_bl246_out 
* OUTPUT: pre_bl247_out 
* OUTPUT: pre_bl248_out 
* OUTPUT: pre_bl249_out 
* OUTPUT: pre_bl250_out 
* OUTPUT: pre_bl251_out 
* OUTPUT: pre_bl252_out 
* OUTPUT: pre_bl253_out 
* OUTPUT: pre_bl254_out 
* OUTPUT: pre_bl255_out 
* INPUT : gate 
* POWER : vdd 
Xpmos_c0
+ vdd gate pre_bl0_out
+ rom_256b_precharge_cell
Xpmos_c1
+ vdd gate pre_bl1_out
+ rom_256b_precharge_cell
Xpmos_c2
+ vdd gate pre_bl2_out
+ rom_256b_precharge_cell
Xpmos_c3
+ vdd gate pre_bl3_out
+ rom_256b_precharge_cell
Xpmos_c4
+ vdd gate pre_bl4_out
+ rom_256b_precharge_cell
Xpmos_c5
+ vdd gate pre_bl5_out
+ rom_256b_precharge_cell
Xpmos_c6
+ vdd gate pre_bl6_out
+ rom_256b_precharge_cell
Xpmos_c7
+ vdd gate pre_bl7_out
+ rom_256b_precharge_cell
Xpmos_c8
+ vdd gate pre_bl8_out
+ rom_256b_precharge_cell
Xpmos_c9
+ vdd gate pre_bl9_out
+ rom_256b_precharge_cell
Xpmos_c10
+ vdd gate pre_bl10_out
+ rom_256b_precharge_cell
Xpmos_c11
+ vdd gate pre_bl11_out
+ rom_256b_precharge_cell
Xpmos_c12
+ vdd gate pre_bl12_out
+ rom_256b_precharge_cell
Xpmos_c13
+ vdd gate pre_bl13_out
+ rom_256b_precharge_cell
Xpmos_c14
+ vdd gate pre_bl14_out
+ rom_256b_precharge_cell
Xpmos_c15
+ vdd gate pre_bl15_out
+ rom_256b_precharge_cell
Xpmos_c16
+ vdd gate pre_bl16_out
+ rom_256b_precharge_cell
Xpmos_c17
+ vdd gate pre_bl17_out
+ rom_256b_precharge_cell
Xpmos_c18
+ vdd gate pre_bl18_out
+ rom_256b_precharge_cell
Xpmos_c19
+ vdd gate pre_bl19_out
+ rom_256b_precharge_cell
Xpmos_c20
+ vdd gate pre_bl20_out
+ rom_256b_precharge_cell
Xpmos_c21
+ vdd gate pre_bl21_out
+ rom_256b_precharge_cell
Xpmos_c22
+ vdd gate pre_bl22_out
+ rom_256b_precharge_cell
Xpmos_c23
+ vdd gate pre_bl23_out
+ rom_256b_precharge_cell
Xpmos_c24
+ vdd gate pre_bl24_out
+ rom_256b_precharge_cell
Xpmos_c25
+ vdd gate pre_bl25_out
+ rom_256b_precharge_cell
Xpmos_c26
+ vdd gate pre_bl26_out
+ rom_256b_precharge_cell
Xpmos_c27
+ vdd gate pre_bl27_out
+ rom_256b_precharge_cell
Xpmos_c28
+ vdd gate pre_bl28_out
+ rom_256b_precharge_cell
Xpmos_c29
+ vdd gate pre_bl29_out
+ rom_256b_precharge_cell
Xpmos_c30
+ vdd gate pre_bl30_out
+ rom_256b_precharge_cell
Xpmos_c31
+ vdd gate pre_bl31_out
+ rom_256b_precharge_cell
Xpmos_c32
+ vdd gate pre_bl32_out
+ rom_256b_precharge_cell
Xpmos_c33
+ vdd gate pre_bl33_out
+ rom_256b_precharge_cell
Xpmos_c34
+ vdd gate pre_bl34_out
+ rom_256b_precharge_cell
Xpmos_c35
+ vdd gate pre_bl35_out
+ rom_256b_precharge_cell
Xpmos_c36
+ vdd gate pre_bl36_out
+ rom_256b_precharge_cell
Xpmos_c37
+ vdd gate pre_bl37_out
+ rom_256b_precharge_cell
Xpmos_c38
+ vdd gate pre_bl38_out
+ rom_256b_precharge_cell
Xpmos_c39
+ vdd gate pre_bl39_out
+ rom_256b_precharge_cell
Xpmos_c40
+ vdd gate pre_bl40_out
+ rom_256b_precharge_cell
Xpmos_c41
+ vdd gate pre_bl41_out
+ rom_256b_precharge_cell
Xpmos_c42
+ vdd gate pre_bl42_out
+ rom_256b_precharge_cell
Xpmos_c43
+ vdd gate pre_bl43_out
+ rom_256b_precharge_cell
Xpmos_c44
+ vdd gate pre_bl44_out
+ rom_256b_precharge_cell
Xpmos_c45
+ vdd gate pre_bl45_out
+ rom_256b_precharge_cell
Xpmos_c46
+ vdd gate pre_bl46_out
+ rom_256b_precharge_cell
Xpmos_c47
+ vdd gate pre_bl47_out
+ rom_256b_precharge_cell
Xpmos_c48
+ vdd gate pre_bl48_out
+ rom_256b_precharge_cell
Xpmos_c49
+ vdd gate pre_bl49_out
+ rom_256b_precharge_cell
Xpmos_c50
+ vdd gate pre_bl50_out
+ rom_256b_precharge_cell
Xpmos_c51
+ vdd gate pre_bl51_out
+ rom_256b_precharge_cell
Xpmos_c52
+ vdd gate pre_bl52_out
+ rom_256b_precharge_cell
Xpmos_c53
+ vdd gate pre_bl53_out
+ rom_256b_precharge_cell
Xpmos_c54
+ vdd gate pre_bl54_out
+ rom_256b_precharge_cell
Xpmos_c55
+ vdd gate pre_bl55_out
+ rom_256b_precharge_cell
Xpmos_c56
+ vdd gate pre_bl56_out
+ rom_256b_precharge_cell
Xpmos_c57
+ vdd gate pre_bl57_out
+ rom_256b_precharge_cell
Xpmos_c58
+ vdd gate pre_bl58_out
+ rom_256b_precharge_cell
Xpmos_c59
+ vdd gate pre_bl59_out
+ rom_256b_precharge_cell
Xpmos_c60
+ vdd gate pre_bl60_out
+ rom_256b_precharge_cell
Xpmos_c61
+ vdd gate pre_bl61_out
+ rom_256b_precharge_cell
Xpmos_c62
+ vdd gate pre_bl62_out
+ rom_256b_precharge_cell
Xpmos_c63
+ vdd gate pre_bl63_out
+ rom_256b_precharge_cell
Xpmos_c64
+ vdd gate pre_bl64_out
+ rom_256b_precharge_cell
Xpmos_c65
+ vdd gate pre_bl65_out
+ rom_256b_precharge_cell
Xpmos_c66
+ vdd gate pre_bl66_out
+ rom_256b_precharge_cell
Xpmos_c67
+ vdd gate pre_bl67_out
+ rom_256b_precharge_cell
Xpmos_c68
+ vdd gate pre_bl68_out
+ rom_256b_precharge_cell
Xpmos_c69
+ vdd gate pre_bl69_out
+ rom_256b_precharge_cell
Xpmos_c70
+ vdd gate pre_bl70_out
+ rom_256b_precharge_cell
Xpmos_c71
+ vdd gate pre_bl71_out
+ rom_256b_precharge_cell
Xpmos_c72
+ vdd gate pre_bl72_out
+ rom_256b_precharge_cell
Xpmos_c73
+ vdd gate pre_bl73_out
+ rom_256b_precharge_cell
Xpmos_c74
+ vdd gate pre_bl74_out
+ rom_256b_precharge_cell
Xpmos_c75
+ vdd gate pre_bl75_out
+ rom_256b_precharge_cell
Xpmos_c76
+ vdd gate pre_bl76_out
+ rom_256b_precharge_cell
Xpmos_c77
+ vdd gate pre_bl77_out
+ rom_256b_precharge_cell
Xpmos_c78
+ vdd gate pre_bl78_out
+ rom_256b_precharge_cell
Xpmos_c79
+ vdd gate pre_bl79_out
+ rom_256b_precharge_cell
Xpmos_c80
+ vdd gate pre_bl80_out
+ rom_256b_precharge_cell
Xpmos_c81
+ vdd gate pre_bl81_out
+ rom_256b_precharge_cell
Xpmos_c82
+ vdd gate pre_bl82_out
+ rom_256b_precharge_cell
Xpmos_c83
+ vdd gate pre_bl83_out
+ rom_256b_precharge_cell
Xpmos_c84
+ vdd gate pre_bl84_out
+ rom_256b_precharge_cell
Xpmos_c85
+ vdd gate pre_bl85_out
+ rom_256b_precharge_cell
Xpmos_c86
+ vdd gate pre_bl86_out
+ rom_256b_precharge_cell
Xpmos_c87
+ vdd gate pre_bl87_out
+ rom_256b_precharge_cell
Xpmos_c88
+ vdd gate pre_bl88_out
+ rom_256b_precharge_cell
Xpmos_c89
+ vdd gate pre_bl89_out
+ rom_256b_precharge_cell
Xpmos_c90
+ vdd gate pre_bl90_out
+ rom_256b_precharge_cell
Xpmos_c91
+ vdd gate pre_bl91_out
+ rom_256b_precharge_cell
Xpmos_c92
+ vdd gate pre_bl92_out
+ rom_256b_precharge_cell
Xpmos_c93
+ vdd gate pre_bl93_out
+ rom_256b_precharge_cell
Xpmos_c94
+ vdd gate pre_bl94_out
+ rom_256b_precharge_cell
Xpmos_c95
+ vdd gate pre_bl95_out
+ rom_256b_precharge_cell
Xpmos_c96
+ vdd gate pre_bl96_out
+ rom_256b_precharge_cell
Xpmos_c97
+ vdd gate pre_bl97_out
+ rom_256b_precharge_cell
Xpmos_c98
+ vdd gate pre_bl98_out
+ rom_256b_precharge_cell
Xpmos_c99
+ vdd gate pre_bl99_out
+ rom_256b_precharge_cell
Xpmos_c100
+ vdd gate pre_bl100_out
+ rom_256b_precharge_cell
Xpmos_c101
+ vdd gate pre_bl101_out
+ rom_256b_precharge_cell
Xpmos_c102
+ vdd gate pre_bl102_out
+ rom_256b_precharge_cell
Xpmos_c103
+ vdd gate pre_bl103_out
+ rom_256b_precharge_cell
Xpmos_c104
+ vdd gate pre_bl104_out
+ rom_256b_precharge_cell
Xpmos_c105
+ vdd gate pre_bl105_out
+ rom_256b_precharge_cell
Xpmos_c106
+ vdd gate pre_bl106_out
+ rom_256b_precharge_cell
Xpmos_c107
+ vdd gate pre_bl107_out
+ rom_256b_precharge_cell
Xpmos_c108
+ vdd gate pre_bl108_out
+ rom_256b_precharge_cell
Xpmos_c109
+ vdd gate pre_bl109_out
+ rom_256b_precharge_cell
Xpmos_c110
+ vdd gate pre_bl110_out
+ rom_256b_precharge_cell
Xpmos_c111
+ vdd gate pre_bl111_out
+ rom_256b_precharge_cell
Xpmos_c112
+ vdd gate pre_bl112_out
+ rom_256b_precharge_cell
Xpmos_c113
+ vdd gate pre_bl113_out
+ rom_256b_precharge_cell
Xpmos_c114
+ vdd gate pre_bl114_out
+ rom_256b_precharge_cell
Xpmos_c115
+ vdd gate pre_bl115_out
+ rom_256b_precharge_cell
Xpmos_c116
+ vdd gate pre_bl116_out
+ rom_256b_precharge_cell
Xpmos_c117
+ vdd gate pre_bl117_out
+ rom_256b_precharge_cell
Xpmos_c118
+ vdd gate pre_bl118_out
+ rom_256b_precharge_cell
Xpmos_c119
+ vdd gate pre_bl119_out
+ rom_256b_precharge_cell
Xpmos_c120
+ vdd gate pre_bl120_out
+ rom_256b_precharge_cell
Xpmos_c121
+ vdd gate pre_bl121_out
+ rom_256b_precharge_cell
Xpmos_c122
+ vdd gate pre_bl122_out
+ rom_256b_precharge_cell
Xpmos_c123
+ vdd gate pre_bl123_out
+ rom_256b_precharge_cell
Xpmos_c124
+ vdd gate pre_bl124_out
+ rom_256b_precharge_cell
Xpmos_c125
+ vdd gate pre_bl125_out
+ rom_256b_precharge_cell
Xpmos_c126
+ vdd gate pre_bl126_out
+ rom_256b_precharge_cell
Xpmos_c127
+ vdd gate pre_bl127_out
+ rom_256b_precharge_cell
Xpmos_c128
+ vdd gate pre_bl128_out
+ rom_256b_precharge_cell
Xpmos_c129
+ vdd gate pre_bl129_out
+ rom_256b_precharge_cell
Xpmos_c130
+ vdd gate pre_bl130_out
+ rom_256b_precharge_cell
Xpmos_c131
+ vdd gate pre_bl131_out
+ rom_256b_precharge_cell
Xpmos_c132
+ vdd gate pre_bl132_out
+ rom_256b_precharge_cell
Xpmos_c133
+ vdd gate pre_bl133_out
+ rom_256b_precharge_cell
Xpmos_c134
+ vdd gate pre_bl134_out
+ rom_256b_precharge_cell
Xpmos_c135
+ vdd gate pre_bl135_out
+ rom_256b_precharge_cell
Xpmos_c136
+ vdd gate pre_bl136_out
+ rom_256b_precharge_cell
Xpmos_c137
+ vdd gate pre_bl137_out
+ rom_256b_precharge_cell
Xpmos_c138
+ vdd gate pre_bl138_out
+ rom_256b_precharge_cell
Xpmos_c139
+ vdd gate pre_bl139_out
+ rom_256b_precharge_cell
Xpmos_c140
+ vdd gate pre_bl140_out
+ rom_256b_precharge_cell
Xpmos_c141
+ vdd gate pre_bl141_out
+ rom_256b_precharge_cell
Xpmos_c142
+ vdd gate pre_bl142_out
+ rom_256b_precharge_cell
Xpmos_c143
+ vdd gate pre_bl143_out
+ rom_256b_precharge_cell
Xpmos_c144
+ vdd gate pre_bl144_out
+ rom_256b_precharge_cell
Xpmos_c145
+ vdd gate pre_bl145_out
+ rom_256b_precharge_cell
Xpmos_c146
+ vdd gate pre_bl146_out
+ rom_256b_precharge_cell
Xpmos_c147
+ vdd gate pre_bl147_out
+ rom_256b_precharge_cell
Xpmos_c148
+ vdd gate pre_bl148_out
+ rom_256b_precharge_cell
Xpmos_c149
+ vdd gate pre_bl149_out
+ rom_256b_precharge_cell
Xpmos_c150
+ vdd gate pre_bl150_out
+ rom_256b_precharge_cell
Xpmos_c151
+ vdd gate pre_bl151_out
+ rom_256b_precharge_cell
Xpmos_c152
+ vdd gate pre_bl152_out
+ rom_256b_precharge_cell
Xpmos_c153
+ vdd gate pre_bl153_out
+ rom_256b_precharge_cell
Xpmos_c154
+ vdd gate pre_bl154_out
+ rom_256b_precharge_cell
Xpmos_c155
+ vdd gate pre_bl155_out
+ rom_256b_precharge_cell
Xpmos_c156
+ vdd gate pre_bl156_out
+ rom_256b_precharge_cell
Xpmos_c157
+ vdd gate pre_bl157_out
+ rom_256b_precharge_cell
Xpmos_c158
+ vdd gate pre_bl158_out
+ rom_256b_precharge_cell
Xpmos_c159
+ vdd gate pre_bl159_out
+ rom_256b_precharge_cell
Xpmos_c160
+ vdd gate pre_bl160_out
+ rom_256b_precharge_cell
Xpmos_c161
+ vdd gate pre_bl161_out
+ rom_256b_precharge_cell
Xpmos_c162
+ vdd gate pre_bl162_out
+ rom_256b_precharge_cell
Xpmos_c163
+ vdd gate pre_bl163_out
+ rom_256b_precharge_cell
Xpmos_c164
+ vdd gate pre_bl164_out
+ rom_256b_precharge_cell
Xpmos_c165
+ vdd gate pre_bl165_out
+ rom_256b_precharge_cell
Xpmos_c166
+ vdd gate pre_bl166_out
+ rom_256b_precharge_cell
Xpmos_c167
+ vdd gate pre_bl167_out
+ rom_256b_precharge_cell
Xpmos_c168
+ vdd gate pre_bl168_out
+ rom_256b_precharge_cell
Xpmos_c169
+ vdd gate pre_bl169_out
+ rom_256b_precharge_cell
Xpmos_c170
+ vdd gate pre_bl170_out
+ rom_256b_precharge_cell
Xpmos_c171
+ vdd gate pre_bl171_out
+ rom_256b_precharge_cell
Xpmos_c172
+ vdd gate pre_bl172_out
+ rom_256b_precharge_cell
Xpmos_c173
+ vdd gate pre_bl173_out
+ rom_256b_precharge_cell
Xpmos_c174
+ vdd gate pre_bl174_out
+ rom_256b_precharge_cell
Xpmos_c175
+ vdd gate pre_bl175_out
+ rom_256b_precharge_cell
Xpmos_c176
+ vdd gate pre_bl176_out
+ rom_256b_precharge_cell
Xpmos_c177
+ vdd gate pre_bl177_out
+ rom_256b_precharge_cell
Xpmos_c178
+ vdd gate pre_bl178_out
+ rom_256b_precharge_cell
Xpmos_c179
+ vdd gate pre_bl179_out
+ rom_256b_precharge_cell
Xpmos_c180
+ vdd gate pre_bl180_out
+ rom_256b_precharge_cell
Xpmos_c181
+ vdd gate pre_bl181_out
+ rom_256b_precharge_cell
Xpmos_c182
+ vdd gate pre_bl182_out
+ rom_256b_precharge_cell
Xpmos_c183
+ vdd gate pre_bl183_out
+ rom_256b_precharge_cell
Xpmos_c184
+ vdd gate pre_bl184_out
+ rom_256b_precharge_cell
Xpmos_c185
+ vdd gate pre_bl185_out
+ rom_256b_precharge_cell
Xpmos_c186
+ vdd gate pre_bl186_out
+ rom_256b_precharge_cell
Xpmos_c187
+ vdd gate pre_bl187_out
+ rom_256b_precharge_cell
Xpmos_c188
+ vdd gate pre_bl188_out
+ rom_256b_precharge_cell
Xpmos_c189
+ vdd gate pre_bl189_out
+ rom_256b_precharge_cell
Xpmos_c190
+ vdd gate pre_bl190_out
+ rom_256b_precharge_cell
Xpmos_c191
+ vdd gate pre_bl191_out
+ rom_256b_precharge_cell
Xpmos_c192
+ vdd gate pre_bl192_out
+ rom_256b_precharge_cell
Xpmos_c193
+ vdd gate pre_bl193_out
+ rom_256b_precharge_cell
Xpmos_c194
+ vdd gate pre_bl194_out
+ rom_256b_precharge_cell
Xpmos_c195
+ vdd gate pre_bl195_out
+ rom_256b_precharge_cell
Xpmos_c196
+ vdd gate pre_bl196_out
+ rom_256b_precharge_cell
Xpmos_c197
+ vdd gate pre_bl197_out
+ rom_256b_precharge_cell
Xpmos_c198
+ vdd gate pre_bl198_out
+ rom_256b_precharge_cell
Xpmos_c199
+ vdd gate pre_bl199_out
+ rom_256b_precharge_cell
Xpmos_c200
+ vdd gate pre_bl200_out
+ rom_256b_precharge_cell
Xpmos_c201
+ vdd gate pre_bl201_out
+ rom_256b_precharge_cell
Xpmos_c202
+ vdd gate pre_bl202_out
+ rom_256b_precharge_cell
Xpmos_c203
+ vdd gate pre_bl203_out
+ rom_256b_precharge_cell
Xpmos_c204
+ vdd gate pre_bl204_out
+ rom_256b_precharge_cell
Xpmos_c205
+ vdd gate pre_bl205_out
+ rom_256b_precharge_cell
Xpmos_c206
+ vdd gate pre_bl206_out
+ rom_256b_precharge_cell
Xpmos_c207
+ vdd gate pre_bl207_out
+ rom_256b_precharge_cell
Xpmos_c208
+ vdd gate pre_bl208_out
+ rom_256b_precharge_cell
Xpmos_c209
+ vdd gate pre_bl209_out
+ rom_256b_precharge_cell
Xpmos_c210
+ vdd gate pre_bl210_out
+ rom_256b_precharge_cell
Xpmos_c211
+ vdd gate pre_bl211_out
+ rom_256b_precharge_cell
Xpmos_c212
+ vdd gate pre_bl212_out
+ rom_256b_precharge_cell
Xpmos_c213
+ vdd gate pre_bl213_out
+ rom_256b_precharge_cell
Xpmos_c214
+ vdd gate pre_bl214_out
+ rom_256b_precharge_cell
Xpmos_c215
+ vdd gate pre_bl215_out
+ rom_256b_precharge_cell
Xpmos_c216
+ vdd gate pre_bl216_out
+ rom_256b_precharge_cell
Xpmos_c217
+ vdd gate pre_bl217_out
+ rom_256b_precharge_cell
Xpmos_c218
+ vdd gate pre_bl218_out
+ rom_256b_precharge_cell
Xpmos_c219
+ vdd gate pre_bl219_out
+ rom_256b_precharge_cell
Xpmos_c220
+ vdd gate pre_bl220_out
+ rom_256b_precharge_cell
Xpmos_c221
+ vdd gate pre_bl221_out
+ rom_256b_precharge_cell
Xpmos_c222
+ vdd gate pre_bl222_out
+ rom_256b_precharge_cell
Xpmos_c223
+ vdd gate pre_bl223_out
+ rom_256b_precharge_cell
Xpmos_c224
+ vdd gate pre_bl224_out
+ rom_256b_precharge_cell
Xpmos_c225
+ vdd gate pre_bl225_out
+ rom_256b_precharge_cell
Xpmos_c226
+ vdd gate pre_bl226_out
+ rom_256b_precharge_cell
Xpmos_c227
+ vdd gate pre_bl227_out
+ rom_256b_precharge_cell
Xpmos_c228
+ vdd gate pre_bl228_out
+ rom_256b_precharge_cell
Xpmos_c229
+ vdd gate pre_bl229_out
+ rom_256b_precharge_cell
Xpmos_c230
+ vdd gate pre_bl230_out
+ rom_256b_precharge_cell
Xpmos_c231
+ vdd gate pre_bl231_out
+ rom_256b_precharge_cell
Xpmos_c232
+ vdd gate pre_bl232_out
+ rom_256b_precharge_cell
Xpmos_c233
+ vdd gate pre_bl233_out
+ rom_256b_precharge_cell
Xpmos_c234
+ vdd gate pre_bl234_out
+ rom_256b_precharge_cell
Xpmos_c235
+ vdd gate pre_bl235_out
+ rom_256b_precharge_cell
Xpmos_c236
+ vdd gate pre_bl236_out
+ rom_256b_precharge_cell
Xpmos_c237
+ vdd gate pre_bl237_out
+ rom_256b_precharge_cell
Xpmos_c238
+ vdd gate pre_bl238_out
+ rom_256b_precharge_cell
Xpmos_c239
+ vdd gate pre_bl239_out
+ rom_256b_precharge_cell
Xpmos_c240
+ vdd gate pre_bl240_out
+ rom_256b_precharge_cell
Xpmos_c241
+ vdd gate pre_bl241_out
+ rom_256b_precharge_cell
Xpmos_c242
+ vdd gate pre_bl242_out
+ rom_256b_precharge_cell
Xpmos_c243
+ vdd gate pre_bl243_out
+ rom_256b_precharge_cell
Xpmos_c244
+ vdd gate pre_bl244_out
+ rom_256b_precharge_cell
Xpmos_c245
+ vdd gate pre_bl245_out
+ rom_256b_precharge_cell
Xpmos_c246
+ vdd gate pre_bl246_out
+ rom_256b_precharge_cell
Xpmos_c247
+ vdd gate pre_bl247_out
+ rom_256b_precharge_cell
Xpmos_c248
+ vdd gate pre_bl248_out
+ rom_256b_precharge_cell
Xpmos_c249
+ vdd gate pre_bl249_out
+ rom_256b_precharge_cell
Xpmos_c250
+ vdd gate pre_bl250_out
+ rom_256b_precharge_cell
Xpmos_c251
+ vdd gate pre_bl251_out
+ rom_256b_precharge_cell
Xpmos_c252
+ vdd gate pre_bl252_out
+ rom_256b_precharge_cell
Xpmos_c253
+ vdd gate pre_bl253_out
+ rom_256b_precharge_cell
Xpmos_c254
+ vdd gate pre_bl254_out
+ rom_256b_precharge_cell
Xpmos_c255
+ vdd gate pre_bl255_out
+ rom_256b_precharge_cell
.ENDS rom_256b_rom_precharge_array

.SUBCKT rom_256b_rom_base_array
+ bl_0_0 bl_0_1 bl_0_2 bl_0_3 bl_0_4 bl_0_5 bl_0_6 bl_0_7 bl_0_8 bl_0_9
+ bl_0_10 bl_0_11 bl_0_12 bl_0_13 bl_0_14 bl_0_15 bl_0_16 bl_0_17
+ bl_0_18 bl_0_19 bl_0_20 bl_0_21 bl_0_22 bl_0_23 bl_0_24 bl_0_25
+ bl_0_26 bl_0_27 bl_0_28 bl_0_29 bl_0_30 bl_0_31 bl_0_32 bl_0_33
+ bl_0_34 bl_0_35 bl_0_36 bl_0_37 bl_0_38 bl_0_39 bl_0_40 bl_0_41
+ bl_0_42 bl_0_43 bl_0_44 bl_0_45 bl_0_46 bl_0_47 bl_0_48 bl_0_49
+ bl_0_50 bl_0_51 bl_0_52 bl_0_53 bl_0_54 bl_0_55 bl_0_56 bl_0_57
+ bl_0_58 bl_0_59 bl_0_60 bl_0_61 bl_0_62 bl_0_63 bl_0_64 bl_0_65
+ bl_0_66 bl_0_67 bl_0_68 bl_0_69 bl_0_70 bl_0_71 bl_0_72 bl_0_73
+ bl_0_74 bl_0_75 bl_0_76 bl_0_77 bl_0_78 bl_0_79 bl_0_80 bl_0_81
+ bl_0_82 bl_0_83 bl_0_84 bl_0_85 bl_0_86 bl_0_87 bl_0_88 bl_0_89
+ bl_0_90 bl_0_91 bl_0_92 bl_0_93 bl_0_94 bl_0_95 bl_0_96 bl_0_97
+ bl_0_98 bl_0_99 bl_0_100 bl_0_101 bl_0_102 bl_0_103 bl_0_104 bl_0_105
+ bl_0_106 bl_0_107 bl_0_108 bl_0_109 bl_0_110 bl_0_111 bl_0_112
+ bl_0_113 bl_0_114 bl_0_115 bl_0_116 bl_0_117 bl_0_118 bl_0_119
+ bl_0_120 bl_0_121 bl_0_122 bl_0_123 bl_0_124 bl_0_125 bl_0_126
+ bl_0_127 bl_0_128 bl_0_129 bl_0_130 bl_0_131 bl_0_132 bl_0_133
+ bl_0_134 bl_0_135 bl_0_136 bl_0_137 bl_0_138 bl_0_139 bl_0_140
+ bl_0_141 bl_0_142 bl_0_143 bl_0_144 bl_0_145 bl_0_146 bl_0_147
+ bl_0_148 bl_0_149 bl_0_150 bl_0_151 bl_0_152 bl_0_153 bl_0_154
+ bl_0_155 bl_0_156 bl_0_157 bl_0_158 bl_0_159 bl_0_160 bl_0_161
+ bl_0_162 bl_0_163 bl_0_164 bl_0_165 bl_0_166 bl_0_167 bl_0_168
+ bl_0_169 bl_0_170 bl_0_171 bl_0_172 bl_0_173 bl_0_174 bl_0_175
+ bl_0_176 bl_0_177 bl_0_178 bl_0_179 bl_0_180 bl_0_181 bl_0_182
+ bl_0_183 bl_0_184 bl_0_185 bl_0_186 bl_0_187 bl_0_188 bl_0_189
+ bl_0_190 bl_0_191 bl_0_192 bl_0_193 bl_0_194 bl_0_195 bl_0_196
+ bl_0_197 bl_0_198 bl_0_199 bl_0_200 bl_0_201 bl_0_202 bl_0_203
+ bl_0_204 bl_0_205 bl_0_206 bl_0_207 bl_0_208 bl_0_209 bl_0_210
+ bl_0_211 bl_0_212 bl_0_213 bl_0_214 bl_0_215 bl_0_216 bl_0_217
+ bl_0_218 bl_0_219 bl_0_220 bl_0_221 bl_0_222 bl_0_223 bl_0_224
+ bl_0_225 bl_0_226 bl_0_227 bl_0_228 bl_0_229 bl_0_230 bl_0_231
+ bl_0_232 bl_0_233 bl_0_234 bl_0_235 bl_0_236 bl_0_237 bl_0_238
+ bl_0_239 bl_0_240 bl_0_241 bl_0_242 bl_0_243 bl_0_244 bl_0_245
+ bl_0_246 bl_0_247 bl_0_248 bl_0_249 bl_0_250 bl_0_251 bl_0_252
+ bl_0_253 bl_0_254 bl_0_255 wl_0_0 wl_0_1 wl_0_2 wl_0_3 wl_0_4 wl_0_5
+ wl_0_6 wl_0_7 precharge vdd gnd
* OUTPUT: bl_0_0 
* OUTPUT: bl_0_1 
* OUTPUT: bl_0_2 
* OUTPUT: bl_0_3 
* OUTPUT: bl_0_4 
* OUTPUT: bl_0_5 
* OUTPUT: bl_0_6 
* OUTPUT: bl_0_7 
* OUTPUT: bl_0_8 
* OUTPUT: bl_0_9 
* OUTPUT: bl_0_10 
* OUTPUT: bl_0_11 
* OUTPUT: bl_0_12 
* OUTPUT: bl_0_13 
* OUTPUT: bl_0_14 
* OUTPUT: bl_0_15 
* OUTPUT: bl_0_16 
* OUTPUT: bl_0_17 
* OUTPUT: bl_0_18 
* OUTPUT: bl_0_19 
* OUTPUT: bl_0_20 
* OUTPUT: bl_0_21 
* OUTPUT: bl_0_22 
* OUTPUT: bl_0_23 
* OUTPUT: bl_0_24 
* OUTPUT: bl_0_25 
* OUTPUT: bl_0_26 
* OUTPUT: bl_0_27 
* OUTPUT: bl_0_28 
* OUTPUT: bl_0_29 
* OUTPUT: bl_0_30 
* OUTPUT: bl_0_31 
* OUTPUT: bl_0_32 
* OUTPUT: bl_0_33 
* OUTPUT: bl_0_34 
* OUTPUT: bl_0_35 
* OUTPUT: bl_0_36 
* OUTPUT: bl_0_37 
* OUTPUT: bl_0_38 
* OUTPUT: bl_0_39 
* OUTPUT: bl_0_40 
* OUTPUT: bl_0_41 
* OUTPUT: bl_0_42 
* OUTPUT: bl_0_43 
* OUTPUT: bl_0_44 
* OUTPUT: bl_0_45 
* OUTPUT: bl_0_46 
* OUTPUT: bl_0_47 
* OUTPUT: bl_0_48 
* OUTPUT: bl_0_49 
* OUTPUT: bl_0_50 
* OUTPUT: bl_0_51 
* OUTPUT: bl_0_52 
* OUTPUT: bl_0_53 
* OUTPUT: bl_0_54 
* OUTPUT: bl_0_55 
* OUTPUT: bl_0_56 
* OUTPUT: bl_0_57 
* OUTPUT: bl_0_58 
* OUTPUT: bl_0_59 
* OUTPUT: bl_0_60 
* OUTPUT: bl_0_61 
* OUTPUT: bl_0_62 
* OUTPUT: bl_0_63 
* OUTPUT: bl_0_64 
* OUTPUT: bl_0_65 
* OUTPUT: bl_0_66 
* OUTPUT: bl_0_67 
* OUTPUT: bl_0_68 
* OUTPUT: bl_0_69 
* OUTPUT: bl_0_70 
* OUTPUT: bl_0_71 
* OUTPUT: bl_0_72 
* OUTPUT: bl_0_73 
* OUTPUT: bl_0_74 
* OUTPUT: bl_0_75 
* OUTPUT: bl_0_76 
* OUTPUT: bl_0_77 
* OUTPUT: bl_0_78 
* OUTPUT: bl_0_79 
* OUTPUT: bl_0_80 
* OUTPUT: bl_0_81 
* OUTPUT: bl_0_82 
* OUTPUT: bl_0_83 
* OUTPUT: bl_0_84 
* OUTPUT: bl_0_85 
* OUTPUT: bl_0_86 
* OUTPUT: bl_0_87 
* OUTPUT: bl_0_88 
* OUTPUT: bl_0_89 
* OUTPUT: bl_0_90 
* OUTPUT: bl_0_91 
* OUTPUT: bl_0_92 
* OUTPUT: bl_0_93 
* OUTPUT: bl_0_94 
* OUTPUT: bl_0_95 
* OUTPUT: bl_0_96 
* OUTPUT: bl_0_97 
* OUTPUT: bl_0_98 
* OUTPUT: bl_0_99 
* OUTPUT: bl_0_100 
* OUTPUT: bl_0_101 
* OUTPUT: bl_0_102 
* OUTPUT: bl_0_103 
* OUTPUT: bl_0_104 
* OUTPUT: bl_0_105 
* OUTPUT: bl_0_106 
* OUTPUT: bl_0_107 
* OUTPUT: bl_0_108 
* OUTPUT: bl_0_109 
* OUTPUT: bl_0_110 
* OUTPUT: bl_0_111 
* OUTPUT: bl_0_112 
* OUTPUT: bl_0_113 
* OUTPUT: bl_0_114 
* OUTPUT: bl_0_115 
* OUTPUT: bl_0_116 
* OUTPUT: bl_0_117 
* OUTPUT: bl_0_118 
* OUTPUT: bl_0_119 
* OUTPUT: bl_0_120 
* OUTPUT: bl_0_121 
* OUTPUT: bl_0_122 
* OUTPUT: bl_0_123 
* OUTPUT: bl_0_124 
* OUTPUT: bl_0_125 
* OUTPUT: bl_0_126 
* OUTPUT: bl_0_127 
* OUTPUT: bl_0_128 
* OUTPUT: bl_0_129 
* OUTPUT: bl_0_130 
* OUTPUT: bl_0_131 
* OUTPUT: bl_0_132 
* OUTPUT: bl_0_133 
* OUTPUT: bl_0_134 
* OUTPUT: bl_0_135 
* OUTPUT: bl_0_136 
* OUTPUT: bl_0_137 
* OUTPUT: bl_0_138 
* OUTPUT: bl_0_139 
* OUTPUT: bl_0_140 
* OUTPUT: bl_0_141 
* OUTPUT: bl_0_142 
* OUTPUT: bl_0_143 
* OUTPUT: bl_0_144 
* OUTPUT: bl_0_145 
* OUTPUT: bl_0_146 
* OUTPUT: bl_0_147 
* OUTPUT: bl_0_148 
* OUTPUT: bl_0_149 
* OUTPUT: bl_0_150 
* OUTPUT: bl_0_151 
* OUTPUT: bl_0_152 
* OUTPUT: bl_0_153 
* OUTPUT: bl_0_154 
* OUTPUT: bl_0_155 
* OUTPUT: bl_0_156 
* OUTPUT: bl_0_157 
* OUTPUT: bl_0_158 
* OUTPUT: bl_0_159 
* OUTPUT: bl_0_160 
* OUTPUT: bl_0_161 
* OUTPUT: bl_0_162 
* OUTPUT: bl_0_163 
* OUTPUT: bl_0_164 
* OUTPUT: bl_0_165 
* OUTPUT: bl_0_166 
* OUTPUT: bl_0_167 
* OUTPUT: bl_0_168 
* OUTPUT: bl_0_169 
* OUTPUT: bl_0_170 
* OUTPUT: bl_0_171 
* OUTPUT: bl_0_172 
* OUTPUT: bl_0_173 
* OUTPUT: bl_0_174 
* OUTPUT: bl_0_175 
* OUTPUT: bl_0_176 
* OUTPUT: bl_0_177 
* OUTPUT: bl_0_178 
* OUTPUT: bl_0_179 
* OUTPUT: bl_0_180 
* OUTPUT: bl_0_181 
* OUTPUT: bl_0_182 
* OUTPUT: bl_0_183 
* OUTPUT: bl_0_184 
* OUTPUT: bl_0_185 
* OUTPUT: bl_0_186 
* OUTPUT: bl_0_187 
* OUTPUT: bl_0_188 
* OUTPUT: bl_0_189 
* OUTPUT: bl_0_190 
* OUTPUT: bl_0_191 
* OUTPUT: bl_0_192 
* OUTPUT: bl_0_193 
* OUTPUT: bl_0_194 
* OUTPUT: bl_0_195 
* OUTPUT: bl_0_196 
* OUTPUT: bl_0_197 
* OUTPUT: bl_0_198 
* OUTPUT: bl_0_199 
* OUTPUT: bl_0_200 
* OUTPUT: bl_0_201 
* OUTPUT: bl_0_202 
* OUTPUT: bl_0_203 
* OUTPUT: bl_0_204 
* OUTPUT: bl_0_205 
* OUTPUT: bl_0_206 
* OUTPUT: bl_0_207 
* OUTPUT: bl_0_208 
* OUTPUT: bl_0_209 
* OUTPUT: bl_0_210 
* OUTPUT: bl_0_211 
* OUTPUT: bl_0_212 
* OUTPUT: bl_0_213 
* OUTPUT: bl_0_214 
* OUTPUT: bl_0_215 
* OUTPUT: bl_0_216 
* OUTPUT: bl_0_217 
* OUTPUT: bl_0_218 
* OUTPUT: bl_0_219 
* OUTPUT: bl_0_220 
* OUTPUT: bl_0_221 
* OUTPUT: bl_0_222 
* OUTPUT: bl_0_223 
* OUTPUT: bl_0_224 
* OUTPUT: bl_0_225 
* OUTPUT: bl_0_226 
* OUTPUT: bl_0_227 
* OUTPUT: bl_0_228 
* OUTPUT: bl_0_229 
* OUTPUT: bl_0_230 
* OUTPUT: bl_0_231 
* OUTPUT: bl_0_232 
* OUTPUT: bl_0_233 
* OUTPUT: bl_0_234 
* OUTPUT: bl_0_235 
* OUTPUT: bl_0_236 
* OUTPUT: bl_0_237 
* OUTPUT: bl_0_238 
* OUTPUT: bl_0_239 
* OUTPUT: bl_0_240 
* OUTPUT: bl_0_241 
* OUTPUT: bl_0_242 
* OUTPUT: bl_0_243 
* OUTPUT: bl_0_244 
* OUTPUT: bl_0_245 
* OUTPUT: bl_0_246 
* OUTPUT: bl_0_247 
* OUTPUT: bl_0_248 
* OUTPUT: bl_0_249 
* OUTPUT: bl_0_250 
* OUTPUT: bl_0_251 
* OUTPUT: bl_0_252 
* OUTPUT: bl_0_253 
* OUTPUT: bl_0_254 
* OUTPUT: bl_0_255 
* INPUT : wl_0_0 
* INPUT : wl_0_1 
* INPUT : wl_0_2 
* INPUT : wl_0_3 
* INPUT : wl_0_4 
* INPUT : wl_0_5 
* INPUT : wl_0_6 
* INPUT : wl_0_7 
* INPUT : precharge 
* POWER : vdd 
* GROUND: gnd 
Xbit_r0_c0
+ bl_int_0_0 bl_0_0 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c1
+ bl_0_1 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c2
+ bl_0_2 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c3
+ bl_int_0_3 bl_0_3 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c4
+ bl_0_4 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c5
+ bl_int_0_5 bl_0_5 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c6
+ bl_0_6 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c7
+ bl_int_0_7 bl_0_7 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c8
+ bl_int_0_8 bl_0_8 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c9
+ bl_0_9 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c10
+ bl_int_0_10 bl_0_10 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c11
+ bl_0_11 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c12
+ bl_int_0_12 bl_0_12 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c13
+ bl_int_0_13 bl_0_13 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c14
+ bl_int_0_14 bl_0_14 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c15
+ bl_0_15 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c16
+ bl_int_0_16 bl_0_16 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c17
+ bl_int_0_17 bl_0_17 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c18
+ bl_0_18 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c19
+ bl_0_19 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c20
+ bl_0_20 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c21
+ bl_0_21 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c22
+ bl_int_0_22 bl_0_22 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c23
+ bl_int_0_23 bl_0_23 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c24
+ bl_int_0_24 bl_0_24 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c25
+ bl_int_0_25 bl_0_25 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c26
+ bl_int_0_26 bl_0_26 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c27
+ bl_int_0_27 bl_0_27 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c28
+ bl_int_0_28 bl_0_28 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c29
+ bl_0_29 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c30
+ bl_int_0_30 bl_0_30 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c31
+ bl_0_31 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c32
+ bl_0_32 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c33
+ bl_0_33 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c34
+ bl_0_34 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c35
+ bl_0_35 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c36
+ bl_0_36 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c37
+ bl_0_37 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c38
+ bl_0_38 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c39
+ bl_int_0_39 bl_0_39 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c40
+ bl_0_40 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c41
+ bl_0_41 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c42
+ bl_int_0_42 bl_0_42 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c43
+ bl_0_43 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c44
+ bl_0_44 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c45
+ bl_int_0_45 bl_0_45 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c46
+ bl_int_0_46 bl_0_46 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c47
+ bl_0_47 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c48
+ bl_int_0_48 bl_0_48 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c49
+ bl_int_0_49 bl_0_49 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c50
+ bl_0_50 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c51
+ bl_0_51 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c52
+ bl_int_0_52 bl_0_52 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c53
+ bl_int_0_53 bl_0_53 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c54
+ bl_0_54 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c55
+ bl_int_0_55 bl_0_55 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c56
+ bl_0_56 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c57
+ bl_0_57 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c58
+ bl_0_58 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c59
+ bl_int_0_59 bl_0_59 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c60
+ bl_0_60 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c61
+ bl_0_61 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c62
+ bl_int_0_62 bl_0_62 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c63
+ bl_int_0_63 bl_0_63 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c64
+ bl_0_64 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c65
+ bl_0_65 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c66
+ bl_0_66 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c67
+ bl_0_67 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c68
+ bl_int_0_68 bl_0_68 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c69
+ bl_int_0_69 bl_0_69 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c70
+ bl_0_70 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c71
+ bl_0_71 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c72
+ bl_0_72 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c73
+ bl_int_0_73 bl_0_73 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c74
+ bl_0_74 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c75
+ bl_0_75 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c76
+ bl_0_76 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c77
+ bl_int_0_77 bl_0_77 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c78
+ bl_0_78 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c79
+ bl_0_79 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c80
+ bl_int_0_80 bl_0_80 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c81
+ bl_int_0_81 bl_0_81 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c82
+ bl_int_0_82 bl_0_82 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c83
+ bl_0_83 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c84
+ bl_0_84 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c85
+ bl_0_85 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c86
+ bl_0_86 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c87
+ bl_0_87 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c88
+ bl_int_0_88 bl_0_88 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c89
+ bl_int_0_89 bl_0_89 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c90
+ bl_0_90 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c91
+ bl_int_0_91 bl_0_91 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c92
+ bl_int_0_92 bl_0_92 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c93
+ bl_0_93 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c94
+ bl_int_0_94 bl_0_94 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c95
+ bl_0_95 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c96
+ bl_int_0_96 bl_0_96 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c97
+ bl_int_0_97 bl_0_97 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c98
+ bl_int_0_98 bl_0_98 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c99
+ bl_0_99 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c100
+ bl_int_0_100 bl_0_100 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c101
+ bl_0_101 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c102
+ bl_0_102 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c103
+ bl_int_0_103 bl_0_103 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c104
+ bl_int_0_104 bl_0_104 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c105
+ bl_int_0_105 bl_0_105 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c106
+ bl_0_106 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c107
+ bl_int_0_107 bl_0_107 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c108
+ bl_0_108 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c109
+ bl_0_109 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c110
+ bl_int_0_110 bl_0_110 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c111
+ bl_0_111 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c112
+ bl_0_112 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c113
+ bl_int_0_113 bl_0_113 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c114
+ bl_0_114 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c115
+ bl_int_0_115 bl_0_115 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c116
+ bl_int_0_116 bl_0_116 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c117
+ bl_int_0_117 bl_0_117 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c118
+ bl_0_118 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c119
+ bl_0_119 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c120
+ bl_0_120 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c121
+ bl_0_121 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c122
+ bl_int_0_122 bl_0_122 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c123
+ bl_0_123 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c124
+ bl_int_0_124 bl_0_124 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c125
+ bl_0_125 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c126
+ bl_int_0_126 bl_0_126 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c127
+ bl_0_127 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c128
+ bl_0_128 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c129
+ bl_0_129 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c130
+ bl_0_130 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c131
+ bl_0_131 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c132
+ bl_int_0_132 bl_0_132 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c133
+ bl_0_133 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c134
+ bl_0_134 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c135
+ bl_0_135 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c136
+ bl_int_0_136 bl_0_136 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c137
+ bl_int_0_137 bl_0_137 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c138
+ bl_int_0_138 bl_0_138 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c139
+ bl_int_0_139 bl_0_139 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c140
+ bl_0_140 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c141
+ bl_int_0_141 bl_0_141 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c142
+ bl_int_0_142 bl_0_142 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c143
+ bl_int_0_143 bl_0_143 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c144
+ bl_int_0_144 bl_0_144 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c145
+ bl_int_0_145 bl_0_145 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c146
+ bl_int_0_146 bl_0_146 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c147
+ bl_int_0_147 bl_0_147 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c148
+ bl_0_148 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c149
+ bl_0_149 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c150
+ bl_int_0_150 bl_0_150 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c151
+ bl_0_151 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c152
+ bl_int_0_152 bl_0_152 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c153
+ bl_0_153 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c154
+ bl_0_154 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c155
+ bl_int_0_155 bl_0_155 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c156
+ bl_0_156 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c157
+ bl_0_157 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c158
+ bl_0_158 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c159
+ bl_int_0_159 bl_0_159 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c160
+ bl_int_0_160 bl_0_160 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c161
+ bl_int_0_161 bl_0_161 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c162
+ bl_0_162 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c163
+ bl_int_0_163 bl_0_163 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c164
+ bl_int_0_164 bl_0_164 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c165
+ bl_0_165 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c166
+ bl_int_0_166 bl_0_166 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c167
+ bl_int_0_167 bl_0_167 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c168
+ bl_0_168 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c169
+ bl_int_0_169 bl_0_169 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c170
+ bl_0_170 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c171
+ bl_int_0_171 bl_0_171 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c172
+ bl_int_0_172 bl_0_172 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c173
+ bl_0_173 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c174
+ bl_int_0_174 bl_0_174 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c175
+ bl_0_175 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c176
+ bl_0_176 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c177
+ bl_0_177 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c178
+ bl_0_178 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c179
+ bl_0_179 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c180
+ bl_int_0_180 bl_0_180 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c181
+ bl_int_0_181 bl_0_181 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c182
+ bl_0_182 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c183
+ bl_int_0_183 bl_0_183 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c184
+ bl_int_0_184 bl_0_184 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c185
+ bl_0_185 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c186
+ bl_int_0_186 bl_0_186 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c187
+ bl_int_0_187 bl_0_187 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c188
+ bl_int_0_188 bl_0_188 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c189
+ bl_0_189 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c190
+ bl_int_0_190 bl_0_190 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c191
+ bl_0_191 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c192
+ bl_0_192 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c193
+ bl_int_0_193 bl_0_193 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c194
+ bl_int_0_194 bl_0_194 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c195
+ bl_int_0_195 bl_0_195 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c196
+ bl_int_0_196 bl_0_196 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c197
+ bl_int_0_197 bl_0_197 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c198
+ bl_int_0_198 bl_0_198 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c199
+ bl_0_199 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c200
+ bl_0_200 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c201
+ bl_0_201 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c202
+ bl_int_0_202 bl_0_202 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c203
+ bl_int_0_203 bl_0_203 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c204
+ bl_int_0_204 bl_0_204 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c205
+ bl_0_205 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c206
+ bl_0_206 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c207
+ bl_int_0_207 bl_0_207 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c208
+ bl_int_0_208 bl_0_208 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c209
+ bl_0_209 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c210
+ bl_int_0_210 bl_0_210 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c211
+ bl_0_211 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c212
+ bl_0_212 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c213
+ bl_int_0_213 bl_0_213 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c214
+ bl_int_0_214 bl_0_214 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c215
+ bl_0_215 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c216
+ bl_int_0_216 bl_0_216 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c217
+ bl_0_217 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c218
+ bl_0_218 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c219
+ bl_int_0_219 bl_0_219 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c220
+ bl_0_220 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c221
+ bl_int_0_221 bl_0_221 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c222
+ bl_int_0_222 bl_0_222 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c223
+ bl_int_0_223 bl_0_223 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c224
+ bl_0_224 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c225
+ bl_0_225 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c226
+ bl_0_226 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c227
+ bl_0_227 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c228
+ bl_0_228 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c229
+ bl_int_0_229 bl_0_229 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c230
+ bl_int_0_230 bl_0_230 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c231
+ bl_int_0_231 bl_0_231 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c232
+ bl_int_0_232 bl_0_232 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c233
+ bl_int_0_233 bl_0_233 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c234
+ bl_0_234 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c235
+ bl_int_0_235 bl_0_235 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c236
+ bl_int_0_236 bl_0_236 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c237
+ bl_int_0_237 bl_0_237 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c238
+ bl_int_0_238 bl_0_238 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c239
+ bl_int_0_239 bl_0_239 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c240
+ bl_int_0_240 bl_0_240 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c241
+ bl_0_241 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c242
+ bl_int_0_242 bl_0_242 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c243
+ bl_int_0_243 bl_0_243 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c244
+ bl_0_244 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c245
+ bl_0_245 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c246
+ bl_int_0_246 bl_0_246 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c247
+ bl_int_0_247 bl_0_247 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c248
+ bl_int_0_248 bl_0_248 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c249
+ bl_int_0_249 bl_0_249 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c250
+ bl_int_0_250 bl_0_250 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c251
+ bl_int_0_251 bl_0_251 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c252
+ bl_int_0_252 bl_0_252 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c253
+ bl_int_0_253 bl_0_253 wl_0_0 gnd
+ rom_256b_rom_base_one_cell
Xbit_r0_c254
+ bl_0_254 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r0_c255
+ bl_0_255 wl_0_0 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c0
+ bl_int_1_0 bl_int_0_0 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c1
+ bl_0_1 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c2
+ bl_int_1_2 bl_0_2 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c3
+ bl_int_0_3 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c4
+ bl_0_4 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c5
+ bl_int_1_5 bl_int_0_5 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c6
+ bl_0_6 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c7
+ bl_int_0_7 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c8
+ bl_int_0_8 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c9
+ bl_0_9 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c10
+ bl_int_1_10 bl_int_0_10 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c11
+ bl_0_11 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c12
+ bl_int_0_12 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c13
+ bl_int_1_13 bl_int_0_13 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c14
+ bl_int_1_14 bl_int_0_14 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c15
+ bl_0_15 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c16
+ bl_int_0_16 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c17
+ bl_int_1_17 bl_int_0_17 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c18
+ bl_0_18 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c19
+ bl_0_19 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c20
+ bl_int_1_20 bl_0_20 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c21
+ bl_0_21 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c22
+ bl_int_0_22 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c23
+ bl_int_0_23 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c24
+ bl_int_0_24 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c25
+ bl_int_1_25 bl_int_0_25 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c26
+ bl_int_1_26 bl_int_0_26 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c27
+ bl_int_0_27 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c28
+ bl_int_0_28 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c29
+ bl_0_29 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c30
+ bl_int_0_30 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c31
+ bl_0_31 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c32
+ bl_int_1_32 bl_0_32 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c33
+ bl_0_33 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c34
+ bl_0_34 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c35
+ bl_0_35 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c36
+ bl_0_36 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c37
+ bl_0_37 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c38
+ bl_0_38 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c39
+ bl_int_0_39 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c40
+ bl_int_1_40 bl_0_40 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c41
+ bl_0_41 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c42
+ bl_int_1_42 bl_int_0_42 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c43
+ bl_int_1_43 bl_0_43 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c44
+ bl_0_44 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c45
+ bl_int_1_45 bl_int_0_45 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c46
+ bl_int_0_46 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c47
+ bl_0_47 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c48
+ bl_int_0_48 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c49
+ bl_int_0_49 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c50
+ bl_0_50 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c51
+ bl_int_1_51 bl_0_51 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c52
+ bl_int_1_52 bl_int_0_52 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c53
+ bl_int_0_53 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c54
+ bl_int_1_54 bl_0_54 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c55
+ bl_int_1_55 bl_int_0_55 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c56
+ bl_int_1_56 bl_0_56 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c57
+ bl_int_1_57 bl_0_57 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c58
+ bl_int_1_58 bl_0_58 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c59
+ bl_int_1_59 bl_int_0_59 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c60
+ bl_0_60 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c61
+ bl_0_61 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c62
+ bl_int_0_62 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c63
+ bl_int_1_63 bl_int_0_63 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c64
+ bl_0_64 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c65
+ bl_0_65 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c66
+ bl_0_66 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c67
+ bl_0_67 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c68
+ bl_int_1_68 bl_int_0_68 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c69
+ bl_int_1_69 bl_int_0_69 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c70
+ bl_int_1_70 bl_0_70 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c71
+ bl_0_71 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c72
+ bl_0_72 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c73
+ bl_int_0_73 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c74
+ bl_int_1_74 bl_0_74 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c75
+ bl_int_1_75 bl_0_75 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c76
+ bl_0_76 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c77
+ bl_int_1_77 bl_int_0_77 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c78
+ bl_int_1_78 bl_0_78 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c79
+ bl_int_1_79 bl_0_79 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c80
+ bl_int_1_80 bl_int_0_80 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c81
+ bl_int_1_81 bl_int_0_81 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c82
+ bl_int_1_82 bl_int_0_82 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c83
+ bl_int_1_83 bl_0_83 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c84
+ bl_0_84 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c85
+ bl_int_1_85 bl_0_85 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c86
+ bl_0_86 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c87
+ bl_int_1_87 bl_0_87 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c88
+ bl_int_0_88 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c89
+ bl_int_0_89 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c90
+ bl_0_90 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c91
+ bl_int_0_91 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c92
+ bl_int_0_92 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c93
+ bl_0_93 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c94
+ bl_int_1_94 bl_int_0_94 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c95
+ bl_0_95 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c96
+ bl_int_0_96 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c97
+ bl_int_1_97 bl_int_0_97 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c98
+ bl_int_1_98 bl_int_0_98 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c99
+ bl_0_99 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c100
+ bl_int_0_100 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c101
+ bl_0_101 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c102
+ bl_0_102 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c103
+ bl_int_0_103 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c104
+ bl_int_0_104 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c105
+ bl_int_0_105 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c106
+ bl_int_1_106 bl_0_106 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c107
+ bl_int_0_107 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c108
+ bl_0_108 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c109
+ bl_0_109 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c110
+ bl_int_0_110 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c111
+ bl_0_111 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c112
+ bl_int_1_112 bl_0_112 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c113
+ bl_int_0_113 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c114
+ bl_int_1_114 bl_0_114 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c115
+ bl_int_1_115 bl_int_0_115 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c116
+ bl_int_0_116 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c117
+ bl_int_1_117 bl_int_0_117 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c118
+ bl_int_1_118 bl_0_118 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c119
+ bl_int_1_119 bl_0_119 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c120
+ bl_0_120 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c121
+ bl_int_1_121 bl_0_121 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c122
+ bl_int_0_122 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c123
+ bl_int_1_123 bl_0_123 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c124
+ bl_int_1_124 bl_int_0_124 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c125
+ bl_int_1_125 bl_0_125 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c126
+ bl_int_0_126 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c127
+ bl_0_127 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c128
+ bl_int_1_128 bl_0_128 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c129
+ bl_int_1_129 bl_0_129 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c130
+ bl_0_130 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c131
+ bl_int_1_131 bl_0_131 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c132
+ bl_int_1_132 bl_int_0_132 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c133
+ bl_int_1_133 bl_0_133 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c134
+ bl_int_1_134 bl_0_134 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c135
+ bl_int_1_135 bl_0_135 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c136
+ bl_int_1_136 bl_int_0_136 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c137
+ bl_int_0_137 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c138
+ bl_int_0_138 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c139
+ bl_int_0_139 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c140
+ bl_0_140 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c141
+ bl_int_1_141 bl_int_0_141 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c142
+ bl_int_1_142 bl_int_0_142 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c143
+ bl_int_1_143 bl_int_0_143 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c144
+ bl_int_0_144 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c145
+ bl_int_0_145 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c146
+ bl_int_0_146 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c147
+ bl_int_1_147 bl_int_0_147 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c148
+ bl_int_1_148 bl_0_148 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c149
+ bl_0_149 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c150
+ bl_int_0_150 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c151
+ bl_int_1_151 bl_0_151 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c152
+ bl_int_1_152 bl_int_0_152 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c153
+ bl_0_153 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c154
+ bl_int_1_154 bl_0_154 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c155
+ bl_int_0_155 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c156
+ bl_int_1_156 bl_0_156 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c157
+ bl_int_1_157 bl_0_157 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c158
+ bl_int_1_158 bl_0_158 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c159
+ bl_int_1_159 bl_int_0_159 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c160
+ bl_int_0_160 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c161
+ bl_int_0_161 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c162
+ bl_0_162 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c163
+ bl_int_1_163 bl_int_0_163 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c164
+ bl_int_1_164 bl_int_0_164 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c165
+ bl_0_165 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c166
+ bl_int_1_166 bl_int_0_166 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c167
+ bl_int_1_167 bl_int_0_167 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c168
+ bl_0_168 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c169
+ bl_int_0_169 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c170
+ bl_int_1_170 bl_0_170 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c171
+ bl_int_1_171 bl_int_0_171 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c172
+ bl_int_0_172 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c173
+ bl_int_1_173 bl_0_173 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c174
+ bl_int_0_174 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c175
+ bl_0_175 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c176
+ bl_0_176 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c177
+ bl_int_1_177 bl_0_177 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c178
+ bl_0_178 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c179
+ bl_0_179 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c180
+ bl_int_0_180 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c181
+ bl_int_1_181 bl_int_0_181 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c182
+ bl_0_182 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c183
+ bl_int_1_183 bl_int_0_183 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c184
+ bl_int_1_184 bl_int_0_184 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c185
+ bl_int_1_185 bl_0_185 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c186
+ bl_int_1_186 bl_int_0_186 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c187
+ bl_int_0_187 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c188
+ bl_int_1_188 bl_int_0_188 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c189
+ bl_int_1_189 bl_0_189 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c190
+ bl_int_0_190 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c191
+ bl_0_191 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c192
+ bl_0_192 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c193
+ bl_int_1_193 bl_int_0_193 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c194
+ bl_int_1_194 bl_int_0_194 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c195
+ bl_int_1_195 bl_int_0_195 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c196
+ bl_int_1_196 bl_int_0_196 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c197
+ bl_int_1_197 bl_int_0_197 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c198
+ bl_int_0_198 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c199
+ bl_int_1_199 bl_0_199 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c200
+ bl_int_1_200 bl_0_200 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c201
+ bl_0_201 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c202
+ bl_int_0_202 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c203
+ bl_int_0_203 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c204
+ bl_int_1_204 bl_int_0_204 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c205
+ bl_0_205 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c206
+ bl_0_206 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c207
+ bl_int_1_207 bl_int_0_207 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c208
+ bl_int_1_208 bl_int_0_208 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c209
+ bl_int_1_209 bl_0_209 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c210
+ bl_int_0_210 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c211
+ bl_int_1_211 bl_0_211 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c212
+ bl_0_212 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c213
+ bl_int_0_213 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c214
+ bl_int_0_214 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c215
+ bl_0_215 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c216
+ bl_int_0_216 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c217
+ bl_int_1_217 bl_0_217 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c218
+ bl_0_218 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c219
+ bl_int_1_219 bl_int_0_219 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c220
+ bl_int_1_220 bl_0_220 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c221
+ bl_int_1_221 bl_int_0_221 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c222
+ bl_int_0_222 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c223
+ bl_int_0_223 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c224
+ bl_0_224 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c225
+ bl_0_225 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c226
+ bl_int_1_226 bl_0_226 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c227
+ bl_int_1_227 bl_0_227 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c228
+ bl_int_1_228 bl_0_228 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c229
+ bl_int_0_229 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c230
+ bl_int_0_230 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c231
+ bl_int_1_231 bl_int_0_231 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c232
+ bl_int_1_232 bl_int_0_232 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c233
+ bl_int_1_233 bl_int_0_233 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c234
+ bl_int_1_234 bl_0_234 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c235
+ bl_int_0_235 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c236
+ bl_int_1_236 bl_int_0_236 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c237
+ bl_int_1_237 bl_int_0_237 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c238
+ bl_int_0_238 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c239
+ bl_int_1_239 bl_int_0_239 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c240
+ bl_int_1_240 bl_int_0_240 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c241
+ bl_0_241 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c242
+ bl_int_0_242 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c243
+ bl_int_0_243 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c244
+ bl_0_244 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c245
+ bl_int_1_245 bl_0_245 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c246
+ bl_int_0_246 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c247
+ bl_int_1_247 bl_int_0_247 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c248
+ bl_int_1_248 bl_int_0_248 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c249
+ bl_int_1_249 bl_int_0_249 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c250
+ bl_int_1_250 bl_int_0_250 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c251
+ bl_int_1_251 bl_int_0_251 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r1_c252
+ bl_int_0_252 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c253
+ bl_int_0_253 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c254
+ bl_0_254 wl_0_1 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r1_c255
+ bl_int_1_255 bl_0_255 wl_0_1 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c0
+ bl_int_2_0 bl_int_1_0 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c1
+ bl_int_2_1 bl_0_1 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c2
+ bl_int_1_2 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c3
+ bl_int_0_3 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c4
+ bl_0_4 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c5
+ bl_int_1_5 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c6
+ bl_0_6 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c7
+ bl_int_2_7 bl_int_0_7 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c8
+ bl_int_0_8 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c9
+ bl_int_2_9 bl_0_9 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c10
+ bl_int_2_10 bl_int_1_10 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c11
+ bl_0_11 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c12
+ bl_int_0_12 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c13
+ bl_int_1_13 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c14
+ bl_int_2_14 bl_int_1_14 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c15
+ bl_0_15 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c16
+ bl_int_2_16 bl_int_0_16 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c17
+ bl_int_2_17 bl_int_1_17 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c18
+ bl_int_2_18 bl_0_18 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c19
+ bl_int_2_19 bl_0_19 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c20
+ bl_int_1_20 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c21
+ bl_int_2_21 bl_0_21 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c22
+ bl_int_2_22 bl_int_0_22 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c23
+ bl_int_2_23 bl_int_0_23 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c24
+ bl_int_0_24 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c25
+ bl_int_2_25 bl_int_1_25 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c26
+ bl_int_2_26 bl_int_1_26 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c27
+ bl_int_0_27 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c28
+ bl_int_0_28 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c29
+ bl_int_2_29 bl_0_29 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c30
+ bl_int_0_30 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c31
+ bl_int_2_31 bl_0_31 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c32
+ bl_int_2_32 bl_int_1_32 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c33
+ bl_int_2_33 bl_0_33 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c34
+ bl_int_2_34 bl_0_34 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c35
+ bl_0_35 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c36
+ bl_int_2_36 bl_0_36 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c37
+ bl_0_37 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c38
+ bl_0_38 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c39
+ bl_int_0_39 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c40
+ bl_int_2_40 bl_int_1_40 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c41
+ bl_int_2_41 bl_0_41 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c42
+ bl_int_2_42 bl_int_1_42 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c43
+ bl_int_2_43 bl_int_1_43 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c44
+ bl_int_2_44 bl_0_44 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c45
+ bl_int_1_45 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c46
+ bl_int_0_46 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c47
+ bl_int_2_47 bl_0_47 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c48
+ bl_int_0_48 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c49
+ bl_int_0_49 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c50
+ bl_0_50 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c51
+ bl_int_1_51 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c52
+ bl_int_2_52 bl_int_1_52 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c53
+ bl_int_2_53 bl_int_0_53 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c54
+ bl_int_1_54 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c55
+ bl_int_1_55 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c56
+ bl_int_1_56 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c57
+ bl_int_2_57 bl_int_1_57 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c58
+ bl_int_1_58 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c59
+ bl_int_1_59 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c60
+ bl_0_60 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c61
+ bl_0_61 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c62
+ bl_int_0_62 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c63
+ bl_int_1_63 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c64
+ bl_int_2_64 bl_0_64 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c65
+ bl_int_2_65 bl_0_65 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c66
+ bl_int_2_66 bl_0_66 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c67
+ bl_0_67 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c68
+ bl_int_1_68 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c69
+ bl_int_1_69 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c70
+ bl_int_2_70 bl_int_1_70 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c71
+ bl_int_2_71 bl_0_71 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c72
+ bl_0_72 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c73
+ bl_int_2_73 bl_int_0_73 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c74
+ bl_int_1_74 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c75
+ bl_int_1_75 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c76
+ bl_int_2_76 bl_0_76 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c77
+ bl_int_1_77 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c78
+ bl_int_2_78 bl_int_1_78 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c79
+ bl_int_1_79 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c80
+ bl_int_2_80 bl_int_1_80 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c81
+ bl_int_2_81 bl_int_1_81 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c82
+ bl_int_1_82 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c83
+ bl_int_1_83 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c84
+ bl_0_84 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c85
+ bl_int_1_85 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c86
+ bl_int_2_86 bl_0_86 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c87
+ bl_int_1_87 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c88
+ bl_int_2_88 bl_int_0_88 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c89
+ bl_int_2_89 bl_int_0_89 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c90
+ bl_0_90 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c91
+ bl_int_0_91 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c92
+ bl_int_2_92 bl_int_0_92 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c93
+ bl_int_2_93 bl_0_93 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c94
+ bl_int_1_94 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c95
+ bl_0_95 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c96
+ bl_int_0_96 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c97
+ bl_int_2_97 bl_int_1_97 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c98
+ bl_int_2_98 bl_int_1_98 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c99
+ bl_int_2_99 bl_0_99 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c100
+ bl_int_2_100 bl_int_0_100 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c101
+ bl_0_101 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c102
+ bl_0_102 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c103
+ bl_int_0_103 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c104
+ bl_int_2_104 bl_int_0_104 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c105
+ bl_int_2_105 bl_int_0_105 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c106
+ bl_int_1_106 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c107
+ bl_int_2_107 bl_int_0_107 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c108
+ bl_0_108 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c109
+ bl_int_2_109 bl_0_109 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c110
+ bl_int_0_110 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c111
+ bl_int_2_111 bl_0_111 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c112
+ bl_int_2_112 bl_int_1_112 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c113
+ bl_int_2_113 bl_int_0_113 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c114
+ bl_int_1_114 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c115
+ bl_int_1_115 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c116
+ bl_int_2_116 bl_int_0_116 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c117
+ bl_int_2_117 bl_int_1_117 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c118
+ bl_int_1_118 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c119
+ bl_int_2_119 bl_int_1_119 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c120
+ bl_int_2_120 bl_0_120 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c121
+ bl_int_2_121 bl_int_1_121 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c122
+ bl_int_2_122 bl_int_0_122 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c123
+ bl_int_1_123 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c124
+ bl_int_2_124 bl_int_1_124 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c125
+ bl_int_1_125 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c126
+ bl_int_0_126 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c127
+ bl_int_2_127 bl_0_127 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c128
+ bl_int_1_128 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c129
+ bl_int_2_129 bl_int_1_129 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c130
+ bl_0_130 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c131
+ bl_int_1_131 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c132
+ bl_int_2_132 bl_int_1_132 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c133
+ bl_int_2_133 bl_int_1_133 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c134
+ bl_int_1_134 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c135
+ bl_int_1_135 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c136
+ bl_int_1_136 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c137
+ bl_int_0_137 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c138
+ bl_int_2_138 bl_int_0_138 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c139
+ bl_int_0_139 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c140
+ bl_0_140 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c141
+ bl_int_2_141 bl_int_1_141 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c142
+ bl_int_2_142 bl_int_1_142 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c143
+ bl_int_2_143 bl_int_1_143 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c144
+ bl_int_2_144 bl_int_0_144 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c145
+ bl_int_0_145 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c146
+ bl_int_0_146 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c147
+ bl_int_1_147 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c148
+ bl_int_2_148 bl_int_1_148 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c149
+ bl_int_2_149 bl_0_149 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c150
+ bl_int_0_150 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c151
+ bl_int_2_151 bl_int_1_151 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c152
+ bl_int_1_152 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c153
+ bl_0_153 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c154
+ bl_int_2_154 bl_int_1_154 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c155
+ bl_int_2_155 bl_int_0_155 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c156
+ bl_int_2_156 bl_int_1_156 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c157
+ bl_int_1_157 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c158
+ bl_int_1_158 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c159
+ bl_int_2_159 bl_int_1_159 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c160
+ bl_int_2_160 bl_int_0_160 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c161
+ bl_int_0_161 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c162
+ bl_0_162 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c163
+ bl_int_1_163 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c164
+ bl_int_1_164 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c165
+ bl_int_2_165 bl_0_165 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c166
+ bl_int_1_166 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c167
+ bl_int_2_167 bl_int_1_167 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c168
+ bl_int_2_168 bl_0_168 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c169
+ bl_int_2_169 bl_int_0_169 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c170
+ bl_int_1_170 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c171
+ bl_int_2_171 bl_int_1_171 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c172
+ bl_int_2_172 bl_int_0_172 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c173
+ bl_int_1_173 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c174
+ bl_int_0_174 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c175
+ bl_0_175 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c176
+ bl_int_2_176 bl_0_176 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c177
+ bl_int_2_177 bl_int_1_177 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c178
+ bl_0_178 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c179
+ bl_int_2_179 bl_0_179 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c180
+ bl_int_2_180 bl_int_0_180 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c181
+ bl_int_2_181 bl_int_1_181 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c182
+ bl_0_182 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c183
+ bl_int_1_183 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c184
+ bl_int_2_184 bl_int_1_184 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c185
+ bl_int_1_185 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c186
+ bl_int_2_186 bl_int_1_186 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c187
+ bl_int_0_187 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c188
+ bl_int_2_188 bl_int_1_188 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c189
+ bl_int_2_189 bl_int_1_189 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c190
+ bl_int_2_190 bl_int_0_190 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c191
+ bl_0_191 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c192
+ bl_int_2_192 bl_0_192 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c193
+ bl_int_2_193 bl_int_1_193 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c194
+ bl_int_1_194 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c195
+ bl_int_2_195 bl_int_1_195 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c196
+ bl_int_2_196 bl_int_1_196 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c197
+ bl_int_2_197 bl_int_1_197 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c198
+ bl_int_2_198 bl_int_0_198 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c199
+ bl_int_1_199 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c200
+ bl_int_2_200 bl_int_1_200 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c201
+ bl_0_201 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c202
+ bl_int_2_202 bl_int_0_202 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c203
+ bl_int_0_203 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c204
+ bl_int_2_204 bl_int_1_204 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c205
+ bl_0_205 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c206
+ bl_0_206 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c207
+ bl_int_1_207 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c208
+ bl_int_1_208 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c209
+ bl_int_1_209 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c210
+ bl_int_2_210 bl_int_0_210 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c211
+ bl_int_2_211 bl_int_1_211 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c212
+ bl_0_212 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c213
+ bl_int_2_213 bl_int_0_213 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c214
+ bl_int_0_214 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c215
+ bl_int_2_215 bl_0_215 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c216
+ bl_int_2_216 bl_int_0_216 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c217
+ bl_int_2_217 bl_int_1_217 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c218
+ bl_int_2_218 bl_0_218 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c219
+ bl_int_1_219 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c220
+ bl_int_2_220 bl_int_1_220 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c221
+ bl_int_2_221 bl_int_1_221 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c222
+ bl_int_0_222 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c223
+ bl_int_0_223 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c224
+ bl_int_2_224 bl_0_224 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c225
+ bl_0_225 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c226
+ bl_int_1_226 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c227
+ bl_int_1_227 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c228
+ bl_int_1_228 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c229
+ bl_int_0_229 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c230
+ bl_int_2_230 bl_int_0_230 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c231
+ bl_int_1_231 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c232
+ bl_int_2_232 bl_int_1_232 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c233
+ bl_int_1_233 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c234
+ bl_int_2_234 bl_int_1_234 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c235
+ bl_int_2_235 bl_int_0_235 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c236
+ bl_int_1_236 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c237
+ bl_int_1_237 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c238
+ bl_int_2_238 bl_int_0_238 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c239
+ bl_int_2_239 bl_int_1_239 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c240
+ bl_int_2_240 bl_int_1_240 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c241
+ bl_int_2_241 bl_0_241 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c242
+ bl_int_0_242 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c243
+ bl_int_2_243 bl_int_0_243 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c244
+ bl_int_2_244 bl_0_244 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c245
+ bl_int_2_245 bl_int_1_245 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c246
+ bl_int_2_246 bl_int_0_246 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c247
+ bl_int_2_247 bl_int_1_247 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c248
+ bl_int_2_248 bl_int_1_248 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c249
+ bl_int_2_249 bl_int_1_249 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c250
+ bl_int_1_250 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c251
+ bl_int_1_251 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c252
+ bl_int_2_252 bl_int_0_252 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c253
+ bl_int_0_253 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r2_c254
+ bl_int_2_254 bl_0_254 wl_0_2 gnd
+ rom_256b_rom_base_one_cell
Xbit_r2_c255
+ bl_int_1_255 wl_0_2 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c0
+ bl_int_2_0 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c1
+ bl_int_2_1 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c2
+ bl_int_1_2 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c3
+ bl_int_3_3 bl_int_0_3 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c4
+ bl_0_4 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c5
+ bl_int_3_5 bl_int_1_5 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c6
+ bl_0_6 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c7
+ bl_int_2_7 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c8
+ bl_int_3_8 bl_int_0_8 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c9
+ bl_int_3_9 bl_int_2_9 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c10
+ bl_int_3_10 bl_int_2_10 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c11
+ bl_0_11 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c12
+ bl_int_3_12 bl_int_0_12 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c13
+ bl_int_3_13 bl_int_1_13 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c14
+ bl_int_3_14 bl_int_2_14 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c15
+ bl_int_3_15 bl_0_15 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c16
+ bl_int_2_16 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c17
+ bl_int_3_17 bl_int_2_17 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c18
+ bl_int_2_18 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c19
+ bl_int_3_19 bl_int_2_19 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c20
+ bl_int_1_20 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c21
+ bl_int_3_21 bl_int_2_21 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c22
+ bl_int_2_22 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c23
+ bl_int_3_23 bl_int_2_23 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c24
+ bl_int_3_24 bl_int_0_24 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c25
+ bl_int_3_25 bl_int_2_25 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c26
+ bl_int_2_26 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c27
+ bl_int_3_27 bl_int_0_27 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c28
+ bl_int_0_28 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c29
+ bl_int_3_29 bl_int_2_29 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c30
+ bl_int_3_30 bl_int_0_30 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c31
+ bl_int_2_31 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c32
+ bl_int_2_32 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c33
+ bl_int_3_33 bl_int_2_33 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c34
+ bl_int_2_34 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c35
+ bl_0_35 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c36
+ bl_int_2_36 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c37
+ bl_0_37 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c38
+ bl_int_3_38 bl_0_38 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c39
+ bl_int_3_39 bl_int_0_39 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c40
+ bl_int_2_40 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c41
+ bl_int_3_41 bl_int_2_41 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c42
+ bl_int_3_42 bl_int_2_42 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c43
+ bl_int_2_43 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c44
+ bl_int_2_44 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c45
+ bl_int_1_45 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c46
+ bl_int_3_46 bl_int_0_46 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c47
+ bl_int_3_47 bl_int_2_47 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c48
+ bl_int_3_48 bl_int_0_48 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c49
+ bl_int_3_49 bl_int_0_49 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c50
+ bl_0_50 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c51
+ bl_int_3_51 bl_int_1_51 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c52
+ bl_int_2_52 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c53
+ bl_int_3_53 bl_int_2_53 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c54
+ bl_int_1_54 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c55
+ bl_int_1_55 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c56
+ bl_int_1_56 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c57
+ bl_int_2_57 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c58
+ bl_int_3_58 bl_int_1_58 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c59
+ bl_int_1_59 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c60
+ bl_int_3_60 bl_0_60 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c61
+ bl_0_61 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c62
+ bl_int_3_62 bl_int_0_62 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c63
+ bl_int_3_63 bl_int_1_63 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c64
+ bl_int_2_64 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c65
+ bl_int_3_65 bl_int_2_65 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c66
+ bl_int_3_66 bl_int_2_66 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c67
+ bl_0_67 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c68
+ bl_int_1_68 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c69
+ bl_int_1_69 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c70
+ bl_int_3_70 bl_int_2_70 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c71
+ bl_int_2_71 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c72
+ bl_0_72 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c73
+ bl_int_3_73 bl_int_2_73 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c74
+ bl_int_3_74 bl_int_1_74 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c75
+ bl_int_3_75 bl_int_1_75 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c76
+ bl_int_3_76 bl_int_2_76 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c77
+ bl_int_1_77 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c78
+ bl_int_3_78 bl_int_2_78 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c79
+ bl_int_3_79 bl_int_1_79 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c80
+ bl_int_2_80 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c81
+ bl_int_2_81 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c82
+ bl_int_3_82 bl_int_1_82 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c83
+ bl_int_3_83 bl_int_1_83 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c84
+ bl_int_3_84 bl_0_84 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c85
+ bl_int_1_85 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c86
+ bl_int_2_86 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c87
+ bl_int_3_87 bl_int_1_87 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c88
+ bl_int_2_88 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c89
+ bl_int_2_89 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c90
+ bl_0_90 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c91
+ bl_int_3_91 bl_int_0_91 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c92
+ bl_int_2_92 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c93
+ bl_int_2_93 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c94
+ bl_int_1_94 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c95
+ bl_int_3_95 bl_0_95 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c96
+ bl_int_3_96 bl_int_0_96 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c97
+ bl_int_2_97 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c98
+ bl_int_3_98 bl_int_2_98 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c99
+ bl_int_2_99 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c100
+ bl_int_2_100 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c101
+ bl_0_101 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c102
+ bl_0_102 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c103
+ bl_int_3_103 bl_int_0_103 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c104
+ bl_int_2_104 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c105
+ bl_int_3_105 bl_int_2_105 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c106
+ bl_int_3_106 bl_int_1_106 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c107
+ bl_int_3_107 bl_int_2_107 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c108
+ bl_int_3_108 bl_0_108 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c109
+ bl_int_3_109 bl_int_2_109 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c110
+ bl_int_0_110 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c111
+ bl_int_3_111 bl_int_2_111 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c112
+ bl_int_2_112 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c113
+ bl_int_2_113 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c114
+ bl_int_3_114 bl_int_1_114 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c115
+ bl_int_1_115 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c116
+ bl_int_3_116 bl_int_2_116 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c117
+ bl_int_2_117 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c118
+ bl_int_1_118 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c119
+ bl_int_3_119 bl_int_2_119 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c120
+ bl_int_3_120 bl_int_2_120 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c121
+ bl_int_3_121 bl_int_2_121 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c122
+ bl_int_2_122 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c123
+ bl_int_1_123 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c124
+ bl_int_3_124 bl_int_2_124 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c125
+ bl_int_1_125 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c126
+ bl_int_0_126 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c127
+ bl_int_3_127 bl_int_2_127 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c128
+ bl_int_3_128 bl_int_1_128 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c129
+ bl_int_3_129 bl_int_2_129 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c130
+ bl_0_130 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c131
+ bl_int_3_131 bl_int_1_131 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c132
+ bl_int_2_132 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c133
+ bl_int_3_133 bl_int_2_133 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c134
+ bl_int_3_134 bl_int_1_134 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c135
+ bl_int_1_135 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c136
+ bl_int_3_136 bl_int_1_136 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c137
+ bl_int_0_137 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c138
+ bl_int_2_138 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c139
+ bl_int_0_139 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c140
+ bl_0_140 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c141
+ bl_int_2_141 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c142
+ bl_int_3_142 bl_int_2_142 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c143
+ bl_int_3_143 bl_int_2_143 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c144
+ bl_int_3_144 bl_int_2_144 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c145
+ bl_int_0_145 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c146
+ bl_int_3_146 bl_int_0_146 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c147
+ bl_int_3_147 bl_int_1_147 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c148
+ bl_int_2_148 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c149
+ bl_int_3_149 bl_int_2_149 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c150
+ bl_int_0_150 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c151
+ bl_int_3_151 bl_int_2_151 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c152
+ bl_int_1_152 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c153
+ bl_0_153 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c154
+ bl_int_3_154 bl_int_2_154 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c155
+ bl_int_3_155 bl_int_2_155 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c156
+ bl_int_3_156 bl_int_2_156 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c157
+ bl_int_1_157 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c158
+ bl_int_3_158 bl_int_1_158 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c159
+ bl_int_2_159 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c160
+ bl_int_3_160 bl_int_2_160 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c161
+ bl_int_3_161 bl_int_0_161 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c162
+ bl_0_162 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c163
+ bl_int_1_163 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c164
+ bl_int_3_164 bl_int_1_164 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c165
+ bl_int_2_165 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c166
+ bl_int_3_166 bl_int_1_166 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c167
+ bl_int_3_167 bl_int_2_167 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c168
+ bl_int_2_168 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c169
+ bl_int_2_169 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c170
+ bl_int_3_170 bl_int_1_170 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c171
+ bl_int_2_171 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c172
+ bl_int_2_172 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c173
+ bl_int_3_173 bl_int_1_173 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c174
+ bl_int_0_174 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c175
+ bl_int_3_175 bl_0_175 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c176
+ bl_int_3_176 bl_int_2_176 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c177
+ bl_int_2_177 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c178
+ bl_int_3_178 bl_0_178 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c179
+ bl_int_3_179 bl_int_2_179 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c180
+ bl_int_3_180 bl_int_2_180 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c181
+ bl_int_3_181 bl_int_2_181 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c182
+ bl_0_182 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c183
+ bl_int_1_183 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c184
+ bl_int_3_184 bl_int_2_184 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c185
+ bl_int_3_185 bl_int_1_185 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c186
+ bl_int_3_186 bl_int_2_186 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c187
+ bl_int_3_187 bl_int_0_187 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c188
+ bl_int_3_188 bl_int_2_188 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c189
+ bl_int_3_189 bl_int_2_189 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c190
+ bl_int_3_190 bl_int_2_190 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c191
+ bl_0_191 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c192
+ bl_int_3_192 bl_int_2_192 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c193
+ bl_int_2_193 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c194
+ bl_int_3_194 bl_int_1_194 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c195
+ bl_int_2_195 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c196
+ bl_int_2_196 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c197
+ bl_int_2_197 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c198
+ bl_int_2_198 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c199
+ bl_int_3_199 bl_int_1_199 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c200
+ bl_int_3_200 bl_int_2_200 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c201
+ bl_0_201 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c202
+ bl_int_2_202 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c203
+ bl_int_0_203 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c204
+ bl_int_3_204 bl_int_2_204 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c205
+ bl_int_3_205 bl_0_205 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c206
+ bl_int_3_206 bl_0_206 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c207
+ bl_int_3_207 bl_int_1_207 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c208
+ bl_int_1_208 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c209
+ bl_int_3_209 bl_int_1_209 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c210
+ bl_int_2_210 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c211
+ bl_int_2_211 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c212
+ bl_int_3_212 bl_0_212 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c213
+ bl_int_3_213 bl_int_2_213 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c214
+ bl_int_0_214 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c215
+ bl_int_2_215 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c216
+ bl_int_3_216 bl_int_2_216 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c217
+ bl_int_3_217 bl_int_2_217 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c218
+ bl_int_3_218 bl_int_2_218 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c219
+ bl_int_1_219 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c220
+ bl_int_3_220 bl_int_2_220 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c221
+ bl_int_3_221 bl_int_2_221 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c222
+ bl_int_3_222 bl_int_0_222 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c223
+ bl_int_0_223 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c224
+ bl_int_3_224 bl_int_2_224 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c225
+ bl_0_225 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c226
+ bl_int_1_226 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c227
+ bl_int_3_227 bl_int_1_227 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c228
+ bl_int_3_228 bl_int_1_228 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c229
+ bl_int_3_229 bl_int_0_229 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c230
+ bl_int_2_230 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c231
+ bl_int_3_231 bl_int_1_231 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c232
+ bl_int_2_232 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c233
+ bl_int_1_233 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c234
+ bl_int_2_234 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c235
+ bl_int_2_235 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c236
+ bl_int_1_236 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c237
+ bl_int_3_237 bl_int_1_237 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c238
+ bl_int_2_238 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c239
+ bl_int_3_239 bl_int_2_239 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c240
+ bl_int_3_240 bl_int_2_240 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c241
+ bl_int_3_241 bl_int_2_241 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c242
+ bl_int_0_242 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c243
+ bl_int_2_243 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c244
+ bl_int_3_244 bl_int_2_244 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c245
+ bl_int_2_245 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c246
+ bl_int_2_246 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c247
+ bl_int_3_247 bl_int_2_247 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c248
+ bl_int_3_248 bl_int_2_248 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c249
+ bl_int_2_249 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c250
+ bl_int_3_250 bl_int_1_250 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c251
+ bl_int_3_251 bl_int_1_251 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r3_c252
+ bl_int_2_252 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c253
+ bl_int_0_253 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c254
+ bl_int_2_254 wl_0_3 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r3_c255
+ bl_int_3_255 bl_int_1_255 wl_0_3 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c0
+ bl_int_4_0 bl_int_2_0 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c1
+ bl_int_2_1 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c2
+ bl_int_4_2 bl_int_1_2 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c3
+ bl_int_3_3 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c4
+ bl_0_4 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c5
+ bl_int_4_5 bl_int_3_5 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c6
+ bl_int_4_6 bl_0_6 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c7
+ bl_int_2_7 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c8
+ bl_int_3_8 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c9
+ bl_int_4_9 bl_int_3_9 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c10
+ bl_int_4_10 bl_int_3_10 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c11
+ bl_int_4_11 bl_0_11 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c12
+ bl_int_3_12 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c13
+ bl_int_4_13 bl_int_3_13 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c14
+ bl_int_4_14 bl_int_3_14 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c15
+ bl_int_3_15 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c16
+ bl_int_4_16 bl_int_2_16 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c17
+ bl_int_4_17 bl_int_3_17 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c18
+ bl_int_4_18 bl_int_2_18 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c19
+ bl_int_4_19 bl_int_3_19 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c20
+ bl_int_4_20 bl_int_1_20 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c21
+ bl_int_4_21 bl_int_3_21 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c22
+ bl_int_4_22 bl_int_2_22 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c23
+ bl_int_3_23 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c24
+ bl_int_3_24 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c25
+ bl_int_4_25 bl_int_3_25 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c26
+ bl_int_4_26 bl_int_2_26 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c27
+ bl_int_3_27 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c28
+ bl_int_0_28 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c29
+ bl_int_4_29 bl_int_3_29 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c30
+ bl_int_3_30 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c31
+ bl_int_2_31 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c32
+ bl_int_2_32 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c33
+ bl_int_4_33 bl_int_3_33 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c34
+ bl_int_2_34 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c35
+ bl_0_35 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c36
+ bl_int_4_36 bl_int_2_36 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c37
+ bl_0_37 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c38
+ bl_int_3_38 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c39
+ bl_int_3_39 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c40
+ bl_int_2_40 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c41
+ bl_int_3_41 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c42
+ bl_int_3_42 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c43
+ bl_int_4_43 bl_int_2_43 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c44
+ bl_int_4_44 bl_int_2_44 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c45
+ bl_int_1_45 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c46
+ bl_int_4_46 bl_int_3_46 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c47
+ bl_int_3_47 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c48
+ bl_int_4_48 bl_int_3_48 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c49
+ bl_int_3_49 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c50
+ bl_0_50 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c51
+ bl_int_4_51 bl_int_3_51 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c52
+ bl_int_2_52 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c53
+ bl_int_4_53 bl_int_3_53 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c54
+ bl_int_1_54 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c55
+ bl_int_4_55 bl_int_1_55 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c56
+ bl_int_4_56 bl_int_1_56 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c57
+ bl_int_2_57 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c58
+ bl_int_3_58 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c59
+ bl_int_1_59 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c60
+ bl_int_3_60 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c61
+ bl_int_4_61 bl_0_61 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c62
+ bl_int_4_62 bl_int_3_62 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c63
+ bl_int_4_63 bl_int_3_63 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c64
+ bl_int_2_64 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c65
+ bl_int_4_65 bl_int_3_65 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c66
+ bl_int_3_66 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c67
+ bl_0_67 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c68
+ bl_int_4_68 bl_int_1_68 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c69
+ bl_int_4_69 bl_int_1_69 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c70
+ bl_int_3_70 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c71
+ bl_int_2_71 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c72
+ bl_0_72 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c73
+ bl_int_4_73 bl_int_3_73 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c74
+ bl_int_4_74 bl_int_3_74 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c75
+ bl_int_4_75 bl_int_3_75 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c76
+ bl_int_3_76 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c77
+ bl_int_1_77 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c78
+ bl_int_4_78 bl_int_3_78 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c79
+ bl_int_3_79 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c80
+ bl_int_2_80 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c81
+ bl_int_2_81 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c82
+ bl_int_4_82 bl_int_3_82 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c83
+ bl_int_4_83 bl_int_3_83 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c84
+ bl_int_4_84 bl_int_3_84 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c85
+ bl_int_1_85 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c86
+ bl_int_2_86 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c87
+ bl_int_4_87 bl_int_3_87 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c88
+ bl_int_4_88 bl_int_2_88 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c89
+ bl_int_4_89 bl_int_2_89 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c90
+ bl_int_4_90 bl_0_90 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c91
+ bl_int_4_91 bl_int_3_91 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c92
+ bl_int_2_92 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c93
+ bl_int_2_93 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c94
+ bl_int_1_94 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c95
+ bl_int_4_95 bl_int_3_95 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c96
+ bl_int_3_96 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c97
+ bl_int_2_97 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c98
+ bl_int_4_98 bl_int_3_98 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c99
+ bl_int_4_99 bl_int_2_99 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c100
+ bl_int_2_100 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c101
+ bl_int_4_101 bl_0_101 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c102
+ bl_int_4_102 bl_0_102 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c103
+ bl_int_3_103 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c104
+ bl_int_2_104 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c105
+ bl_int_3_105 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c106
+ bl_int_3_106 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c107
+ bl_int_4_107 bl_int_3_107 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c108
+ bl_int_3_108 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c109
+ bl_int_3_109 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c110
+ bl_int_0_110 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c111
+ bl_int_4_111 bl_int_3_111 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c112
+ bl_int_4_112 bl_int_2_112 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c113
+ bl_int_4_113 bl_int_2_113 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c114
+ bl_int_4_114 bl_int_3_114 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c115
+ bl_int_1_115 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c116
+ bl_int_3_116 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c117
+ bl_int_2_117 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c118
+ bl_int_1_118 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c119
+ bl_int_3_119 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c120
+ bl_int_4_120 bl_int_3_120 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c121
+ bl_int_4_121 bl_int_3_121 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c122
+ bl_int_4_122 bl_int_2_122 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c123
+ bl_int_1_123 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c124
+ bl_int_3_124 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c125
+ bl_int_4_125 bl_int_1_125 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c126
+ bl_int_0_126 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c127
+ bl_int_4_127 bl_int_3_127 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c128
+ bl_int_4_128 bl_int_3_128 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c129
+ bl_int_3_129 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c130
+ bl_0_130 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c131
+ bl_int_4_131 bl_int_3_131 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c132
+ bl_int_2_132 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c133
+ bl_int_4_133 bl_int_3_133 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c134
+ bl_int_4_134 bl_int_3_134 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c135
+ bl_int_4_135 bl_int_1_135 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c136
+ bl_int_3_136 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c137
+ bl_int_4_137 bl_int_0_137 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c138
+ bl_int_4_138 bl_int_2_138 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c139
+ bl_int_0_139 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c140
+ bl_0_140 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c141
+ bl_int_4_141 bl_int_2_141 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c142
+ bl_int_3_142 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c143
+ bl_int_3_143 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c144
+ bl_int_4_144 bl_int_3_144 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c145
+ bl_int_4_145 bl_int_0_145 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c146
+ bl_int_4_146 bl_int_3_146 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c147
+ bl_int_3_147 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c148
+ bl_int_4_148 bl_int_2_148 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c149
+ bl_int_3_149 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c150
+ bl_int_0_150 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c151
+ bl_int_3_151 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c152
+ bl_int_1_152 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c153
+ bl_0_153 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c154
+ bl_int_4_154 bl_int_3_154 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c155
+ bl_int_3_155 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c156
+ bl_int_3_156 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c157
+ bl_int_1_157 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c158
+ bl_int_3_158 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c159
+ bl_int_2_159 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c160
+ bl_int_3_160 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c161
+ bl_int_4_161 bl_int_3_161 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c162
+ bl_int_4_162 bl_0_162 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c163
+ bl_int_4_163 bl_int_1_163 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c164
+ bl_int_4_164 bl_int_3_164 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c165
+ bl_int_4_165 bl_int_2_165 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c166
+ bl_int_4_166 bl_int_3_166 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c167
+ bl_int_4_167 bl_int_3_167 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c168
+ bl_int_2_168 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c169
+ bl_int_4_169 bl_int_2_169 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c170
+ bl_int_4_170 bl_int_3_170 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c171
+ bl_int_2_171 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c172
+ bl_int_4_172 bl_int_2_172 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c173
+ bl_int_4_173 bl_int_3_173 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c174
+ bl_int_4_174 bl_int_0_174 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c175
+ bl_int_4_175 bl_int_3_175 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c176
+ bl_int_3_176 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c177
+ bl_int_4_177 bl_int_2_177 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c178
+ bl_int_3_178 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c179
+ bl_int_3_179 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c180
+ bl_int_4_180 bl_int_3_180 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c181
+ bl_int_4_181 bl_int_3_181 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c182
+ bl_int_4_182 bl_0_182 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c183
+ bl_int_1_183 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c184
+ bl_int_4_184 bl_int_3_184 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c185
+ bl_int_4_185 bl_int_3_185 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c186
+ bl_int_3_186 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c187
+ bl_int_3_187 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c188
+ bl_int_3_188 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c189
+ bl_int_4_189 bl_int_3_189 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c190
+ bl_int_3_190 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c191
+ bl_0_191 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c192
+ bl_int_4_192 bl_int_3_192 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c193
+ bl_int_2_193 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c194
+ bl_int_3_194 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c195
+ bl_int_4_195 bl_int_2_195 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c196
+ bl_int_2_196 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c197
+ bl_int_4_197 bl_int_2_197 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c198
+ bl_int_2_198 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c199
+ bl_int_3_199 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c200
+ bl_int_4_200 bl_int_3_200 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c201
+ bl_0_201 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c202
+ bl_int_2_202 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c203
+ bl_int_0_203 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c204
+ bl_int_4_204 bl_int_3_204 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c205
+ bl_int_3_205 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c206
+ bl_int_3_206 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c207
+ bl_int_3_207 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c208
+ bl_int_1_208 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c209
+ bl_int_4_209 bl_int_3_209 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c210
+ bl_int_2_210 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c211
+ bl_int_4_211 bl_int_2_211 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c212
+ bl_int_3_212 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c213
+ bl_int_4_213 bl_int_3_213 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c214
+ bl_int_0_214 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c215
+ bl_int_2_215 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c216
+ bl_int_3_216 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c217
+ bl_int_3_217 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c218
+ bl_int_4_218 bl_int_3_218 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c219
+ bl_int_1_219 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c220
+ bl_int_4_220 bl_int_3_220 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c221
+ bl_int_4_221 bl_int_3_221 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c222
+ bl_int_3_222 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c223
+ bl_int_0_223 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c224
+ bl_int_3_224 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c225
+ bl_int_4_225 bl_0_225 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c226
+ bl_int_1_226 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c227
+ bl_int_3_227 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c228
+ bl_int_3_228 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c229
+ bl_int_4_229 bl_int_3_229 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c230
+ bl_int_4_230 bl_int_2_230 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c231
+ bl_int_4_231 bl_int_3_231 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c232
+ bl_int_4_232 bl_int_2_232 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c233
+ bl_int_1_233 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c234
+ bl_int_4_234 bl_int_2_234 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c235
+ bl_int_4_235 bl_int_2_235 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c236
+ bl_int_4_236 bl_int_1_236 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c237
+ bl_int_3_237 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c238
+ bl_int_2_238 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c239
+ bl_int_4_239 bl_int_3_239 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c240
+ bl_int_4_240 bl_int_3_240 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c241
+ bl_int_4_241 bl_int_3_241 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c242
+ bl_int_4_242 bl_int_0_242 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c243
+ bl_int_4_243 bl_int_2_243 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c244
+ bl_int_3_244 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c245
+ bl_int_4_245 bl_int_2_245 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c246
+ bl_int_4_246 bl_int_2_246 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c247
+ bl_int_4_247 bl_int_3_247 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c248
+ bl_int_4_248 bl_int_3_248 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c249
+ bl_int_4_249 bl_int_2_249 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c250
+ bl_int_3_250 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c251
+ bl_int_3_251 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c252
+ bl_int_4_252 bl_int_2_252 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r4_c253
+ bl_int_0_253 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c254
+ bl_int_2_254 wl_0_4 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r4_c255
+ bl_int_4_255 bl_int_3_255 wl_0_4 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c0
+ bl_int_4_0 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c1
+ bl_int_5_1 bl_int_2_1 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c2
+ bl_int_5_2 bl_int_4_2 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c3
+ bl_int_5_3 bl_int_3_3 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c4
+ bl_int_5_4 bl_0_4 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c5
+ bl_int_4_5 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c6
+ bl_int_4_6 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c7
+ bl_int_5_7 bl_int_2_7 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c8
+ bl_int_3_8 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c9
+ bl_int_4_9 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c10
+ bl_int_4_10 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c11
+ bl_int_4_11 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c12
+ bl_int_3_12 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c13
+ bl_int_5_13 bl_int_4_13 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c14
+ bl_int_5_14 bl_int_4_14 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c15
+ bl_int_3_15 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c16
+ bl_int_4_16 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c17
+ bl_int_4_17 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c18
+ bl_int_5_18 bl_int_4_18 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c19
+ bl_int_4_19 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c20
+ bl_int_5_20 bl_int_4_20 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c21
+ bl_int_5_21 bl_int_4_21 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c22
+ bl_int_5_22 bl_int_4_22 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c23
+ bl_int_3_23 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c24
+ bl_int_5_24 bl_int_3_24 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c25
+ bl_int_4_25 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c26
+ bl_int_4_26 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c27
+ bl_int_5_27 bl_int_3_27 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c28
+ bl_int_5_28 bl_int_0_28 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c29
+ bl_int_5_29 bl_int_4_29 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c30
+ bl_int_5_30 bl_int_3_30 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c31
+ bl_int_2_31 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c32
+ bl_int_5_32 bl_int_2_32 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c33
+ bl_int_5_33 bl_int_4_33 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c34
+ bl_int_2_34 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c35
+ bl_0_35 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c36
+ bl_int_4_36 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c37
+ bl_0_37 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c38
+ bl_int_5_38 bl_int_3_38 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c39
+ bl_int_3_39 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c40
+ bl_int_5_40 bl_int_2_40 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c41
+ bl_int_5_41 bl_int_3_41 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c42
+ bl_int_3_42 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c43
+ bl_int_5_43 bl_int_4_43 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c44
+ bl_int_4_44 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c45
+ bl_int_1_45 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c46
+ bl_int_5_46 bl_int_4_46 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c47
+ bl_int_5_47 bl_int_3_47 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c48
+ bl_int_5_48 bl_int_4_48 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c49
+ bl_int_5_49 bl_int_3_49 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c50
+ bl_int_5_50 bl_0_50 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c51
+ bl_int_5_51 bl_int_4_51 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c52
+ bl_int_2_52 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c53
+ bl_int_4_53 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c54
+ bl_int_1_54 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c55
+ bl_int_5_55 bl_int_4_55 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c56
+ bl_int_5_56 bl_int_4_56 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c57
+ bl_int_5_57 bl_int_2_57 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c58
+ bl_int_5_58 bl_int_3_58 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c59
+ bl_int_5_59 bl_int_1_59 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c60
+ bl_int_5_60 bl_int_3_60 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c61
+ bl_int_5_61 bl_int_4_61 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c62
+ bl_int_5_62 bl_int_4_62 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c63
+ bl_int_5_63 bl_int_4_63 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c64
+ bl_int_2_64 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c65
+ bl_int_4_65 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c66
+ bl_int_5_66 bl_int_3_66 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c67
+ bl_int_5_67 bl_0_67 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c68
+ bl_int_4_68 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c69
+ bl_int_5_69 bl_int_4_69 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c70
+ bl_int_3_70 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c71
+ bl_int_5_71 bl_int_2_71 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c72
+ bl_0_72 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c73
+ bl_int_5_73 bl_int_4_73 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c74
+ bl_int_5_74 bl_int_4_74 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c75
+ bl_int_5_75 bl_int_4_75 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c76
+ bl_int_3_76 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c77
+ bl_int_5_77 bl_int_1_77 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c78
+ bl_int_4_78 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c79
+ bl_int_5_79 bl_int_3_79 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c80
+ bl_int_2_80 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c81
+ bl_int_5_81 bl_int_2_81 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c82
+ bl_int_4_82 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c83
+ bl_int_4_83 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c84
+ bl_int_4_84 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c85
+ bl_int_1_85 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c86
+ bl_int_2_86 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c87
+ bl_int_5_87 bl_int_4_87 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c88
+ bl_int_4_88 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c89
+ bl_int_4_89 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c90
+ bl_int_4_90 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c91
+ bl_int_5_91 bl_int_4_91 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c92
+ bl_int_5_92 bl_int_2_92 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c93
+ bl_int_5_93 bl_int_2_93 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c94
+ bl_int_5_94 bl_int_1_94 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c95
+ bl_int_5_95 bl_int_4_95 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c96
+ bl_int_5_96 bl_int_3_96 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c97
+ bl_int_5_97 bl_int_2_97 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c98
+ bl_int_4_98 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c99
+ bl_int_5_99 bl_int_4_99 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c100
+ bl_int_2_100 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c101
+ bl_int_5_101 bl_int_4_101 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c102
+ bl_int_4_102 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c103
+ bl_int_3_103 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c104
+ bl_int_5_104 bl_int_2_104 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c105
+ bl_int_5_105 bl_int_3_105 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c106
+ bl_int_5_106 bl_int_3_106 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c107
+ bl_int_5_107 bl_int_4_107 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c108
+ bl_int_3_108 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c109
+ bl_int_5_109 bl_int_3_109 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c110
+ bl_int_5_110 bl_int_0_110 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c111
+ bl_int_4_111 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c112
+ bl_int_4_112 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c113
+ bl_int_5_113 bl_int_4_113 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c114
+ bl_int_5_114 bl_int_4_114 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c115
+ bl_int_1_115 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c116
+ bl_int_5_116 bl_int_3_116 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c117
+ bl_int_5_117 bl_int_2_117 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c118
+ bl_int_5_118 bl_int_1_118 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c119
+ bl_int_3_119 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c120
+ bl_int_5_120 bl_int_4_120 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c121
+ bl_int_5_121 bl_int_4_121 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c122
+ bl_int_4_122 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c123
+ bl_int_1_123 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c124
+ bl_int_5_124 bl_int_3_124 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c125
+ bl_int_5_125 bl_int_4_125 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c126
+ bl_int_0_126 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c127
+ bl_int_5_127 bl_int_4_127 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c128
+ bl_int_5_128 bl_int_4_128 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c129
+ bl_int_5_129 bl_int_3_129 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c130
+ bl_int_5_130 bl_0_130 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c131
+ bl_int_5_131 bl_int_4_131 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c132
+ bl_int_5_132 bl_int_2_132 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c133
+ bl_int_5_133 bl_int_4_133 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c134
+ bl_int_4_134 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c135
+ bl_int_4_135 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c136
+ bl_int_5_136 bl_int_3_136 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c137
+ bl_int_5_137 bl_int_4_137 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c138
+ bl_int_4_138 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c139
+ bl_int_0_139 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c140
+ bl_0_140 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c141
+ bl_int_4_141 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c142
+ bl_int_3_142 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c143
+ bl_int_3_143 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c144
+ bl_int_4_144 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c145
+ bl_int_5_145 bl_int_4_145 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c146
+ bl_int_5_146 bl_int_4_146 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c147
+ bl_int_5_147 bl_int_3_147 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c148
+ bl_int_4_148 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c149
+ bl_int_3_149 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c150
+ bl_int_0_150 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c151
+ bl_int_3_151 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c152
+ bl_int_5_152 bl_int_1_152 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c153
+ bl_int_5_153 bl_0_153 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c154
+ bl_int_5_154 bl_int_4_154 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c155
+ bl_int_5_155 bl_int_3_155 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c156
+ bl_int_5_156 bl_int_3_156 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c157
+ bl_int_5_157 bl_int_1_157 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c158
+ bl_int_5_158 bl_int_3_158 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c159
+ bl_int_5_159 bl_int_2_159 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c160
+ bl_int_5_160 bl_int_3_160 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c161
+ bl_int_4_161 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c162
+ bl_int_4_162 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c163
+ bl_int_5_163 bl_int_4_163 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c164
+ bl_int_4_164 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c165
+ bl_int_5_165 bl_int_4_165 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c166
+ bl_int_4_166 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c167
+ bl_int_5_167 bl_int_4_167 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c168
+ bl_int_2_168 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c169
+ bl_int_4_169 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c170
+ bl_int_4_170 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c171
+ bl_int_5_171 bl_int_2_171 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c172
+ bl_int_4_172 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c173
+ bl_int_5_173 bl_int_4_173 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c174
+ bl_int_5_174 bl_int_4_174 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c175
+ bl_int_5_175 bl_int_4_175 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c176
+ bl_int_5_176 bl_int_3_176 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c177
+ bl_int_5_177 bl_int_4_177 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c178
+ bl_int_5_178 bl_int_3_178 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c179
+ bl_int_3_179 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c180
+ bl_int_4_180 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c181
+ bl_int_5_181 bl_int_4_181 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c182
+ bl_int_5_182 bl_int_4_182 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c183
+ bl_int_1_183 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c184
+ bl_int_5_184 bl_int_4_184 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c185
+ bl_int_4_185 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c186
+ bl_int_3_186 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c187
+ bl_int_5_187 bl_int_3_187 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c188
+ bl_int_5_188 bl_int_3_188 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c189
+ bl_int_4_189 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c190
+ bl_int_5_190 bl_int_3_190 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c191
+ bl_0_191 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c192
+ bl_int_5_192 bl_int_4_192 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c193
+ bl_int_2_193 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c194
+ bl_int_3_194 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c195
+ bl_int_4_195 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c196
+ bl_int_5_196 bl_int_2_196 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c197
+ bl_int_4_197 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c198
+ bl_int_5_198 bl_int_2_198 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c199
+ bl_int_5_199 bl_int_3_199 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c200
+ bl_int_5_200 bl_int_4_200 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c201
+ bl_0_201 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c202
+ bl_int_5_202 bl_int_2_202 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c203
+ bl_int_0_203 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c204
+ bl_int_4_204 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c205
+ bl_int_3_205 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c206
+ bl_int_3_206 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c207
+ bl_int_5_207 bl_int_3_207 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c208
+ bl_int_1_208 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c209
+ bl_int_4_209 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c210
+ bl_int_2_210 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c211
+ bl_int_5_211 bl_int_4_211 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c212
+ bl_int_5_212 bl_int_3_212 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c213
+ bl_int_5_213 bl_int_4_213 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c214
+ bl_int_0_214 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c215
+ bl_int_2_215 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c216
+ bl_int_5_216 bl_int_3_216 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c217
+ bl_int_5_217 bl_int_3_217 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c218
+ bl_int_4_218 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c219
+ bl_int_1_219 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c220
+ bl_int_5_220 bl_int_4_220 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c221
+ bl_int_5_221 bl_int_4_221 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c222
+ bl_int_5_222 bl_int_3_222 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c223
+ bl_int_5_223 bl_int_0_223 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c224
+ bl_int_3_224 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c225
+ bl_int_5_225 bl_int_4_225 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c226
+ bl_int_1_226 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c227
+ bl_int_5_227 bl_int_3_227 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c228
+ bl_int_5_228 bl_int_3_228 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c229
+ bl_int_4_229 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c230
+ bl_int_4_230 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c231
+ bl_int_5_231 bl_int_4_231 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c232
+ bl_int_5_232 bl_int_4_232 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c233
+ bl_int_1_233 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c234
+ bl_int_4_234 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c235
+ bl_int_5_235 bl_int_4_235 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c236
+ bl_int_5_236 bl_int_4_236 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c237
+ bl_int_5_237 bl_int_3_237 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c238
+ bl_int_5_238 bl_int_2_238 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c239
+ bl_int_5_239 bl_int_4_239 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c240
+ bl_int_5_240 bl_int_4_240 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c241
+ bl_int_5_241 bl_int_4_241 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c242
+ bl_int_4_242 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c243
+ bl_int_4_243 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c244
+ bl_int_3_244 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c245
+ bl_int_4_245 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c246
+ bl_int_5_246 bl_int_4_246 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c247
+ bl_int_5_247 bl_int_4_247 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c248
+ bl_int_5_248 bl_int_4_248 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c249
+ bl_int_4_249 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c250
+ bl_int_5_250 bl_int_3_250 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c251
+ bl_int_3_251 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c252
+ bl_int_5_252 bl_int_4_252 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c253
+ bl_int_5_253 bl_int_0_253 wl_0_5 gnd
+ rom_256b_rom_base_one_cell
Xbit_r5_c254
+ bl_int_2_254 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r5_c255
+ bl_int_4_255 wl_0_5 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c0
+ bl_int_6_0 bl_int_4_0 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c1
+ bl_int_5_1 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c2
+ bl_int_5_2 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c3
+ bl_int_5_3 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c4
+ bl_int_6_4 bl_int_5_4 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c5
+ bl_int_4_5 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c6
+ bl_int_6_6 bl_int_4_6 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c7
+ bl_int_6_7 bl_int_5_7 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c8
+ bl_int_3_8 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c9
+ bl_int_6_9 bl_int_4_9 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c10
+ bl_int_4_10 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c11
+ bl_int_6_11 bl_int_4_11 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c12
+ bl_int_3_12 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c13
+ bl_int_6_13 bl_int_5_13 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c14
+ bl_int_5_14 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c15
+ bl_int_3_15 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c16
+ bl_int_6_16 bl_int_4_16 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c17
+ bl_int_4_17 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c18
+ bl_int_6_18 bl_int_5_18 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c19
+ bl_int_6_19 bl_int_4_19 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c20
+ bl_int_5_20 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c21
+ bl_int_5_21 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c22
+ bl_int_6_22 bl_int_5_22 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c23
+ bl_int_3_23 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c24
+ bl_int_6_24 bl_int_5_24 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c25
+ bl_int_6_25 bl_int_4_25 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c26
+ bl_int_4_26 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c27
+ bl_int_5_27 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c28
+ bl_int_6_28 bl_int_5_28 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c29
+ bl_int_5_29 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c30
+ bl_int_6_30 bl_int_5_30 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c31
+ bl_int_2_31 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c32
+ bl_int_6_32 bl_int_5_32 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c33
+ bl_int_5_33 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c34
+ bl_int_6_34 bl_int_2_34 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c35
+ bl_0_35 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c36
+ bl_int_4_36 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c37
+ bl_0_37 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c38
+ bl_int_5_38 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c39
+ bl_int_6_39 bl_int_3_39 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c40
+ bl_int_6_40 bl_int_5_40 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c41
+ bl_int_6_41 bl_int_5_41 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c42
+ bl_int_3_42 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c43
+ bl_int_5_43 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c44
+ bl_int_4_44 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c45
+ bl_int_1_45 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c46
+ bl_int_6_46 bl_int_5_46 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c47
+ bl_int_6_47 bl_int_5_47 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c48
+ bl_int_6_48 bl_int_5_48 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c49
+ bl_int_6_49 bl_int_5_49 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c50
+ bl_int_6_50 bl_int_5_50 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c51
+ bl_int_6_51 bl_int_5_51 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c52
+ bl_int_2_52 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c53
+ bl_int_6_53 bl_int_4_53 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c54
+ bl_int_1_54 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c55
+ bl_int_5_55 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c56
+ bl_int_5_56 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c57
+ bl_int_6_57 bl_int_5_57 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c58
+ bl_int_6_58 bl_int_5_58 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c59
+ bl_int_6_59 bl_int_5_59 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c60
+ bl_int_5_60 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c61
+ bl_int_6_61 bl_int_5_61 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c62
+ bl_int_6_62 bl_int_5_62 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c63
+ bl_int_5_63 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c64
+ bl_int_2_64 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c65
+ bl_int_6_65 bl_int_4_65 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c66
+ bl_int_5_66 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c67
+ bl_int_5_67 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c68
+ bl_int_4_68 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c69
+ bl_int_6_69 bl_int_5_69 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c70
+ bl_int_3_70 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c71
+ bl_int_5_71 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c72
+ bl_int_6_72 bl_0_72 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c73
+ bl_int_6_73 bl_int_5_73 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c74
+ bl_int_5_74 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c75
+ bl_int_5_75 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c76
+ bl_int_3_76 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c77
+ bl_int_6_77 bl_int_5_77 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c78
+ bl_int_4_78 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c79
+ bl_int_5_79 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c80
+ bl_int_2_80 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c81
+ bl_int_6_81 bl_int_5_81 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c82
+ bl_int_4_82 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c83
+ bl_int_4_83 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c84
+ bl_int_4_84 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c85
+ bl_int_1_85 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c86
+ bl_int_2_86 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c87
+ bl_int_6_87 bl_int_5_87 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c88
+ bl_int_6_88 bl_int_4_88 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c89
+ bl_int_6_89 bl_int_4_89 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c90
+ bl_int_6_90 bl_int_4_90 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c91
+ bl_int_6_91 bl_int_5_91 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c92
+ bl_int_5_92 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c93
+ bl_int_5_93 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c94
+ bl_int_6_94 bl_int_5_94 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c95
+ bl_int_6_95 bl_int_5_95 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c96
+ bl_int_5_96 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c97
+ bl_int_6_97 bl_int_5_97 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c98
+ bl_int_4_98 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c99
+ bl_int_5_99 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c100
+ bl_int_6_100 bl_int_2_100 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c101
+ bl_int_6_101 bl_int_5_101 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c102
+ bl_int_6_102 bl_int_4_102 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c103
+ bl_int_6_103 bl_int_3_103 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c104
+ bl_int_6_104 bl_int_5_104 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c105
+ bl_int_5_105 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c106
+ bl_int_5_106 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c107
+ bl_int_6_107 bl_int_5_107 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c108
+ bl_int_6_108 bl_int_3_108 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c109
+ bl_int_5_109 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c110
+ bl_int_6_110 bl_int_5_110 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c111
+ bl_int_4_111 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c112
+ bl_int_6_112 bl_int_4_112 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c113
+ bl_int_5_113 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c114
+ bl_int_5_114 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c115
+ bl_int_6_115 bl_int_1_115 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c116
+ bl_int_6_116 bl_int_5_116 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c117
+ bl_int_6_117 bl_int_5_117 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c118
+ bl_int_5_118 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c119
+ bl_int_6_119 bl_int_3_119 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c120
+ bl_int_6_120 bl_int_5_120 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c121
+ bl_int_6_121 bl_int_5_121 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c122
+ bl_int_4_122 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c123
+ bl_int_6_123 bl_int_1_123 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c124
+ bl_int_5_124 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c125
+ bl_int_6_125 bl_int_5_125 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c126
+ bl_int_0_126 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c127
+ bl_int_6_127 bl_int_5_127 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c128
+ bl_int_6_128 bl_int_5_128 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c129
+ bl_int_6_129 bl_int_5_129 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c130
+ bl_int_6_130 bl_int_5_130 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c131
+ bl_int_6_131 bl_int_5_131 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c132
+ bl_int_6_132 bl_int_5_132 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c133
+ bl_int_5_133 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c134
+ bl_int_4_134 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c135
+ bl_int_4_135 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c136
+ bl_int_5_136 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c137
+ bl_int_5_137 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c138
+ bl_int_4_138 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c139
+ bl_int_6_139 bl_int_0_139 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c140
+ bl_0_140 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c141
+ bl_int_4_141 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c142
+ bl_int_3_142 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c143
+ bl_int_3_143 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c144
+ bl_int_4_144 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c145
+ bl_int_5_145 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c146
+ bl_int_6_146 bl_int_5_146 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c147
+ bl_int_5_147 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c148
+ bl_int_4_148 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c149
+ bl_int_3_149 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c150
+ bl_int_6_150 bl_int_0_150 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c151
+ bl_int_6_151 bl_int_3_151 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c152
+ bl_int_6_152 bl_int_5_152 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c153
+ bl_int_5_153 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c154
+ bl_int_6_154 bl_int_5_154 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c155
+ bl_int_6_155 bl_int_5_155 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c156
+ bl_int_5_156 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c157
+ bl_int_6_157 bl_int_5_157 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c158
+ bl_int_6_158 bl_int_5_158 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c159
+ bl_int_6_159 bl_int_5_159 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c160
+ bl_int_5_160 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c161
+ bl_int_4_161 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c162
+ bl_int_4_162 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c163
+ bl_int_6_163 bl_int_5_163 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c164
+ bl_int_6_164 bl_int_4_164 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c165
+ bl_int_5_165 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c166
+ bl_int_4_166 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c167
+ bl_int_6_167 bl_int_5_167 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c168
+ bl_int_2_168 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c169
+ bl_int_6_169 bl_int_4_169 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c170
+ bl_int_4_170 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c171
+ bl_int_6_171 bl_int_5_171 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c172
+ bl_int_4_172 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c173
+ bl_int_6_173 bl_int_5_173 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c174
+ bl_int_5_174 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c175
+ bl_int_5_175 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c176
+ bl_int_6_176 bl_int_5_176 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c177
+ bl_int_5_177 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c178
+ bl_int_6_178 bl_int_5_178 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c179
+ bl_int_3_179 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c180
+ bl_int_4_180 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c181
+ bl_int_6_181 bl_int_5_181 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c182
+ bl_int_5_182 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c183
+ bl_int_6_183 bl_int_1_183 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c184
+ bl_int_5_184 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c185
+ bl_int_6_185 bl_int_4_185 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c186
+ bl_int_3_186 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c187
+ bl_int_5_187 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c188
+ bl_int_6_188 bl_int_5_188 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c189
+ bl_int_4_189 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c190
+ bl_int_5_190 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c191
+ bl_0_191 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c192
+ bl_int_6_192 bl_int_5_192 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c193
+ bl_int_2_193 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c194
+ bl_int_3_194 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c195
+ bl_int_4_195 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c196
+ bl_int_6_196 bl_int_5_196 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c197
+ bl_int_6_197 bl_int_4_197 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c198
+ bl_int_6_198 bl_int_5_198 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c199
+ bl_int_6_199 bl_int_5_199 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c200
+ bl_int_5_200 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c201
+ bl_int_6_201 bl_0_201 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c202
+ bl_int_6_202 bl_int_5_202 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c203
+ bl_int_6_203 bl_int_0_203 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c204
+ bl_int_6_204 bl_int_4_204 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c205
+ bl_int_6_205 bl_int_3_205 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c206
+ bl_int_6_206 bl_int_3_206 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c207
+ bl_int_6_207 bl_int_5_207 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c208
+ bl_int_1_208 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c209
+ bl_int_6_209 bl_int_4_209 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c210
+ bl_int_2_210 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c211
+ bl_int_5_211 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c212
+ bl_int_6_212 bl_int_5_212 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c213
+ bl_int_5_213 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c214
+ bl_int_0_214 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c215
+ bl_int_2_215 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c216
+ bl_int_6_216 bl_int_5_216 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c217
+ bl_int_6_217 bl_int_5_217 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c218
+ bl_int_4_218 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c219
+ bl_int_1_219 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c220
+ bl_int_6_220 bl_int_5_220 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c221
+ bl_int_6_221 bl_int_5_221 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c222
+ bl_int_5_222 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c223
+ bl_int_5_223 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c224
+ bl_int_6_224 bl_int_3_224 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c225
+ bl_int_6_225 bl_int_5_225 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c226
+ bl_int_6_226 bl_int_1_226 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c227
+ bl_int_6_227 bl_int_5_227 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c228
+ bl_int_5_228 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c229
+ bl_int_4_229 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c230
+ bl_int_4_230 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c231
+ bl_int_6_231 bl_int_5_231 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c232
+ bl_int_6_232 bl_int_5_232 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c233
+ bl_int_1_233 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c234
+ bl_int_4_234 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c235
+ bl_int_6_235 bl_int_5_235 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c236
+ bl_int_5_236 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c237
+ bl_int_5_237 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c238
+ bl_int_6_238 bl_int_5_238 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c239
+ bl_int_6_239 bl_int_5_239 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c240
+ bl_int_6_240 bl_int_5_240 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c241
+ bl_int_5_241 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c242
+ bl_int_4_242 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c243
+ bl_int_4_243 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c244
+ bl_int_3_244 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c245
+ bl_int_4_245 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c246
+ bl_int_6_246 bl_int_5_246 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c247
+ bl_int_6_247 bl_int_5_247 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c248
+ bl_int_6_248 bl_int_5_248 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c249
+ bl_int_4_249 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c250
+ bl_int_6_250 bl_int_5_250 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c251
+ bl_int_3_251 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c252
+ bl_int_5_252 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c253
+ bl_int_5_253 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r6_c254
+ bl_int_6_254 bl_int_2_254 wl_0_6 gnd
+ rom_256b_rom_base_one_cell
Xbit_r6_c255
+ bl_int_4_255 wl_0_6 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c0
+ bl_int_7_0 bl_int_6_0 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c1
+ bl_int_7_1 bl_int_5_1 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c2
+ bl_int_5_2 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c3
+ bl_int_5_3 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c4
+ bl_int_6_4 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c5
+ bl_int_4_5 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c6
+ bl_int_7_6 bl_int_6_6 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c7
+ bl_int_7_7 bl_int_6_7 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c8
+ bl_int_3_8 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c9
+ bl_int_6_9 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c10
+ bl_int_4_10 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c11
+ bl_int_6_11 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c12
+ bl_int_7_12 bl_int_3_12 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c13
+ bl_int_7_13 bl_int_6_13 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c14
+ bl_int_5_14 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c15
+ bl_int_7_15 bl_int_3_15 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c16
+ bl_int_6_16 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c17
+ bl_int_4_17 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c18
+ bl_int_7_18 bl_int_6_18 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c19
+ bl_int_7_19 bl_int_6_19 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c20
+ bl_int_5_20 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c21
+ bl_int_7_21 bl_int_5_21 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c22
+ bl_int_7_22 bl_int_6_22 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c23
+ bl_int_7_23 bl_int_3_23 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c24
+ bl_int_6_24 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c25
+ bl_int_6_25 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c26
+ bl_int_4_26 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c27
+ bl_int_5_27 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c28
+ bl_int_6_28 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c29
+ bl_int_5_29 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c30
+ bl_int_7_30 bl_int_6_30 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c31
+ bl_int_2_31 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c32
+ bl_int_7_32 bl_int_6_32 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c33
+ bl_int_7_33 bl_int_5_33 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c34
+ bl_int_7_34 bl_int_6_34 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c35
+ bl_int_7_35 bl_0_35 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c36
+ bl_int_4_36 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c37
+ bl_int_7_37 bl_0_37 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c38
+ bl_int_5_38 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c39
+ bl_int_7_39 bl_int_6_39 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c40
+ bl_int_6_40 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c41
+ bl_int_6_41 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c42
+ bl_int_7_42 bl_int_3_42 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c43
+ bl_int_7_43 bl_int_5_43 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c44
+ bl_int_7_44 bl_int_4_44 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c45
+ bl_int_7_45 bl_int_1_45 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c46
+ bl_int_6_46 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c47
+ bl_int_6_47 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c48
+ bl_int_6_48 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c49
+ bl_int_7_49 bl_int_6_49 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c50
+ bl_int_7_50 bl_int_6_50 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c51
+ bl_int_7_51 bl_int_6_51 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c52
+ bl_int_2_52 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c53
+ bl_int_6_53 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c54
+ bl_int_1_54 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c55
+ bl_int_5_55 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c56
+ bl_int_5_56 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c57
+ bl_int_7_57 bl_int_6_57 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c58
+ bl_int_6_58 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c59
+ bl_int_7_59 bl_int_6_59 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c60
+ bl_int_7_60 bl_int_5_60 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c61
+ bl_int_6_61 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c62
+ bl_int_6_62 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c63
+ bl_int_5_63 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c64
+ bl_int_7_64 bl_int_2_64 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c65
+ bl_int_7_65 bl_int_6_65 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c66
+ bl_int_5_66 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c67
+ bl_int_5_67 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c68
+ bl_int_4_68 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c69
+ bl_int_7_69 bl_int_6_69 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c70
+ bl_int_7_70 bl_int_3_70 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c71
+ bl_int_7_71 bl_int_5_71 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c72
+ bl_int_6_72 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c73
+ bl_int_6_73 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c74
+ bl_int_7_74 bl_int_5_74 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c75
+ bl_int_7_75 bl_int_5_75 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c76
+ bl_int_3_76 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c77
+ bl_int_7_77 bl_int_6_77 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c78
+ bl_int_4_78 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c79
+ bl_int_5_79 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c80
+ bl_int_7_80 bl_int_2_80 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c81
+ bl_int_7_81 bl_int_6_81 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c82
+ bl_int_7_82 bl_int_4_82 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c83
+ bl_int_7_83 bl_int_4_83 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c84
+ bl_int_7_84 bl_int_4_84 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c85
+ bl_int_7_85 bl_int_1_85 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c86
+ bl_int_2_86 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c87
+ bl_int_6_87 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c88
+ bl_int_7_88 bl_int_6_88 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c89
+ bl_int_6_89 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c90
+ bl_int_6_90 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c91
+ bl_int_6_91 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c92
+ bl_int_5_92 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c93
+ bl_int_7_93 bl_int_5_93 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c94
+ bl_int_7_94 bl_int_6_94 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c95
+ bl_int_6_95 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c96
+ bl_int_7_96 bl_int_5_96 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c97
+ bl_int_7_97 bl_int_6_97 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c98
+ bl_int_4_98 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c99
+ bl_int_5_99 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c100
+ bl_int_7_100 bl_int_6_100 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c101
+ bl_int_6_101 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c102
+ bl_int_6_102 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c103
+ bl_int_7_103 bl_int_6_103 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c104
+ bl_int_6_104 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c105
+ bl_int_7_105 bl_int_5_105 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c106
+ bl_int_7_106 bl_int_5_106 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c107
+ bl_int_6_107 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c108
+ bl_int_7_108 bl_int_6_108 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c109
+ bl_int_5_109 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c110
+ bl_int_6_110 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c111
+ bl_int_4_111 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c112
+ bl_int_7_112 bl_int_6_112 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c113
+ bl_int_5_113 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c114
+ bl_int_5_114 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c115
+ bl_int_7_115 bl_int_6_115 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c116
+ bl_int_6_116 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c117
+ bl_int_7_117 bl_int_6_117 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c118
+ bl_int_5_118 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c119
+ bl_int_7_119 bl_int_6_119 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c120
+ bl_int_7_120 bl_int_6_120 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c121
+ bl_int_7_121 bl_int_6_121 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c122
+ bl_int_7_122 bl_int_4_122 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c123
+ bl_int_6_123 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c124
+ bl_int_5_124 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c125
+ bl_int_6_125 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c126
+ bl_int_0_126 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c127
+ bl_int_6_127 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c128
+ bl_int_7_128 bl_int_6_128 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c129
+ bl_int_7_129 bl_int_6_129 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c130
+ bl_int_6_130 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c131
+ bl_int_6_131 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c132
+ bl_int_7_132 bl_int_6_132 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c133
+ bl_int_5_133 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c134
+ bl_int_7_134 bl_int_4_134 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c135
+ bl_int_4_135 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c136
+ bl_int_7_136 bl_int_5_136 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c137
+ bl_int_7_137 bl_int_5_137 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c138
+ bl_int_7_138 bl_int_4_138 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c139
+ bl_int_6_139 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c140
+ bl_int_7_140 bl_0_140 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c141
+ bl_int_4_141 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c142
+ bl_int_3_142 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c143
+ bl_int_3_143 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c144
+ bl_int_4_144 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c145
+ bl_int_7_145 bl_int_5_145 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c146
+ bl_int_6_146 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c147
+ bl_int_7_147 bl_int_5_147 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c148
+ bl_int_7_148 bl_int_4_148 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c149
+ bl_int_7_149 bl_int_3_149 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c150
+ bl_int_6_150 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c151
+ bl_int_6_151 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c152
+ bl_int_7_152 bl_int_6_152 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c153
+ bl_int_7_153 bl_int_5_153 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c154
+ bl_int_6_154 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c155
+ bl_int_7_155 bl_int_6_155 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c156
+ bl_int_7_156 bl_int_5_156 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c157
+ bl_int_7_157 bl_int_6_157 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c158
+ bl_int_7_158 bl_int_6_158 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c159
+ bl_int_6_159 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c160
+ bl_int_7_160 bl_int_5_160 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c161
+ bl_int_4_161 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c162
+ bl_int_4_162 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c163
+ bl_int_6_163 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c164
+ bl_int_6_164 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c165
+ bl_int_5_165 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c166
+ bl_int_7_166 bl_int_4_166 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c167
+ bl_int_7_167 bl_int_6_167 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c168
+ bl_int_7_168 bl_int_2_168 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c169
+ bl_int_6_169 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c170
+ bl_int_4_170 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c171
+ bl_int_7_171 bl_int_6_171 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c172
+ bl_int_4_172 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c173
+ bl_int_6_173 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c174
+ bl_int_5_174 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c175
+ bl_int_7_175 bl_int_5_175 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c176
+ bl_int_7_176 bl_int_6_176 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c177
+ bl_int_7_177 bl_int_5_177 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c178
+ bl_int_7_178 bl_int_6_178 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c179
+ bl_int_3_179 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c180
+ bl_int_4_180 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c181
+ bl_int_7_181 bl_int_6_181 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c182
+ bl_int_5_182 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c183
+ bl_int_7_183 bl_int_6_183 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c184
+ bl_int_7_184 bl_int_5_184 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c185
+ bl_int_7_185 bl_int_6_185 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c186
+ bl_int_7_186 bl_int_3_186 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c187
+ bl_int_5_187 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c188
+ bl_int_6_188 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c189
+ bl_int_4_189 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c190
+ bl_int_5_190 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c191
+ bl_int_7_191 bl_0_191 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c192
+ bl_int_6_192 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c193
+ bl_int_2_193 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c194
+ bl_int_3_194 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c195
+ bl_int_7_195 bl_int_4_195 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c196
+ bl_int_6_196 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c197
+ bl_int_7_197 bl_int_6_197 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c198
+ bl_int_6_198 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c199
+ bl_int_6_199 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c200
+ bl_int_7_200 bl_int_5_200 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c201
+ bl_int_6_201 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c202
+ bl_int_7_202 bl_int_6_202 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c203
+ bl_int_6_203 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c204
+ bl_int_7_204 bl_int_6_204 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c205
+ bl_int_6_205 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c206
+ bl_int_7_206 bl_int_6_206 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c207
+ bl_int_6_207 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c208
+ bl_int_7_208 bl_int_1_208 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c209
+ bl_int_7_209 bl_int_6_209 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c210
+ bl_int_2_210 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c211
+ bl_int_5_211 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c212
+ bl_int_6_212 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c213
+ bl_int_7_213 bl_int_5_213 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c214
+ bl_int_7_214 bl_int_0_214 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c215
+ bl_int_2_215 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c216
+ bl_int_7_216 bl_int_6_216 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c217
+ bl_int_6_217 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c218
+ bl_int_7_218 bl_int_4_218 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c219
+ bl_int_7_219 bl_int_1_219 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c220
+ bl_int_7_220 bl_int_6_220 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c221
+ bl_int_6_221 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c222
+ bl_int_7_222 bl_int_5_222 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c223
+ bl_int_5_223 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c224
+ bl_int_6_224 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c225
+ bl_int_6_225 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c226
+ bl_int_6_226 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c227
+ bl_int_7_227 bl_int_6_227 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c228
+ bl_int_7_228 bl_int_5_228 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c229
+ bl_int_7_229 bl_int_4_229 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c230
+ bl_int_7_230 bl_int_4_230 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c231
+ bl_int_6_231 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c232
+ bl_int_6_232 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c233
+ bl_int_1_233 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c234
+ bl_int_7_234 bl_int_4_234 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c235
+ bl_int_6_235 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c236
+ bl_int_5_236 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c237
+ bl_int_7_237 bl_int_5_237 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c238
+ bl_int_7_238 bl_int_6_238 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c239
+ bl_int_6_239 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c240
+ bl_int_7_240 bl_int_6_240 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c241
+ bl_int_5_241 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c242
+ bl_int_4_242 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c243
+ bl_int_7_243 bl_int_4_243 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c244
+ bl_int_3_244 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c245
+ bl_int_7_245 bl_int_4_245 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c246
+ bl_int_6_246 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c247
+ bl_int_7_247 bl_int_6_247 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c248
+ bl_int_7_248 bl_int_6_248 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c249
+ bl_int_4_249 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c250
+ bl_int_7_250 bl_int_6_250 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c251
+ bl_int_3_251 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c252
+ bl_int_5_252 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r7_c253
+ bl_int_7_253 bl_int_5_253 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c254
+ bl_int_7_254 bl_int_6_254 wl_0_7 gnd
+ rom_256b_rom_base_one_cell
Xbit_r7_c255
+ bl_int_4_255 wl_0_7 gnd
+ rom_256b_rom_base_zero_cell
Xbit_r8_c0
+ gnd bl_int_7_0 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c1
+ gnd bl_int_7_1 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c2
+ gnd bl_int_5_2 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c3
+ gnd bl_int_5_3 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c4
+ gnd bl_int_6_4 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c5
+ gnd bl_int_4_5 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c6
+ gnd bl_int_7_6 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c7
+ gnd bl_int_7_7 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c8
+ gnd bl_int_3_8 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c9
+ gnd bl_int_6_9 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c10
+ gnd bl_int_4_10 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c11
+ gnd bl_int_6_11 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c12
+ gnd bl_int_7_12 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c13
+ gnd bl_int_7_13 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c14
+ gnd bl_int_5_14 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c15
+ gnd bl_int_7_15 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c16
+ gnd bl_int_6_16 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c17
+ gnd bl_int_4_17 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c18
+ gnd bl_int_7_18 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c19
+ gnd bl_int_7_19 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c20
+ gnd bl_int_5_20 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c21
+ gnd bl_int_7_21 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c22
+ gnd bl_int_7_22 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c23
+ gnd bl_int_7_23 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c24
+ gnd bl_int_6_24 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c25
+ gnd bl_int_6_25 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c26
+ gnd bl_int_4_26 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c27
+ gnd bl_int_5_27 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c28
+ gnd bl_int_6_28 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c29
+ gnd bl_int_5_29 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c30
+ gnd bl_int_7_30 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c31
+ gnd bl_int_2_31 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c32
+ gnd bl_int_7_32 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c33
+ gnd bl_int_7_33 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c34
+ gnd bl_int_7_34 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c35
+ gnd bl_int_7_35 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c36
+ gnd bl_int_4_36 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c37
+ gnd bl_int_7_37 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c38
+ gnd bl_int_5_38 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c39
+ gnd bl_int_7_39 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c40
+ gnd bl_int_6_40 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c41
+ gnd bl_int_6_41 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c42
+ gnd bl_int_7_42 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c43
+ gnd bl_int_7_43 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c44
+ gnd bl_int_7_44 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c45
+ gnd bl_int_7_45 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c46
+ gnd bl_int_6_46 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c47
+ gnd bl_int_6_47 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c48
+ gnd bl_int_6_48 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c49
+ gnd bl_int_7_49 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c50
+ gnd bl_int_7_50 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c51
+ gnd bl_int_7_51 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c52
+ gnd bl_int_2_52 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c53
+ gnd bl_int_6_53 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c54
+ gnd bl_int_1_54 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c55
+ gnd bl_int_5_55 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c56
+ gnd bl_int_5_56 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c57
+ gnd bl_int_7_57 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c58
+ gnd bl_int_6_58 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c59
+ gnd bl_int_7_59 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c60
+ gnd bl_int_7_60 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c61
+ gnd bl_int_6_61 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c62
+ gnd bl_int_6_62 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c63
+ gnd bl_int_5_63 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c64
+ gnd bl_int_7_64 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c65
+ gnd bl_int_7_65 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c66
+ gnd bl_int_5_66 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c67
+ gnd bl_int_5_67 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c68
+ gnd bl_int_4_68 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c69
+ gnd bl_int_7_69 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c70
+ gnd bl_int_7_70 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c71
+ gnd bl_int_7_71 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c72
+ gnd bl_int_6_72 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c73
+ gnd bl_int_6_73 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c74
+ gnd bl_int_7_74 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c75
+ gnd bl_int_7_75 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c76
+ gnd bl_int_3_76 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c77
+ gnd bl_int_7_77 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c78
+ gnd bl_int_4_78 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c79
+ gnd bl_int_5_79 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c80
+ gnd bl_int_7_80 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c81
+ gnd bl_int_7_81 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c82
+ gnd bl_int_7_82 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c83
+ gnd bl_int_7_83 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c84
+ gnd bl_int_7_84 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c85
+ gnd bl_int_7_85 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c86
+ gnd bl_int_2_86 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c87
+ gnd bl_int_6_87 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c88
+ gnd bl_int_7_88 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c89
+ gnd bl_int_6_89 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c90
+ gnd bl_int_6_90 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c91
+ gnd bl_int_6_91 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c92
+ gnd bl_int_5_92 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c93
+ gnd bl_int_7_93 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c94
+ gnd bl_int_7_94 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c95
+ gnd bl_int_6_95 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c96
+ gnd bl_int_7_96 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c97
+ gnd bl_int_7_97 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c98
+ gnd bl_int_4_98 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c99
+ gnd bl_int_5_99 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c100
+ gnd bl_int_7_100 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c101
+ gnd bl_int_6_101 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c102
+ gnd bl_int_6_102 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c103
+ gnd bl_int_7_103 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c104
+ gnd bl_int_6_104 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c105
+ gnd bl_int_7_105 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c106
+ gnd bl_int_7_106 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c107
+ gnd bl_int_6_107 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c108
+ gnd bl_int_7_108 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c109
+ gnd bl_int_5_109 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c110
+ gnd bl_int_6_110 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c111
+ gnd bl_int_4_111 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c112
+ gnd bl_int_7_112 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c113
+ gnd bl_int_5_113 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c114
+ gnd bl_int_5_114 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c115
+ gnd bl_int_7_115 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c116
+ gnd bl_int_6_116 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c117
+ gnd bl_int_7_117 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c118
+ gnd bl_int_5_118 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c119
+ gnd bl_int_7_119 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c120
+ gnd bl_int_7_120 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c121
+ gnd bl_int_7_121 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c122
+ gnd bl_int_7_122 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c123
+ gnd bl_int_6_123 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c124
+ gnd bl_int_5_124 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c125
+ gnd bl_int_6_125 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c126
+ gnd bl_int_0_126 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c127
+ gnd bl_int_6_127 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c128
+ gnd bl_int_7_128 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c129
+ gnd bl_int_7_129 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c130
+ gnd bl_int_6_130 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c131
+ gnd bl_int_6_131 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c132
+ gnd bl_int_7_132 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c133
+ gnd bl_int_5_133 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c134
+ gnd bl_int_7_134 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c135
+ gnd bl_int_4_135 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c136
+ gnd bl_int_7_136 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c137
+ gnd bl_int_7_137 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c138
+ gnd bl_int_7_138 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c139
+ gnd bl_int_6_139 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c140
+ gnd bl_int_7_140 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c141
+ gnd bl_int_4_141 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c142
+ gnd bl_int_3_142 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c143
+ gnd bl_int_3_143 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c144
+ gnd bl_int_4_144 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c145
+ gnd bl_int_7_145 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c146
+ gnd bl_int_6_146 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c147
+ gnd bl_int_7_147 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c148
+ gnd bl_int_7_148 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c149
+ gnd bl_int_7_149 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c150
+ gnd bl_int_6_150 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c151
+ gnd bl_int_6_151 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c152
+ gnd bl_int_7_152 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c153
+ gnd bl_int_7_153 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c154
+ gnd bl_int_6_154 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c155
+ gnd bl_int_7_155 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c156
+ gnd bl_int_7_156 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c157
+ gnd bl_int_7_157 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c158
+ gnd bl_int_7_158 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c159
+ gnd bl_int_6_159 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c160
+ gnd bl_int_7_160 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c161
+ gnd bl_int_4_161 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c162
+ gnd bl_int_4_162 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c163
+ gnd bl_int_6_163 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c164
+ gnd bl_int_6_164 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c165
+ gnd bl_int_5_165 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c166
+ gnd bl_int_7_166 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c167
+ gnd bl_int_7_167 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c168
+ gnd bl_int_7_168 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c169
+ gnd bl_int_6_169 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c170
+ gnd bl_int_4_170 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c171
+ gnd bl_int_7_171 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c172
+ gnd bl_int_4_172 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c173
+ gnd bl_int_6_173 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c174
+ gnd bl_int_5_174 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c175
+ gnd bl_int_7_175 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c176
+ gnd bl_int_7_176 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c177
+ gnd bl_int_7_177 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c178
+ gnd bl_int_7_178 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c179
+ gnd bl_int_3_179 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c180
+ gnd bl_int_4_180 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c181
+ gnd bl_int_7_181 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c182
+ gnd bl_int_5_182 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c183
+ gnd bl_int_7_183 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c184
+ gnd bl_int_7_184 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c185
+ gnd bl_int_7_185 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c186
+ gnd bl_int_7_186 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c187
+ gnd bl_int_5_187 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c188
+ gnd bl_int_6_188 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c189
+ gnd bl_int_4_189 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c190
+ gnd bl_int_5_190 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c191
+ gnd bl_int_7_191 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c192
+ gnd bl_int_6_192 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c193
+ gnd bl_int_2_193 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c194
+ gnd bl_int_3_194 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c195
+ gnd bl_int_7_195 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c196
+ gnd bl_int_6_196 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c197
+ gnd bl_int_7_197 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c198
+ gnd bl_int_6_198 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c199
+ gnd bl_int_6_199 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c200
+ gnd bl_int_7_200 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c201
+ gnd bl_int_6_201 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c202
+ gnd bl_int_7_202 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c203
+ gnd bl_int_6_203 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c204
+ gnd bl_int_7_204 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c205
+ gnd bl_int_6_205 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c206
+ gnd bl_int_7_206 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c207
+ gnd bl_int_6_207 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c208
+ gnd bl_int_7_208 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c209
+ gnd bl_int_7_209 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c210
+ gnd bl_int_2_210 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c211
+ gnd bl_int_5_211 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c212
+ gnd bl_int_6_212 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c213
+ gnd bl_int_7_213 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c214
+ gnd bl_int_7_214 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c215
+ gnd bl_int_2_215 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c216
+ gnd bl_int_7_216 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c217
+ gnd bl_int_6_217 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c218
+ gnd bl_int_7_218 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c219
+ gnd bl_int_7_219 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c220
+ gnd bl_int_7_220 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c221
+ gnd bl_int_6_221 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c222
+ gnd bl_int_7_222 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c223
+ gnd bl_int_5_223 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c224
+ gnd bl_int_6_224 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c225
+ gnd bl_int_6_225 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c226
+ gnd bl_int_6_226 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c227
+ gnd bl_int_7_227 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c228
+ gnd bl_int_7_228 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c229
+ gnd bl_int_7_229 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c230
+ gnd bl_int_7_230 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c231
+ gnd bl_int_6_231 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c232
+ gnd bl_int_6_232 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c233
+ gnd bl_int_1_233 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c234
+ gnd bl_int_7_234 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c235
+ gnd bl_int_6_235 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c236
+ gnd bl_int_5_236 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c237
+ gnd bl_int_7_237 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c238
+ gnd bl_int_7_238 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c239
+ gnd bl_int_6_239 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c240
+ gnd bl_int_7_240 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c241
+ gnd bl_int_5_241 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c242
+ gnd bl_int_4_242 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c243
+ gnd bl_int_7_243 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c244
+ gnd bl_int_3_244 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c245
+ gnd bl_int_7_245 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c246
+ gnd bl_int_6_246 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c247
+ gnd bl_int_7_247 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c248
+ gnd bl_int_7_248 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c249
+ gnd bl_int_4_249 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c250
+ gnd bl_int_7_250 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c251
+ gnd bl_int_3_251 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c252
+ gnd bl_int_5_252 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c253
+ gnd bl_int_7_253 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c254
+ gnd bl_int_7_254 precharge gnd
+ rom_256b_rom_base_one_cell
Xbit_r8_c255
+ gnd bl_int_4_255 precharge gnd
+ rom_256b_rom_base_one_cell
Xbitcell_array_precharge
+ bl_0_0 bl_0_1 bl_0_2 bl_0_3 bl_0_4 bl_0_5 bl_0_6 bl_0_7 bl_0_8 bl_0_9
+ bl_0_10 bl_0_11 bl_0_12 bl_0_13 bl_0_14 bl_0_15 bl_0_16 bl_0_17
+ bl_0_18 bl_0_19 bl_0_20 bl_0_21 bl_0_22 bl_0_23 bl_0_24 bl_0_25
+ bl_0_26 bl_0_27 bl_0_28 bl_0_29 bl_0_30 bl_0_31 bl_0_32 bl_0_33
+ bl_0_34 bl_0_35 bl_0_36 bl_0_37 bl_0_38 bl_0_39 bl_0_40 bl_0_41
+ bl_0_42 bl_0_43 bl_0_44 bl_0_45 bl_0_46 bl_0_47 bl_0_48 bl_0_49
+ bl_0_50 bl_0_51 bl_0_52 bl_0_53 bl_0_54 bl_0_55 bl_0_56 bl_0_57
+ bl_0_58 bl_0_59 bl_0_60 bl_0_61 bl_0_62 bl_0_63 bl_0_64 bl_0_65
+ bl_0_66 bl_0_67 bl_0_68 bl_0_69 bl_0_70 bl_0_71 bl_0_72 bl_0_73
+ bl_0_74 bl_0_75 bl_0_76 bl_0_77 bl_0_78 bl_0_79 bl_0_80 bl_0_81
+ bl_0_82 bl_0_83 bl_0_84 bl_0_85 bl_0_86 bl_0_87 bl_0_88 bl_0_89
+ bl_0_90 bl_0_91 bl_0_92 bl_0_93 bl_0_94 bl_0_95 bl_0_96 bl_0_97
+ bl_0_98 bl_0_99 bl_0_100 bl_0_101 bl_0_102 bl_0_103 bl_0_104 bl_0_105
+ bl_0_106 bl_0_107 bl_0_108 bl_0_109 bl_0_110 bl_0_111 bl_0_112
+ bl_0_113 bl_0_114 bl_0_115 bl_0_116 bl_0_117 bl_0_118 bl_0_119
+ bl_0_120 bl_0_121 bl_0_122 bl_0_123 bl_0_124 bl_0_125 bl_0_126
+ bl_0_127 bl_0_128 bl_0_129 bl_0_130 bl_0_131 bl_0_132 bl_0_133
+ bl_0_134 bl_0_135 bl_0_136 bl_0_137 bl_0_138 bl_0_139 bl_0_140
+ bl_0_141 bl_0_142 bl_0_143 bl_0_144 bl_0_145 bl_0_146 bl_0_147
+ bl_0_148 bl_0_149 bl_0_150 bl_0_151 bl_0_152 bl_0_153 bl_0_154
+ bl_0_155 bl_0_156 bl_0_157 bl_0_158 bl_0_159 bl_0_160 bl_0_161
+ bl_0_162 bl_0_163 bl_0_164 bl_0_165 bl_0_166 bl_0_167 bl_0_168
+ bl_0_169 bl_0_170 bl_0_171 bl_0_172 bl_0_173 bl_0_174 bl_0_175
+ bl_0_176 bl_0_177 bl_0_178 bl_0_179 bl_0_180 bl_0_181 bl_0_182
+ bl_0_183 bl_0_184 bl_0_185 bl_0_186 bl_0_187 bl_0_188 bl_0_189
+ bl_0_190 bl_0_191 bl_0_192 bl_0_193 bl_0_194 bl_0_195 bl_0_196
+ bl_0_197 bl_0_198 bl_0_199 bl_0_200 bl_0_201 bl_0_202 bl_0_203
+ bl_0_204 bl_0_205 bl_0_206 bl_0_207 bl_0_208 bl_0_209 bl_0_210
+ bl_0_211 bl_0_212 bl_0_213 bl_0_214 bl_0_215 bl_0_216 bl_0_217
+ bl_0_218 bl_0_219 bl_0_220 bl_0_221 bl_0_222 bl_0_223 bl_0_224
+ bl_0_225 bl_0_226 bl_0_227 bl_0_228 bl_0_229 bl_0_230 bl_0_231
+ bl_0_232 bl_0_233 bl_0_234 bl_0_235 bl_0_236 bl_0_237 bl_0_238
+ bl_0_239 bl_0_240 bl_0_241 bl_0_242 bl_0_243 bl_0_244 bl_0_245
+ bl_0_246 bl_0_247 bl_0_248 bl_0_249 bl_0_250 bl_0_251 bl_0_252
+ bl_0_253 bl_0_254 bl_0_255 precharge vdd
+ rom_256b_rom_precharge_array
.ENDS rom_256b_rom_base_array

* spice ptx X{0} {1} sky130_fd_pr__nfet_01v8 m=1 w=0.36 l=0.15 pd=1.02 ps=1.02 as=0.14u ad=0.14u

* spice ptx X{0} {1} sky130_fd_pr__pfet_01v8 m=1 w=1.12 l=0.15 pd=2.54 ps=2.54 as=0.42u ad=0.42u

.SUBCKT rom_256b_pinv
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* size: 1
Xpinv_pmos Z A vdd vdd sky130_fd_pr__pfet_01v8 m=1 w=1.12u l=0.15u
Xpinv_nmos Z A gnd gnd sky130_fd_pr__nfet_01v8 m=1 w=0.36u l=0.15u
.ENDS rom_256b_pinv

* spice ptx X{0} {1} sky130_fd_pr__pfet_01v8 m=3 w=3.0 l=0.15 pd=6.30 ps=6.30 as=1.12u ad=1.12u

* spice ptx X{0} {1} sky130_fd_pr__nfet_01v8 m=3 w=3.0 l=0.15 pd=6.30 ps=6.30 as=1.12u ad=1.12u

.SUBCKT rom_256b_pinv_1
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* size: 7
Xpinv_pmos Z A vdd vdd sky130_fd_pr__pfet_01v8 m=3 w=3.0u l=0.15u
Xpinv_nmos Z A gnd gnd sky130_fd_pr__nfet_01v8 m=3 w=3.0u l=0.15u
.ENDS rom_256b_pinv_1

* spice ptx X{0} {1} sky130_fd_pr__pfet_01v8 m=2 w=1.26 l=0.15 pd=2.82 ps=2.82 as=0.47u ad=0.47u

* spice ptx X{0} {1} sky130_fd_pr__nfet_01v8 m=2 w=0.74 l=0.15 pd=1.78 ps=1.78 as=0.28u ad=0.28u

.SUBCKT rom_256b_pinv_0
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* size: 2
Xpinv_pmos Z A vdd vdd sky130_fd_pr__pfet_01v8 m=2 w=1.26u l=0.15u
Xpinv_nmos Z A gnd gnd sky130_fd_pr__nfet_01v8 m=2 w=0.74u l=0.15u
.ENDS rom_256b_pinv_0

.SUBCKT rom_256b_rom_clock_driver
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* sizes: [1, 1, 2, 7]
Xbuf_inv1
+ A Zb1_int vdd gnd
+ rom_256b_pinv
Xbuf_inv2
+ Zb1_int Zb2_int vdd gnd
+ rom_256b_pinv
Xbuf_inv3
+ Zb2_int Zb3_int vdd gnd
+ rom_256b_pinv_0
Xbuf_inv4
+ Zb3_int Z vdd gnd
+ rom_256b_pinv_1
.ENDS rom_256b_rom_clock_driver

* spice ptx X{0} {1} sky130_fd_pr__pfet_01v8 m=20 w=5.0 l=0.15 pd=10.30 ps=10.30 as=1.88u ad=1.88u

* spice ptx X{0} {1} sky130_fd_pr__nfet_01v8 m=20 w=5.0 l=0.15 pd=10.30 ps=10.30 as=1.88u ad=1.88u

.SUBCKT rom_256b_pinv_5
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* size: 91
Xpinv_pmos Z A vdd vdd sky130_fd_pr__pfet_01v8 m=20 w=5.0u l=0.15u
Xpinv_nmos Z A gnd gnd sky130_fd_pr__nfet_01v8 m=20 w=5.0u l=0.15u
.ENDS rom_256b_pinv_5

* spice ptx X{0} {1} sky130_fd_pr__nfet_01v8 m=7 w=3.0 l=0.15 pd=6.30 ps=6.30 as=1.12u ad=1.12u

* spice ptx X{0} {1} sky130_fd_pr__pfet_01v8 m=7 w=5.0 l=0.15 pd=10.30 ps=10.30 as=1.88u ad=1.88u

.SUBCKT rom_256b_pinv_4
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* size: 30
Xpinv_pmos Z A vdd vdd sky130_fd_pr__pfet_01v8 m=7 w=5.0u l=0.15u
Xpinv_nmos Z A gnd gnd sky130_fd_pr__nfet_01v8 m=7 w=3.0u l=0.15u
.ENDS rom_256b_pinv_4

* spice ptx X{0} {1} sky130_fd_pr__nfet_01v8 m=4 w=2.0 l=0.15 pd=4.30 ps=4.30 as=0.75u ad=0.75u

* spice ptx X{0} {1} sky130_fd_pr__pfet_01v8 m=4 w=3.0 l=0.15 pd=6.30 ps=6.30 as=1.12u ad=1.12u

.SUBCKT rom_256b_pinv_3
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* size: 10
Xpinv_pmos Z A vdd vdd sky130_fd_pr__pfet_01v8 m=4 w=3.0u l=0.15u
Xpinv_nmos Z A gnd gnd sky130_fd_pr__nfet_01v8 m=4 w=2.0u l=0.15u
.ENDS rom_256b_pinv_3

* spice ptx X{0} {1} sky130_fd_pr__nfet_01v8 m=2 w=1.26 l=0.15 pd=2.82 ps=2.82 as=0.47u ad=0.47u

* spice ptx X{0} {1} sky130_fd_pr__pfet_01v8 m=2 w=2.0 l=0.15 pd=4.30 ps=4.30 as=0.75u ad=0.75u

.SUBCKT rom_256b_pinv_2
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* size: 3
Xpinv_pmos Z A vdd vdd sky130_fd_pr__pfet_01v8 m=2 w=2.0u l=0.15u
Xpinv_nmos Z A gnd gnd sky130_fd_pr__nfet_01v8 m=2 w=1.26u l=0.15u
.ENDS rom_256b_pinv_2

.SUBCKT rom_256b_rom_precharge_driver
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* sizes: [1, 1, 1, 3, 10, 30, 91]
Xbuf_inv1
+ A Zb1_int vdd gnd
+ rom_256b_pinv
Xbuf_inv2
+ Zb1_int Zb2_int vdd gnd
+ rom_256b_pinv
Xbuf_inv3
+ Zb2_int Zb3_int vdd gnd
+ rom_256b_pinv
Xbuf_inv4
+ Zb3_int Zb4_int vdd gnd
+ rom_256b_pinv_2
Xbuf_inv5
+ Zb4_int Zb5_int vdd gnd
+ rom_256b_pinv_3
Xbuf_inv6
+ Zb5_int Zb6_int vdd gnd
+ rom_256b_pinv_4
Xbuf_inv7
+ Zb6_int Z vdd gnd
+ rom_256b_pinv_5
.ENDS rom_256b_rom_precharge_driver

* spice ptx X{0} {1} sky130_fd_pr__nfet_01v8 m=1 w=0.74 l=0.15 pd=1.78 ps=1.78 as=0.28u ad=0.28u

* spice ptx X{0} {1} sky130_fd_pr__pfet_01v8 m=1 w=1.12 l=0.15 pd=2.54 ps=2.54 as=0.42u ad=0.42u

* spice ptx X{0} {1} sky130_fd_pr__nfet_01v8 m=1 w=0.74 l=0.15 pd=1.78 ps=1.78 as=0.28u ad=0.28u

.SUBCKT rom_256b_rom_control_nand
+ A B Z vdd gnd
* INPUT : A 
* INPUT : B 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* size: 1
Xpnand2_pmos1 vdd A Z vdd sky130_fd_pr__pfet_01v8 m=1 w=1.12u l=0.15u
Xpnand2_pmos2 Z B vdd vdd sky130_fd_pr__pfet_01v8 m=1 w=1.12u l=0.15u
Xpnand2_nmos1 Z B net1 gnd sky130_fd_pr__nfet_01v8 m=1 w=0.74u l=0.15u
Xpnand2_nmos2 net1 A gnd gnd sky130_fd_pr__nfet_01v8 m=1 w=0.74u l=0.15u
.ENDS rom_256b_rom_control_nand

.SUBCKT rom_256b_rom_control_logic
+ clk_in CS prechrg clk_out vdd gnd
* INPUT : clk_in 
* INPUT : CS 
* OUTPUT: prechrg 
* OUTPUT: clk_out 
* POWER : vdd 
* GROUND: gnd 
Xclk_driver
+ clk_in clk_out vdd gnd
+ rom_256b_rom_clock_driver
Xcontrol_nand
+ CS clk_out pre_drive vdd gnd
+ rom_256b_rom_control_nand
Xprecharge_driver
+ pre_drive prechrg vdd gnd
+ rom_256b_rom_precharge_driver
.ENDS rom_256b_rom_control_logic

.SUBCKT rom_256b_pinv_dec_4
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* size: 4
Xpinv_pmos Z A vdd vdd sky130_fd_pr__pfet_01v8 m=1 w=5.0u l=0.15u
Xpinv_nmos Z A gnd gnd sky130_fd_pr__nfet_01v8 m=1 w=1.68u l=0.15u
.ENDS rom_256b_pinv_dec_4

.SUBCKT rom_256b_rom_output_buffer
+ in_0 in_1 in_2 in_3 in_4 in_5 in_6 in_7 in_8 in_9 in_10 in_11 in_12
+ in_13 in_14 in_15 in_16 in_17 in_18 in_19 in_20 in_21 in_22 in_23
+ in_24 in_25 in_26 in_27 in_28 in_29 in_30 in_31 out_0 out_1 out_2
+ out_3 out_4 out_5 out_6 out_7 out_8 out_9 out_10 out_11 out_12 out_13
+ out_14 out_15 out_16 out_17 out_18 out_19 out_20 out_21 out_22 out_23
+ out_24 out_25 out_26 out_27 out_28 out_29 out_30 out_31 vdd gnd
* INPUT : in_0 
* INPUT : in_1 
* INPUT : in_2 
* INPUT : in_3 
* INPUT : in_4 
* INPUT : in_5 
* INPUT : in_6 
* INPUT : in_7 
* INPUT : in_8 
* INPUT : in_9 
* INPUT : in_10 
* INPUT : in_11 
* INPUT : in_12 
* INPUT : in_13 
* INPUT : in_14 
* INPUT : in_15 
* INPUT : in_16 
* INPUT : in_17 
* INPUT : in_18 
* INPUT : in_19 
* INPUT : in_20 
* INPUT : in_21 
* INPUT : in_22 
* INPUT : in_23 
* INPUT : in_24 
* INPUT : in_25 
* INPUT : in_26 
* INPUT : in_27 
* INPUT : in_28 
* INPUT : in_29 
* INPUT : in_30 
* INPUT : in_31 
* OUTPUT: out_0 
* OUTPUT: out_1 
* OUTPUT: out_2 
* OUTPUT: out_3 
* OUTPUT: out_4 
* OUTPUT: out_5 
* OUTPUT: out_6 
* OUTPUT: out_7 
* OUTPUT: out_8 
* OUTPUT: out_9 
* OUTPUT: out_10 
* OUTPUT: out_11 
* OUTPUT: out_12 
* OUTPUT: out_13 
* OUTPUT: out_14 
* OUTPUT: out_15 
* OUTPUT: out_16 
* OUTPUT: out_17 
* OUTPUT: out_18 
* OUTPUT: out_19 
* OUTPUT: out_20 
* OUTPUT: out_21 
* OUTPUT: out_22 
* OUTPUT: out_23 
* OUTPUT: out_24 
* OUTPUT: out_25 
* OUTPUT: out_26 
* OUTPUT: out_27 
* OUTPUT: out_28 
* OUTPUT: out_29 
* OUTPUT: out_30 
* OUTPUT: out_31 
* POWER : vdd 
* GROUND: gnd 
* rows: 32 Buffer size of: 4
Xwld0
+ in_0 out_0 vdd gnd
+ rom_256b_pinv_dec_4
Xwld1
+ in_1 out_1 vdd gnd
+ rom_256b_pinv_dec_4
Xwld2
+ in_2 out_2 vdd gnd
+ rom_256b_pinv_dec_4
Xwld3
+ in_3 out_3 vdd gnd
+ rom_256b_pinv_dec_4
Xwld4
+ in_4 out_4 vdd gnd
+ rom_256b_pinv_dec_4
Xwld5
+ in_5 out_5 vdd gnd
+ rom_256b_pinv_dec_4
Xwld6
+ in_6 out_6 vdd gnd
+ rom_256b_pinv_dec_4
Xwld7
+ in_7 out_7 vdd gnd
+ rom_256b_pinv_dec_4
Xwld8
+ in_8 out_8 vdd gnd
+ rom_256b_pinv_dec_4
Xwld9
+ in_9 out_9 vdd gnd
+ rom_256b_pinv_dec_4
Xwld10
+ in_10 out_10 vdd gnd
+ rom_256b_pinv_dec_4
Xwld11
+ in_11 out_11 vdd gnd
+ rom_256b_pinv_dec_4
Xwld12
+ in_12 out_12 vdd gnd
+ rom_256b_pinv_dec_4
Xwld13
+ in_13 out_13 vdd gnd
+ rom_256b_pinv_dec_4
Xwld14
+ in_14 out_14 vdd gnd
+ rom_256b_pinv_dec_4
Xwld15
+ in_15 out_15 vdd gnd
+ rom_256b_pinv_dec_4
Xwld16
+ in_16 out_16 vdd gnd
+ rom_256b_pinv_dec_4
Xwld17
+ in_17 out_17 vdd gnd
+ rom_256b_pinv_dec_4
Xwld18
+ in_18 out_18 vdd gnd
+ rom_256b_pinv_dec_4
Xwld19
+ in_19 out_19 vdd gnd
+ rom_256b_pinv_dec_4
Xwld20
+ in_20 out_20 vdd gnd
+ rom_256b_pinv_dec_4
Xwld21
+ in_21 out_21 vdd gnd
+ rom_256b_pinv_dec_4
Xwld22
+ in_22 out_22 vdd gnd
+ rom_256b_pinv_dec_4
Xwld23
+ in_23 out_23 vdd gnd
+ rom_256b_pinv_dec_4
Xwld24
+ in_24 out_24 vdd gnd
+ rom_256b_pinv_dec_4
Xwld25
+ in_25 out_25 vdd gnd
+ rom_256b_pinv_dec_4
Xwld26
+ in_26 out_26 vdd gnd
+ rom_256b_pinv_dec_4
Xwld27
+ in_27 out_27 vdd gnd
+ rom_256b_pinv_dec_4
Xwld28
+ in_28 out_28 vdd gnd
+ rom_256b_pinv_dec_4
Xwld29
+ in_29 out_29 vdd gnd
+ rom_256b_pinv_dec_4
Xwld30
+ in_30 out_30 vdd gnd
+ rom_256b_pinv_dec_4
Xwld31
+ in_31 out_31 vdd gnd
+ rom_256b_pinv_dec_4
.ENDS rom_256b_rom_output_buffer

.SUBCKT rom_256b_pinv_dec_2
+ A Z vdd gnd
* INPUT : A 
* OUTPUT: Z 
* POWER : vdd 
* GROUND: gnd 
* size: 2
Xpinv_pmos Z A vdd vdd sky130_fd_pr__pfet_01v8 m=1 w=3.0u l=0.15u
Xpinv_nmos Z A gnd gnd sky130_fd_pr__nfet_01v8 m=1 w=0.74u l=0.15u
.ENDS rom_256b_pinv_dec_2

.SUBCKT rom_256b_rom_column_decode_wordline_buffer
+ in_0 in_1 in_2 in_3 in_4 in_5 in_6 in_7 out_0 out_1 out_2 out_3 out_4
+ out_5 out_6 out_7 vdd gnd
* INPUT : in_0 
* INPUT : in_1 
* INPUT : in_2 
* INPUT : in_3 
* INPUT : in_4 
* INPUT : in_5 
* INPUT : in_6 
* INPUT : in_7 
* OUTPUT: out_0 
* OUTPUT: out_1 
* OUTPUT: out_2 
* OUTPUT: out_3 
* OUTPUT: out_4 
* OUTPUT: out_5 
* OUTPUT: out_6 
* OUTPUT: out_7 
* POWER : vdd 
* GROUND: gnd 
* rows: 8 Buffer size of: 2
Xwld0
+ in_0 out_0 vdd gnd
+ rom_256b_pinv_dec_2
Xwld1
+ in_1 out_1 vdd gnd
+ rom_256b_pinv_dec_2
Xwld2
+ in_2 out_2 vdd gnd
+ rom_256b_pinv_dec_2
Xwld3
+ in_3 out_3 vdd gnd
+ rom_256b_pinv_dec_2
Xwld4
+ in_4 out_4 vdd gnd
+ rom_256b_pinv_dec_2
Xwld5
+ in_5 out_5 vdd gnd
+ rom_256b_pinv_dec_2
Xwld6
+ in_6 out_6 vdd gnd
+ rom_256b_pinv_dec_2
Xwld7
+ in_7 out_7 vdd gnd
+ rom_256b_pinv_dec_2
.ENDS rom_256b_rom_column_decode_wordline_buffer

.SUBCKT rom_256b_rom_column_decode
+ A0 A1 A2 wl_0 wl_1 wl_2 wl_3 wl_4 wl_5 wl_6 wl_7 precharge clk vdd gnd
* INPUT : A0 
* INPUT : A1 
* INPUT : A2 
* OUTPUT: wl_0 
* OUTPUT: wl_1 
* OUTPUT: wl_2 
* OUTPUT: wl_3 
* OUTPUT: wl_4 
* OUTPUT: wl_5 
* OUTPUT: wl_6 
* OUTPUT: wl_7 
* INPUT : precharge 
* INPUT : clk 
* POWER : vdd 
* GROUND: gnd 
Xdecode_array_inst
+ wl_int0 wl_int1 wl_int2 wl_int3 wl_int4 wl_int5 wl_int6 wl_int7
+ Ab_int_2 A_int_2 Ab_int_1 A_int_1 Ab_int_0 A_int_0 precharge vdd gnd
+ rom_256b_rom_row_decode_array
Xpre_control_array
+ A0 A1 A2 A_int_0 A_int_1 A_int_2 Ab_int_0 Ab_int_1 Ab_int_2 clk vdd
+ gnd
+ rom_256b_rom_address_control_array
Xrom_wordline_driver
+ wl_int0 wl_int1 wl_int2 wl_int3 wl_int4 wl_int5 wl_int6 wl_int7 wl_0
+ wl_1 wl_2 wl_3 wl_4 wl_5 wl_6 wl_7 vdd gnd
+ rom_256b_rom_column_decode_wordline_buffer
.ENDS rom_256b_rom_column_decode

.SUBCKT rom_256b
+ clk0 cs0 addr0[0] addr0[1] addr0[2] addr0[3] addr0[4] addr0[5]
+ dout0[0] dout0[1] dout0[2] dout0[3] dout0[4] dout0[5] dout0[6]
+ dout0[7] dout0[8] dout0[9] dout0[10] dout0[11] dout0[12] dout0[13]
+ dout0[14] dout0[15] dout0[16] dout0[17] dout0[18] dout0[19] dout0[20]
+ dout0[21] dout0[22] dout0[23] dout0[24] dout0[25] dout0[26] dout0[27]
+ dout0[28] dout0[29] dout0[30] dout0[31] vccd1 vssd1
* INPUT : clk0 
* INPUT : cs0 
* INPUT : addr0[0] 
* INPUT : addr0[1] 
* INPUT : addr0[2] 
* INPUT : addr0[3] 
* INPUT : addr0[4] 
* INPUT : addr0[5] 
* OUTPUT: dout0[0] 
* OUTPUT: dout0[1] 
* OUTPUT: dout0[2] 
* OUTPUT: dout0[3] 
* OUTPUT: dout0[4] 
* OUTPUT: dout0[5] 
* OUTPUT: dout0[6] 
* OUTPUT: dout0[7] 
* OUTPUT: dout0[8] 
* OUTPUT: dout0[9] 
* OUTPUT: dout0[10] 
* OUTPUT: dout0[11] 
* OUTPUT: dout0[12] 
* OUTPUT: dout0[13] 
* OUTPUT: dout0[14] 
* OUTPUT: dout0[15] 
* OUTPUT: dout0[16] 
* OUTPUT: dout0[17] 
* OUTPUT: dout0[18] 
* OUTPUT: dout0[19] 
* OUTPUT: dout0[20] 
* OUTPUT: dout0[21] 
* OUTPUT: dout0[22] 
* OUTPUT: dout0[23] 
* OUTPUT: dout0[24] 
* OUTPUT: dout0[25] 
* OUTPUT: dout0[26] 
* OUTPUT: dout0[27] 
* OUTPUT: dout0[28] 
* OUTPUT: dout0[29] 
* OUTPUT: dout0[30] 
* OUTPUT: dout0[31] 
* POWER : vccd1 
* GROUND: vssd1 
Xrom_bit_array
+ bl_0 bl_1 bl_2 bl_3 bl_4 bl_5 bl_6 bl_7 bl_8 bl_9 bl_10 bl_11 bl_12
+ bl_13 bl_14 bl_15 bl_16 bl_17 bl_18 bl_19 bl_20 bl_21 bl_22 bl_23
+ bl_24 bl_25 bl_26 bl_27 bl_28 bl_29 bl_30 bl_31 bl_32 bl_33 bl_34
+ bl_35 bl_36 bl_37 bl_38 bl_39 bl_40 bl_41 bl_42 bl_43 bl_44 bl_45
+ bl_46 bl_47 bl_48 bl_49 bl_50 bl_51 bl_52 bl_53 bl_54 bl_55 bl_56
+ bl_57 bl_58 bl_59 bl_60 bl_61 bl_62 bl_63 bl_64 bl_65 bl_66 bl_67
+ bl_68 bl_69 bl_70 bl_71 bl_72 bl_73 bl_74 bl_75 bl_76 bl_77 bl_78
+ bl_79 bl_80 bl_81 bl_82 bl_83 bl_84 bl_85 bl_86 bl_87 bl_88 bl_89
+ bl_90 bl_91 bl_92 bl_93 bl_94 bl_95 bl_96 bl_97 bl_98 bl_99 bl_100
+ bl_101 bl_102 bl_103 bl_104 bl_105 bl_106 bl_107 bl_108 bl_109 bl_110
+ bl_111 bl_112 bl_113 bl_114 bl_115 bl_116 bl_117 bl_118 bl_119 bl_120
+ bl_121 bl_122 bl_123 bl_124 bl_125 bl_126 bl_127 bl_128 bl_129 bl_130
+ bl_131 bl_132 bl_133 bl_134 bl_135 bl_136 bl_137 bl_138 bl_139 bl_140
+ bl_141 bl_142 bl_143 bl_144 bl_145 bl_146 bl_147 bl_148 bl_149 bl_150
+ bl_151 bl_152 bl_153 bl_154 bl_155 bl_156 bl_157 bl_158 bl_159 bl_160
+ bl_161 bl_162 bl_163 bl_164 bl_165 bl_166 bl_167 bl_168 bl_169 bl_170
+ bl_171 bl_172 bl_173 bl_174 bl_175 bl_176 bl_177 bl_178 bl_179 bl_180
+ bl_181 bl_182 bl_183 bl_184 bl_185 bl_186 bl_187 bl_188 bl_189 bl_190
+ bl_191 bl_192 bl_193 bl_194 bl_195 bl_196 bl_197 bl_198 bl_199 bl_200
+ bl_201 bl_202 bl_203 bl_204 bl_205 bl_206 bl_207 bl_208 bl_209 bl_210
+ bl_211 bl_212 bl_213 bl_214 bl_215 bl_216 bl_217 bl_218 bl_219 bl_220
+ bl_221 bl_222 bl_223 bl_224 bl_225 bl_226 bl_227 bl_228 bl_229 bl_230
+ bl_231 bl_232 bl_233 bl_234 bl_235 bl_236 bl_237 bl_238 bl_239 bl_240
+ bl_241 bl_242 bl_243 bl_244 bl_245 bl_246 bl_247 bl_248 bl_249 bl_250
+ bl_251 bl_252 bl_253 bl_254 bl_255 wl_0 wl_1 wl_2 wl_3 wl_4 wl_5 wl_6
+ wl_7 precharge vccd1 vssd1
+ rom_256b_rom_base_array
Xrom_row_decoder
+ addr0[3] addr0[4] addr0[5] wl_0 wl_1 wl_2 wl_3 wl_4 wl_5 wl_6 wl_7
+ clk_int clk_int vccd1 vssd1
+ rom_256b_rom_row_decode
Xrom_control
+ clk0 cs0 precharge clk_int vccd1 vssd1
+ rom_256b_rom_control_logic
Xrom_column_mux
+ bl_b_0 bl_b_1 bl_b_2 bl_b_3 bl_b_4 bl_b_5 bl_b_6 bl_b_7 bl_b_8 bl_b_9
+ bl_b_10 bl_b_11 bl_b_12 bl_b_13 bl_b_14 bl_b_15 bl_b_16 bl_b_17
+ bl_b_18 bl_b_19 bl_b_20 bl_b_21 bl_b_22 bl_b_23 bl_b_24 bl_b_25
+ bl_b_26 bl_b_27 bl_b_28 bl_b_29 bl_b_30 bl_b_31 bl_b_32 bl_b_33
+ bl_b_34 bl_b_35 bl_b_36 bl_b_37 bl_b_38 bl_b_39 bl_b_40 bl_b_41
+ bl_b_42 bl_b_43 bl_b_44 bl_b_45 bl_b_46 bl_b_47 bl_b_48 bl_b_49
+ bl_b_50 bl_b_51 bl_b_52 bl_b_53 bl_b_54 bl_b_55 bl_b_56 bl_b_57
+ bl_b_58 bl_b_59 bl_b_60 bl_b_61 bl_b_62 bl_b_63 bl_b_64 bl_b_65
+ bl_b_66 bl_b_67 bl_b_68 bl_b_69 bl_b_70 bl_b_71 bl_b_72 bl_b_73
+ bl_b_74 bl_b_75 bl_b_76 bl_b_77 bl_b_78 bl_b_79 bl_b_80 bl_b_81
+ bl_b_82 bl_b_83 bl_b_84 bl_b_85 bl_b_86 bl_b_87 bl_b_88 bl_b_89
+ bl_b_90 bl_b_91 bl_b_92 bl_b_93 bl_b_94 bl_b_95 bl_b_96 bl_b_97
+ bl_b_98 bl_b_99 bl_b_100 bl_b_101 bl_b_102 bl_b_103 bl_b_104 bl_b_105
+ bl_b_106 bl_b_107 bl_b_108 bl_b_109 bl_b_110 bl_b_111 bl_b_112
+ bl_b_113 bl_b_114 bl_b_115 bl_b_116 bl_b_117 bl_b_118 bl_b_119
+ bl_b_120 bl_b_121 bl_b_122 bl_b_123 bl_b_124 bl_b_125 bl_b_126
+ bl_b_127 bl_b_128 bl_b_129 bl_b_130 bl_b_131 bl_b_132 bl_b_133
+ bl_b_134 bl_b_135 bl_b_136 bl_b_137 bl_b_138 bl_b_139 bl_b_140
+ bl_b_141 bl_b_142 bl_b_143 bl_b_144 bl_b_145 bl_b_146 bl_b_147
+ bl_b_148 bl_b_149 bl_b_150 bl_b_151 bl_b_152 bl_b_153 bl_b_154
+ bl_b_155 bl_b_156 bl_b_157 bl_b_158 bl_b_159 bl_b_160 bl_b_161
+ bl_b_162 bl_b_163 bl_b_164 bl_b_165 bl_b_166 bl_b_167 bl_b_168
+ bl_b_169 bl_b_170 bl_b_171 bl_b_172 bl_b_173 bl_b_174 bl_b_175
+ bl_b_176 bl_b_177 bl_b_178 bl_b_179 bl_b_180 bl_b_181 bl_b_182
+ bl_b_183 bl_b_184 bl_b_185 bl_b_186 bl_b_187 bl_b_188 bl_b_189
+ bl_b_190 bl_b_191 bl_b_192 bl_b_193 bl_b_194 bl_b_195 bl_b_196
+ bl_b_197 bl_b_198 bl_b_199 bl_b_200 bl_b_201 bl_b_202 bl_b_203
+ bl_b_204 bl_b_205 bl_b_206 bl_b_207 bl_b_208 bl_b_209 bl_b_210
+ bl_b_211 bl_b_212 bl_b_213 bl_b_214 bl_b_215 bl_b_216 bl_b_217
+ bl_b_218 bl_b_219 bl_b_220 bl_b_221 bl_b_222 bl_b_223 bl_b_224
+ bl_b_225 bl_b_226 bl_b_227 bl_b_228 bl_b_229 bl_b_230 bl_b_231
+ bl_b_232 bl_b_233 bl_b_234 bl_b_235 bl_b_236 bl_b_237 bl_b_238
+ bl_b_239 bl_b_240 bl_b_241 bl_b_242 bl_b_243 bl_b_244 bl_b_245
+ bl_b_246 bl_b_247 bl_b_248 bl_b_249 bl_b_250 bl_b_251 bl_b_252
+ bl_b_253 bl_b_254 bl_b_255 word_sel_0 word_sel_1 word_sel_2 word_sel_3
+ word_sel_4 word_sel_5 word_sel_6 word_sel_7 rom_out_prebuf_0
+ rom_out_prebuf_1 rom_out_prebuf_2 rom_out_prebuf_3 rom_out_prebuf_4
+ rom_out_prebuf_5 rom_out_prebuf_6 rom_out_prebuf_7 rom_out_prebuf_8
+ rom_out_prebuf_9 rom_out_prebuf_10 rom_out_prebuf_11 rom_out_prebuf_12
+ rom_out_prebuf_13 rom_out_prebuf_14 rom_out_prebuf_15
+ rom_out_prebuf_16 rom_out_prebuf_17 rom_out_prebuf_18
+ rom_out_prebuf_19 rom_out_prebuf_20 rom_out_prebuf_21
+ rom_out_prebuf_22 rom_out_prebuf_23 rom_out_prebuf_24
+ rom_out_prebuf_25 rom_out_prebuf_26 rom_out_prebuf_27
+ rom_out_prebuf_28 rom_out_prebuf_29 rom_out_prebuf_30
+ rom_out_prebuf_31 vssd1
+ rom_256b_rom_column_mux_array
Xrom_column_decoder
+ addr0[0] addr0[1] addr0[2] word_sel_0 word_sel_1 word_sel_2 word_sel_3
+ word_sel_4 word_sel_5 word_sel_6 word_sel_7 precharge precharge vccd1
+ vssd1
+ rom_256b_rom_column_decode
Xrom_bitline_inverter
+ bl_0 bl_1 bl_2 bl_3 bl_4 bl_5 bl_6 bl_7 bl_8 bl_9 bl_10 bl_11 bl_12
+ bl_13 bl_14 bl_15 bl_16 bl_17 bl_18 bl_19 bl_20 bl_21 bl_22 bl_23
+ bl_24 bl_25 bl_26 bl_27 bl_28 bl_29 bl_30 bl_31 bl_32 bl_33 bl_34
+ bl_35 bl_36 bl_37 bl_38 bl_39 bl_40 bl_41 bl_42 bl_43 bl_44 bl_45
+ bl_46 bl_47 bl_48 bl_49 bl_50 bl_51 bl_52 bl_53 bl_54 bl_55 bl_56
+ bl_57 bl_58 bl_59 bl_60 bl_61 bl_62 bl_63 bl_64 bl_65 bl_66 bl_67
+ bl_68 bl_69 bl_70 bl_71 bl_72 bl_73 bl_74 bl_75 bl_76 bl_77 bl_78
+ bl_79 bl_80 bl_81 bl_82 bl_83 bl_84 bl_85 bl_86 bl_87 bl_88 bl_89
+ bl_90 bl_91 bl_92 bl_93 bl_94 bl_95 bl_96 bl_97 bl_98 bl_99 bl_100
+ bl_101 bl_102 bl_103 bl_104 bl_105 bl_106 bl_107 bl_108 bl_109 bl_110
+ bl_111 bl_112 bl_113 bl_114 bl_115 bl_116 bl_117 bl_118 bl_119 bl_120
+ bl_121 bl_122 bl_123 bl_124 bl_125 bl_126 bl_127 bl_128 bl_129 bl_130
+ bl_131 bl_132 bl_133 bl_134 bl_135 bl_136 bl_137 bl_138 bl_139 bl_140
+ bl_141 bl_142 bl_143 bl_144 bl_145 bl_146 bl_147 bl_148 bl_149 bl_150
+ bl_151 bl_152 bl_153 bl_154 bl_155 bl_156 bl_157 bl_158 bl_159 bl_160
+ bl_161 bl_162 bl_163 bl_164 bl_165 bl_166 bl_167 bl_168 bl_169 bl_170
+ bl_171 bl_172 bl_173 bl_174 bl_175 bl_176 bl_177 bl_178 bl_179 bl_180
+ bl_181 bl_182 bl_183 bl_184 bl_185 bl_186 bl_187 bl_188 bl_189 bl_190
+ bl_191 bl_192 bl_193 bl_194 bl_195 bl_196 bl_197 bl_198 bl_199 bl_200
+ bl_201 bl_202 bl_203 bl_204 bl_205 bl_206 bl_207 bl_208 bl_209 bl_210
+ bl_211 bl_212 bl_213 bl_214 bl_215 bl_216 bl_217 bl_218 bl_219 bl_220
+ bl_221 bl_222 bl_223 bl_224 bl_225 bl_226 bl_227 bl_228 bl_229 bl_230
+ bl_231 bl_232 bl_233 bl_234 bl_235 bl_236 bl_237 bl_238 bl_239 bl_240
+ bl_241 bl_242 bl_243 bl_244 bl_245 bl_246 bl_247 bl_248 bl_249 bl_250
+ bl_251 bl_252 bl_253 bl_254 bl_255 bl_b_0 bl_b_1 bl_b_2 bl_b_3 bl_b_4
+ bl_b_5 bl_b_6 bl_b_7 bl_b_8 bl_b_9 bl_b_10 bl_b_11 bl_b_12 bl_b_13
+ bl_b_14 bl_b_15 bl_b_16 bl_b_17 bl_b_18 bl_b_19 bl_b_20 bl_b_21
+ bl_b_22 bl_b_23 bl_b_24 bl_b_25 bl_b_26 bl_b_27 bl_b_28 bl_b_29
+ bl_b_30 bl_b_31 bl_b_32 bl_b_33 bl_b_34 bl_b_35 bl_b_36 bl_b_37
+ bl_b_38 bl_b_39 bl_b_40 bl_b_41 bl_b_42 bl_b_43 bl_b_44 bl_b_45
+ bl_b_46 bl_b_47 bl_b_48 bl_b_49 bl_b_50 bl_b_51 bl_b_52 bl_b_53
+ bl_b_54 bl_b_55 bl_b_56 bl_b_57 bl_b_58 bl_b_59 bl_b_60 bl_b_61
+ bl_b_62 bl_b_63 bl_b_64 bl_b_65 bl_b_66 bl_b_67 bl_b_68 bl_b_69
+ bl_b_70 bl_b_71 bl_b_72 bl_b_73 bl_b_74 bl_b_75 bl_b_76 bl_b_77
+ bl_b_78 bl_b_79 bl_b_80 bl_b_81 bl_b_82 bl_b_83 bl_b_84 bl_b_85
+ bl_b_86 bl_b_87 bl_b_88 bl_b_89 bl_b_90 bl_b_91 bl_b_92 bl_b_93
+ bl_b_94 bl_b_95 bl_b_96 bl_b_97 bl_b_98 bl_b_99 bl_b_100 bl_b_101
+ bl_b_102 bl_b_103 bl_b_104 bl_b_105 bl_b_106 bl_b_107 bl_b_108
+ bl_b_109 bl_b_110 bl_b_111 bl_b_112 bl_b_113 bl_b_114 bl_b_115
+ bl_b_116 bl_b_117 bl_b_118 bl_b_119 bl_b_120 bl_b_121 bl_b_122
+ bl_b_123 bl_b_124 bl_b_125 bl_b_126 bl_b_127 bl_b_128 bl_b_129
+ bl_b_130 bl_b_131 bl_b_132 bl_b_133 bl_b_134 bl_b_135 bl_b_136
+ bl_b_137 bl_b_138 bl_b_139 bl_b_140 bl_b_141 bl_b_142 bl_b_143
+ bl_b_144 bl_b_145 bl_b_146 bl_b_147 bl_b_148 bl_b_149 bl_b_150
+ bl_b_151 bl_b_152 bl_b_153 bl_b_154 bl_b_155 bl_b_156 bl_b_157
+ bl_b_158 bl_b_159 bl_b_160 bl_b_161 bl_b_162 bl_b_163 bl_b_164
+ bl_b_165 bl_b_166 bl_b_167 bl_b_168 bl_b_169 bl_b_170 bl_b_171
+ bl_b_172 bl_b_173 bl_b_174 bl_b_175 bl_b_176 bl_b_177 bl_b_178
+ bl_b_179 bl_b_180 bl_b_181 bl_b_182 bl_b_183 bl_b_184 bl_b_185
+ bl_b_186 bl_b_187 bl_b_188 bl_b_189 bl_b_190 bl_b_191 bl_b_192
+ bl_b_193 bl_b_194 bl_b_195 bl_b_196 bl_b_197 bl_b_198 bl_b_199
+ bl_b_200 bl_b_201 bl_b_202 bl_b_203 bl_b_204 bl_b_205 bl_b_206
+ bl_b_207 bl_b_208 bl_b_209 bl_b_210 bl_b_211 bl_b_212 bl_b_213
+ bl_b_214 bl_b_215 bl_b_216 bl_b_217 bl_b_218 bl_b_219 bl_b_220
+ bl_b_221 bl_b_222 bl_b_223 bl_b_224 bl_b_225 bl_b_226 bl_b_227
+ bl_b_228 bl_b_229 bl_b_230 bl_b_231 bl_b_232 bl_b_233 bl_b_234
+ bl_b_235 bl_b_236 bl_b_237 bl_b_238 bl_b_239 bl_b_240 bl_b_241
+ bl_b_242 bl_b_243 bl_b_244 bl_b_245 bl_b_246 bl_b_247 bl_b_248
+ bl_b_249 bl_b_250 bl_b_251 bl_b_252 bl_b_253 bl_b_254 bl_b_255 vccd1
+ vssd1
+ rom_256b_rom_bitline_inverter
Xrom_output_inverter
+ rom_out_prebuf_0 rom_out_prebuf_1 rom_out_prebuf_2 rom_out_prebuf_3
+ rom_out_prebuf_4 rom_out_prebuf_5 rom_out_prebuf_6 rom_out_prebuf_7
+ rom_out_prebuf_8 rom_out_prebuf_9 rom_out_prebuf_10 rom_out_prebuf_11
+ rom_out_prebuf_12 rom_out_prebuf_13 rom_out_prebuf_14
+ rom_out_prebuf_15 rom_out_prebuf_16 rom_out_prebuf_17
+ rom_out_prebuf_18 rom_out_prebuf_19 rom_out_prebuf_20
+ rom_out_prebuf_21 rom_out_prebuf_22 rom_out_prebuf_23
+ rom_out_prebuf_24 rom_out_prebuf_25 rom_out_prebuf_26
+ rom_out_prebuf_27 rom_out_prebuf_28 rom_out_prebuf_29
+ rom_out_prebuf_30 rom_out_prebuf_31 dout0[0] dout0[1] dout0[2]
+ dout0[3] dout0[4] dout0[5] dout0[6] dout0[7] dout0[8] dout0[9]
+ dout0[10] dout0[11] dout0[12] dout0[13] dout0[14] dout0[15] dout0[16]
+ dout0[17] dout0[18] dout0[19] dout0[20] dout0[21] dout0[22] dout0[23]
+ dout0[24] dout0[25] dout0[26] dout0[27] dout0[28] dout0[29] dout0[30]
+ dout0[31] vccd1 vssd1
+ rom_256b_rom_output_buffer
.ENDS rom_256b
