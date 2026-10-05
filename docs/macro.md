# ROM Circuit Architecture & Macro Details

This document describes the seven top-level blocks in the OpenRAM series-NAND
ROM and the read path through them.

[<- back to the README](../README.md)

---

## 1. Top-Level Macro Architecture & Signal Flow

The OpenRAM ROM compiler emits a dynamic, unlatched **series-NAND architecture**. Total macro access delay is determined by the staged propagation through seven interconnected sub-blocks.

![Macro Floorplan](img/01-macro-floorplan.png)

### Signal Progression
1. **Control (`rom_control_logic`)**: Ingests `clk0` and `cs0` to generate internal clocking and the global active-low `precharge` distribution rail.
2. **Row Decode (`rom_row_decode`)**: Decodes upper address bits (`addr0[10:3]`) to assert one of the wordlines (`wl[133:0]`).
3. **Core Array (`rom_base_array`)**: The selected wordline enables the series-NAND pull-down stack, conditionally discharging the dynamic bitlines (`bl[255:0]`).
4. **Bitline Inverter (`rom_bitline_inverter`)**: Senses bitline discharge, isolates array capacitance, and generates inverted bitlines (`bl_b[255:0]`).
5. **Column Decode (`rom_column_decode`)**: Decodes lower address bits (`addr0[2:0]`) into 8-way mux select lines (`word_sel[7:0]`).
6. **Column Multiplexer (`rom_column_mux_array`)**: Multiplexes 256 bitlines down to 32 pre-buffer lines (`rom_out_prebuf[31:0]`).
7. **Output Driver (`rom_output_buffer`)**: Buffers and re-inverts the data to drive external capacitive loads on `dout0[31:0]`.

---

## 2. Block 1: `rom_control_logic`

Generates synchronous evaluate timing and global precharge control from `clk0` and chip-select `cs0`.

### Circuit Structure & Operation
1. **Clock Buffer (`rom_clock_driver`):**
   * Two cascaded CMOS inverter stages (`pinv` -> `pinv_0` -> `pinv_1` / `pinv_2`) that buffer external `clk0` to produce internal clock net `clk_int`.
   * Isolates external clock loading from internal distribution capacitance.
2. **Control NAND (`rom_control_nand`):**
   * A 2-input CMOS NAND gate (`A=clk_int`, `B=cs0`).
   * When `cs0=0` (chip disabled), the NAND output stays continuously HIGH, keeping precharge asserted (bitlines held precharged, evaluate never triggers).
   * When `cs0=1` (chip selected) and `clk_int` rises HIGH, the NAND output falls to 0V.
3. **Precharge Driver (`rom_precharge_driver`):**
   * High-fanout inverter driver chain (`pinv_5`, `pinv_6`, `pinv_7`) driving the heavily loaded global `precharge` distribution rail across the macro.
   * `precharge` is **active-low (0V)** during the precharge phase (`clk0=0`).
   * During the evaluate phase (`clk0=1`, `cs0=1`), `precharge` rises to **VDD (1.8V)**.

---

## 3. Block 2: `rom_row_decode`

Decodes the upper 8 address bits (`addr0[10:3]`) to select exactly 1 out of 134 wordlines.

### Circuit Structure & Operation
1. **Address Input Buffers (`rom_address_control_array`):**
   * For each address bit, uses `rom_address_control_buf` (`inv_array_mod` inverters) to produce non-inverted and complementary address rails (`A_out` and `Abar_out`).
   * Gates address propagation using internal clock `clk_int`.
2. **Precharge Array (`rom_precharge_array_0`):**
   * PMOS pull-up transistors connected to each internal decode line, pulling all decode rows to VDD during precharge.
3. **Dynamic Decode Matrix (`rom_row_decode_array`):**
   * Multi-input dynamic NAND lines constructed from `rom_base_one_cell` and `rom_base_zero_cell` instances.
   * For a given row, NMOS transistors are placed on the address bits that correspond to its binary index.
   * When all matching address inputs are HIGH, the series NMOS stack pulls down, discharging that specific decode line to 0V. All unselected rows remain floating or held at VDD.
