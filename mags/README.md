# Shared Magic cell layouts

This directory holds small, reusable sky130 Magic (`.mag`) layouts used by the
characterization support scripts when a macro does not carry its own copy of a
generic cell layout.

`scripts/rom_char/gen_resistance_model.py` searches the macro's `mags/`
directory and macro root first, then this shared directory. The ROM base cells
and precharge cell provide geometry for extracting or analytically estimating
series resistance and wordline pitch. The NAND decoder cell is kept here as a
shared layout reference for the decoder path.

Current files:

- `rom_base_one_cell.mag`: series-NMOS ROM cell geometry.
- `rom_base_zero_cell.mag`: metal-strapped zero-cell geometry.
- `precharge_cell.mag`: bitline precharge PMOS cell geometry.
- `sky130_fd_bd_sram__openram_sp_nand2_dec.mag`: OpenRAM decoder NAND layout.

These files are model inputs and reusable references, not generated Liberty or
simulation deliverables. Using a shared cell assumes its layout is genuinely
identical to the corresponding cell in the target macro. The resistance-model
JSON records whether a value came from Magic, an analytic estimate, or a
generic baseline; a baseline fallback must not be presented as a macro-specific
physical extraction without separate correlation. DRC/LVS of the complete
macro remains a separate requirement.
