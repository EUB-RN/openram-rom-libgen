# Using your own ROM

What the flow needs from a macro directory, what the `.lib` says about power and ground, and how the output is validated.

[<- back to the README](../README.md)

---

## Using your own ROM

There are two ways in, and they differ only in where the macro lives:

* **`user/` + `./flow.py <macro>`** -- drop the macro under `user/`, and one
  command runs pre-flight, the simulations, both generators and the tests.
  This is what `shell.nix` sets up; see [`user/README.md`](../user/README.md).
  Standard mode (`./flow.py <macro>`) provides a conservative library in tens
  of minutes with declared timing fallbacks for address hold and clock slew.
  Full mode (`./flow.py <macro> --full`) runs all measurements including the
  6d group (`run_wl_slew.sh`, `run_hold_bisect.sh`, `run_addr2wl.sh`,
  `run_slew_sweep.sh`), eliminating timing fallbacks.
* **`ROM_MACROS_DIR` + the `run_*.sh` scripts** -- the step-by-step flow this
  page and [flow.md](flow.md) describe. Use it when you want to inspect or
  repeat one measurement; standard/full production runs should use `flow.py`.

Either way a macro directory is expected to look like an OpenRAM ROM output:

```
<macro>/
  <macro>.sp            netlist          (required -- geometry comes from here)
  <macro>.lef           pins + area      (required -- pin list for the .lib)
  <macro>.gds           layout           (needed for parasitic extraction)
  mags/                 base cell layouts (optional -- falls back to repo mags/)
  config/<macro>.py     word_size, words_per_row (optional, cross-check)
  or <macro>.py         (optional, same config at macro root)
  rom_configs/<macro>.bin                (optional, word count for the model)
  char/                 generated decks and logs (created for you)
```

Check it before running anything:

```
$ python3 scripts/rom_char/rom_paths.py --check wrom0
macro directory : /path/to/examples/wrom0

files:
  ok      wrom0.sp                     schematic netlist -- geometry, worst column
  ok      wrom0.lef                    LEF -- pin list, bus widths and area for the .lib
  ok      wrom0.gds                    GDS -- needed by run_cap_extract.sh
  ...
sub-circuits expected by the flow:
  ok      wrom0_rom_base_array               cell array (geometry, worst column)
  ok      wrom0_rom_base_one_cell            cell with a real NMOS (series chain)
  ...
All good -- this macro can go through the flow.
```

The sub-circuit names it looks for are the ones OpenRAM's `rom_compiler`
emits:

```
<macro>_rom_base_array        <macro>_rom_control_logic
<macro>_rom_base_one_cell     <macro>_rom_row_decode
<macro>_rom_base_zero_cell    <macro>_rom_bitline_inverter
<macro>_precharge_cell        <macro>_rom_column_mux_array
                              <macro>_rom_output_buffer
```

If your macro does not supply local `.mag` files for `rom_base_one_cell`,
`rom_base_zero_cell`, `precharge_cell`, or
`sky130_fd_bd_sram__openram_sp_nand2_dec`, the flow automatically resolves them
from the shared `mags/` directory (or falls back to calibrated Sky130 generic
baselines).

If your ROM has the same architecture under different names, adjust those names
in the generators. If it is a **different architecture** -- NOR ROM, latched
output, differential read -- the decks themselves need rethinking: they encode
the precharged-NAND behaviour described above.

## Power and ground in the `.lib`

The library declares its rails and then actually points at them:

```
voltage_map ( VCCD1, 1.80 )      rail name -> voltage
  pg_pin(vccd1) voltage_name : VCCD1;       pin -> rail
    related_power_pin : vccd1;              signal pin -> pg_pin
    related_pg_pin    : vccd1;              internal_power / leakage -> pg_pin
```

All four links have to exist for a multi-voltage power tool to walk from a
signal pin to its supply. Declaring `voltage_map` and never referencing it is not an error anywhere in
the toolchain: the analysis just comes out unattributed.
`tests/lib_tests/check_lib.py` now refuses a reference that does not resolve,
and `tests/lib_tests/test_rom_lib.py` refuses a pin that carries none.

The pin names are read from the LEF (`USE POWER` / `USE GROUND`) rather than
being fixed to `vccd1`/`vssd1`, which would name nets a differently-built
macro does not have. The first power/ground pin in
the LEF becomes the primary rail and any others are written as backup rails.

## Validating the output

Without a reader of its own, a syntax error or a table with the wrong number
of rows only surfaces in someone else's tool. `tests/` closes that:

```sh
tests/run_tests.sh
```

Three suites run eleven checks: script/SPICE helpers, error/provenance handling,
flow resume, dynamic periphery settling, paired periphery leakage, the checker's 15 deliberately broken Liberty fixtures, generic
Liberty structure, ROM semantics, OpenSTA parsing, SystemVerilog elaboration,
and dynamic behavioural simulation. The last group asserts precharge, access
delay, falling-edge invalidation, cs0 gating and hold behaviour. Every skipped
external-tool check is named in the closing banner; strict mode turns skips
into failures.
`regen_rom_libs.sh` runs the structural pass by itself at the end of every run,
so a file that does not parse never leaves the generator. Details in
[`tests/README.md`](../tests/README.md). Deliverables land in `output/lib/` and
`output/verilog/`. Note that characterization validation does not replace physical
DRC/LVS sign-off.

## `examples/`

`wrom0`..`wrom3`: four ROM macros built on sky130 (1064 words x 32 bit, 134
rows x 256 columns) with all of their characterization logs. Use them to study
the flow without ngspice, or to check a change end to end -- regenerate and
compare against what is committed in `output/`:

```sh
./scripts/rom_char/regen_rom_libs.sh && git diff --stat output/
```
