# TODOs / Roadmap: Modeling & Optimization Improvements

This document tracks planned architectural improvements, simulation performance optimizations, and future enhancements for the OpenRAM ROM characterization flow (`openram-rom-libgen`).

For current known simulation, extraction, and modeling limitations, see [Known Limitations](limitations.md).

[<- back to the README](../README.md)

---

## 1. Row Decoder Slicing & Periphery Deck Reduction

*Target:* Make large ROM macro characterization (512, 1024, 2048+ rows) computationally tractable in ngspice by eliminating the unreduced decoder simulation bottleneck ([limitations.md item 13](limitations.md)).

- [ ] **Single Worst-Case Decode NAND Slice Extraction:**
  - Instead of preserving the entire multi-thousand device `rom_row_decode_array`, extract only the single worst-case decode NAND discharge path (the row with the maximum number of series `one_cell` NMOS transistors and longest interconnect path).
  - Replace inactive decoder rows with equivalent lumped parasitic capacitance on the internal clock and address buffer distribution rails.
- [ ] **Interfaced Wordline Driver Loading:**
  - Drive the corresponding `rom_row_decode_wordline_buffer` from the isolated slice.
  - Load the buffer output with lumped parasitic wire and gate capacitance of the row (matching current `arr_inst` load restoration).
  - Benchmark periphery deck simulation runtime on 512-row and 1024-row ROMs to verify speedup (target: hours down to seconds) without loss of delay measurement fidelity.

---

## 2. Row Decode Array Parasitic Resistance Injection

*Target:* Close the interconnect/wire resistance modeling gap in the row decoder path ([limitations.md item 3](limitations.md)).

- [ ] **Decoder Slice Wire Resistance Modeling:**
  - Adapt [`gen_resistance_model.py`](../scripts/rom_char/gen_resistance_model.py) cell series wire resistance values (`one_cell`: ~505 $\Omega$, `zero_cell`: ~0.24 $\Omega$) for the row decode array.
  - Inject synthetic resistors (`Rw...`, `Rstrap...`) into the extracted single decode NAND slice in [`gen_periphery_power_tb.py`](../scripts/rom_char/gen_periphery_power_tb.py) and [`gen_addr2wl_tb.py`](../scripts/rom_char/gen_addr2wl_tb.py).
- [ ] **Timing Arc & Wordline Slew Validation:**
  - Verify impact on wordline trigger delays ($t_{wlfall}$, $t_{wlslew}$) and address setup/hold margins under full BSIM4 channel + interconnect parasitic modeling.
  - Validate against baseline characterization on small reference macros (`rom_1k`, `wrom0`).

---

## 3. Characterization & Verification Enhancements

- [ ] **Multi-Corner Slew Sweep Unification:**
  - Streamline `run_slew_sweep.sh` across all PVT corners (TT, SS, FF) with automated Liberty table interpolation and validation.
- [ ] **Automated Slicing Equivalence Regression:**
  - Add regression checks comparing sliced decoder timing against full-macro SPICE on small test macros (e.g. 16–32 rows) to mathematically bound slicing error.