4. **Wordline Driver Buffers (`rom_row_decode_wordline_buffer`):**
   * CMOS inverter stages (`pinv_dec_0`, `pinv_dec_1`) driving horizontal wordlines across all 256 array columns.
   * Inverts the discharged decode line: **The selected row's wordline falls to LOW (0V)**.
   * All 133 unselected wordlines remain held at **HIGH (VDD)**.

Unlike the data-dependent storage array, decoder rows have equal logical stack
depth. Physical routing can still vary by row. `run_addr2wl.sh` measures the
row 0 to row 1 transition used in the hold conversion; it does not sweep every
row. That coverage limit is recorded in [limitations.md](limitations.md).

---

## 4. Block 3: `rom_base_array`

The core memory array (134 rows x 256 columns in `wrom0`). Each column forms a single continuous series-NAND pull-down chain.

![rom_base_array Overview](img/02-array-overview.png)

### Storage Cell Topologies: Mask-Programmed Transistors vs Straps
Every bit in the array is physically manufactured with an NMOS transistor; the ROM mask pattern dictates whether its drain and source are shorted:

| `rom_base_one_cell` (Logic 1) | `rom_base_zero_cell` (Logic 0) |
|---|---|
| ![one_cell layout](img/03a-one-cell.png) | ![zero_cell layout](img/03b-zero-cell.png) |
| Active NMOS (`W=0.36u, L=0.15u`). Gate connected to wordline `wl`. | Drain and Source shorted directly via Metal-1 strap ($R_{strap} \approx 0.24\ \Omega$). |
| When selected `wl` falls LOW $\rightarrow$ NMOS turns OFF $\rightarrow$ chain broken $\rightarrow$ **bitline stays HIGH (1)**. | Wordline state ignored $\rightarrow$ strap conducts $\rightarrow$ chain closed $\rightarrow$ **bitline discharges to 0V (0)**. |

![Single Column Strip](img/example_one_col.png)

### Precharge & Foot Architecture
* **Precharge PMOS (`precharge_cell`):** Sits at the top of each bitline (`W=0.42u, L=0.15u`). When `precharge` is LOW, charges the bitline node to VDD.
* **Foot NMOS:** Sits at the bottom of the column series chain, gated by `precharge`. Cuts the chain from GND during precharge (preventing static VDD-to-GND current) and connects the chain to ground during evaluate.
* **Internal Node Voltage Gradient:** Internal nodes along the NAND chain do not reach full VDD due to $V_{th}$ threshold drops across successive NMOS pass transistors. Saturated settling requires multiple clock cycles to stabilize before measurement.

---

## 5. Block 4: `rom_column_decode`

Decodes the lowest 3 address bits (`addr0[2:0]`) to select 1 out of 8 column multiplexer groups ($2^3 = 8$).

### Circuit Structure & Operation
1. **Address Buffers (`rom_address_control_array_0`):**
   * Buffers `addr0[0]`, `addr0[1]`, `addr0[2]` into true and complement rail pairs.
2. **Column Decode Matrix (`rom_column_decode_array`):**
   * An 8-line dynamic decode NAND array matching the 3-bit binary addresses (`000` through `111`).
3. **Select Line Drivers (`rom_column_decode_wordline_buffer`):**
   * Inverter driver stages (`pinv_dec_2`) driving lines `word_sel_0` to `word_sel_7`.
   * Exactly one `word_sel[k]` line transitions **HIGH (VDD)** during evaluate; all other 7 lines remain **LOW (0V)**.
   * Races bitline discharge: The select signal arrives at the multiplexer gates 23–35x faster than the bitline discharges through 50%, ensuring multiplexer selection is already established before data propagates.

The column decoder is dynamic. Changing `addr0[2:0]` during evaluate can leave
multiple select paths active because precharge is unavailable to restore the
previous decoder state. The address therefore remains covered by the measured
hold constraint until data has cleared the back end.

---

## 6. Block 5: `rom_column_mux_array`

