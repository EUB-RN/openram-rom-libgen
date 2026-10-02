# TODOs / Roadmap: Modeling & Optimization Improvements

This document tracks planned architectural improvements, simulation performance optimizations, and cell parasitic resistance modeling in the OpenRAM ROM characterization flow (`openram-rom-libgen`).

---

## 1. Row Decode Array Parasitic Resistance Modeling

### Background & Physical Nature of Cell Resistance
In the ROM array and decoder architectures, cells such as `rom_base_one_cell` and `rom_base_zero_cell` exhibit two fundamentally different types of resistance:

1. **MOSFET Channel Resistance ($R_{channel}$ / $R_{on}$):**
   * The saturated and linear-region channel resistance of the NMOS transistor is on the order of tens of kilohms ($\sim 15\text{--}30\text{ k}\Omega$).
   * This non-linear switching resistance is naturally handled and accurately computed by ngspice using the Sky130 BSIM4 device model (`sky130_fd_pr__special_nfet_01v8`).

2. **Interconnect & Parasitic Layer Resistance (Wire Resistance):**
   * These resistances are **strictly wire/interconnect resistances, EXCLUDING the transistor channel**:
     * **`one_cell (~505 Ω)`:** The parasitic series resistance along the path from external ports (Source/Drain) to the boundary of the active channel:
       $$\text{Port D} \xrightarrow{\text{Metal1 + Li + Contact + N-Diff}} \text{Channel} \xrightarrow{\text{Channel}} \text{Channel} \xrightarrow{\text{N-Diff + Contact + Li + Metal1}} \text{Port S}$$
       In Sky130A, the N-diffusion layer (`ndiff`) has a high sheet resistance ($\sim 120\ \Omega/\Box$). Combined with local interconnect (`li`), contacts, and metal1, this contributes $\sim 505\ \Omega$ of series parasitic resistance per cell.
     * **`zero_cell (~0.24 Ω)`:** A logic '0' cell has its Source and Drain shorted directly via a Metal-1 strap. With Sky130A Metal-1 sheet resistance at $0.125\ \Omega/\Box$ and a geometry of $\approx 1.9$ squares:
       $$R_{\text{strap}} \approx 1.9 \times 0.125\ \Omega \approx 0.24\ \Omega$$
       This is a pure metallic interconnect resistance.

### Current Implementation Gap
* **Full-Macro Magic Segfault:** Magic 8.3 crashes with a segmentation fault when running full-macro resistance extraction (`extresist all` / `ext2spice extresist on`) on large ROM arrays due to size and degenerate topologies (e.g. shorted `zero_cell`s). Therefore, macro extraction is strictly capacitance-only (`run_cap_extract.sh`).
* **Bitline Array:** The series wire resistance is modeled on single cells via [`gen_resistance_model.py`](../scripts/rom_char/gen_resistance_model.py) and injected as synthetic resistors (`Rw...`, `Rstrap...`) in the bitline discharge deck ([`gen_col_tb_parasitic.py`](../scripts/rom_char/gen_col_tb_parasitic.py)).
* **Row Decode Array (Gap):** The periphery deck ([`gen_periphery_power_tb.py`](../scripts/rom_char/gen_periphery_power_tb.py)) uses `*_cap_only.spice` directly. While the transistor BSIM4 channel resistance and parasitic capacitances are present, the series wire resistance (~505 $\Omega$ / ~0.24 $\Omega$) is **currently not injected** into the decoder array instances.

---

## 2. Row Decoder Simulation Bottleneck on Large ROM Macros

### The Problem
* In [`gen_periphery_power_tb.py`](../scripts/rom_char/gen_periphery_power_tb.py), the bitline array (`rom_base_array`) is deleted and replaced with lumped RC loading, but the row decoder (`rom_row_decode`) is kept **entirely intact** (`KEEP_SUB = {..., rom_row_decode}`).
* On small to medium ROMs (e.g. 1k–4kbit, 64–128 rows), this completes in reasonable time (3–6 minutes).
* On **large ROMs** (e.g. 8k, 16k, 32k, 64k words with 512, 1024, or 2048 rows):
  * The row decode array scales linearly with the number of rows.
  * For example, a 1024-row ROM with 10 address bits contains **over 10,240 cell instances** in `rom_row_decode_array` alone.
  * Simulating thousands of unreduced dynamic NAND transistors in ngspice causes simulation runtimes to balloon into hours, drives up peak memory consumption, and introduces timestep convergence issues.

---

## 3. Planned Solution: Decoder Slicing & Resistance Modeling (Similar to Bitline Flow)

To make large ROM characterization tractable while simultaneously accounting for the missing wire resistance, a reduction approach analogous to the bitline column flow should be implemented:

### Implementation Plan

1. **Worst-Case Single Decode NAND Slice Extraction:**
   * Instead of preserving the entire multi-thousand device `rom_row_decode_array`, extract only the single **worst-case decode NAND discharge path** (the row with the maximum number of series `one_cell` NMOS transistors and longest interconnect).
   * Replace the inactive rows with equivalent lumped capacitance on the internal clock and address buffer distribution rails.

2. **Series Wire Resistance Injection:**
   * Inject the per-cell wire resistance model from [`gen_resistance_model.py`](../scripts/rom_char/gen_resistance_model.py) (`one_cell`: ~505 $\Omega$, `zero_cell`: ~0.24 $\Omega$) directly into this isolated decode NAND slice.
   * This concurrently solves the missing interconnect resistance in the decoder path and provides bounded, accurate wordline trigger delays ($t_{wlfall}$, $t_{wlslew}$).

3. **Interfaced Wordline Driver Loading:**
   * Drive the corresponding `rom_row_decode_wordline_buffer` from this single slice and load its output with the lumped parasitic wire capacitance and gate capacitance of the row (identical to the current `arr_inst` load restoration).
   * This cuts ngspice simulation time for large ROMs from hours to seconds while maintaining high fidelity.