Multiplexes 256 physical bitline columns into 32 data channels (an 8:1 multiplexer per output bit).

### Circuit Structure & Operation
* **Multiplexer Unit (`rom_column_mux`):**
  * Built using wide NMOS pass-transistors (`W=2.88u, L=0.15u`) to minimize on-resistance ($R_{on}$) and speed up signal transfer.
* **Bus Interleaving:**
  * Bitlines are interleaved across 32 multiplexers:
    $$\text{Data Bit } j \text{ selects from bitlines } \{j, 32+j, 64+j, \dots, 224+j\} \text{ for } j \in [0, 31]$$
  * When `word_sel[k]` is active HIGH, each multiplexer routes its $k$-th input bitline to internal pre-buffer node `rom_out_prebuf[j]`.

---

## 7. Block 6: `rom_bitline_inverter`

Dynamic node isolation and sensing stage placed between the bitlines and the column multiplexers.

### Circuit Structure & Operation
* Contains 256 individual CMOS inverters (`pinv_dec_3`).
* **Isolation Function:** Isolates the high-capacitance dynamic bitline node (`bl_0`..`bl_255`) from the pass-transistor multiplexer switches and downstream routing capacitance.
* **Signal Polarity:**
  * When bitline is HIGH (reading '1'), `rom_bitline_inverter` output `bl_b` is **LOW (0V)**.
  * When bitline discharges to 0V (reading '0'), `rom_bitline_inverter` output `bl_b` transitions **HIGH (VDD)**.

---

## 8. Block 7: `rom_output_buffer`

Final output drive stage buffering the 32 read signals and driving external output pins (`dout0[31:0]`).

### Circuit Structure & Operation
* Contains 32 tapered CMOS inverter stages (`pinv_dec_4`).
* **Drive Capability:** Designed with scaled transistor geometries to drive external board loads (characterized in Liberty tables across 689 fF, 2756 fF, and 17225 fF load points).
* **Final Inversion:** Inverts `rom_out_prebuf[31:0]` to produce external data `dout0[31:0]`, completing the true-value logic restoration:
  * Reading Logic 1: `bl` HIGH $\rightarrow$ `bl_b` LOW $\rightarrow$ `rom_out_prebuf` LOW $\rightarrow$ **`dout0` HIGH (1)**.
  * Reading Logic 0: `bl` LOW $\rightarrow$ `bl_b` HIGH $\rightarrow$ `rom_out_prebuf` HIGH $\rightarrow$ **`dout0` LOW (0)**.

---

## 9. End-to-End Read Operation Walkthrough

```text
========================================================================================
1. Precharge Phase (clk0 = 0):
   - clk0 is LOW -> rom_control_logic holds precharge net at 0V.
   - Precharge PMOS turns ON -> all 256 bitlines (bl_0..bl_255) charged to VDD.
   - Foot NMOS is OFF -> column chains isolated from ground.
   - rom_bitline_inverter drives bl_b to 0V.

2. Evaluate Phase Initiated (clk0 = 1, cs0 = 1):
   - clk0 rises -> precharge net rises to VDD.
   - Precharge PMOS turns OFF -> bitlines float dynamically at VDD.
   - Foot NMOS turns ON -> bottom of all 256 column chains grounded.

3. Address Decoding:
   - Row Decoder: Selected wordline falls from VDD to 0V (t_clk2wl).
   - Column Decoder: Selected word_sel line rises from 0V to VDD (t_pre2sel).

4. Bitline Evaluation:
   - If selected cell is one_cell (NMOS):
     Gate falls to 0V -> NMOS opens -> chain broken -> bl stays at VDD.
   - If selected cell is zero_cell (Strap):
     Strap conducts -> entire chain closed to GND -> bl discharges to 0V.

5. Sense & Output Propagation:
   - Bitline inverter senses bl level -> drives bl_b.
   - Column multiplexer routes bl_b to rom_out_prebuf.
   - Output buffer inverts and drives dout0[31:0] pins.
========================================================================================
```
