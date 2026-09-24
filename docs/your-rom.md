# Using your own ROM

What the flow needs from a macro directory, what the `.lib` says about power and ground, and how the output is validated.

[<- back to the README](../README.md)

---

## Using your own ROM

There are two ways in, and they differ only in where the macro lives:

* **`user/` + `./flow.py <macro>`** -- drop the macro under `user/`, and one
  command runs pre-flight, the simulations, both generators and the tests.
  This is what `shell.nix` sets up; see [`user/README.md`](../user/README.md).
  It leaves the optional measurements of step 6d out (see
  [flow.md](flow.md)), so its library is conservative rather than complete.
* **`ROM_MACROS_DIR` + the `run_*.sh` scripts** -- the step-by-step flow this
  page and [flow.md](flow.md) describe. Use it when you want a single
  measurement, or the optional ones `flow.py` skips.

Either way a macro directory is expected to look like an OpenRAM ROM output:

```
<macro>/
  <macro>.sp            netlist          (required -- geometry comes from here)
  <macro>.lef           pins + area      (required -- pin list for the .lib)
  <macro>.gds           layout           (needed for parasitic extraction)
  config/<macro>.py     word_size, words_per_row   (optional, cross-check)
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
the toolchain: the analysis just comes out unattributed. `tests/check_lib.py` now refuses a reference that
does not resolve, and `tests/test_rom_lib.py` refuses a pin that carries none.

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

Six layers: the checker's own fixtures (15 deliberately broken Liberty files,
so a green run means something), the generic Liberty structure, the ROM
semantics (both `dout0` arcs, the constraints, both power states, FF < TT < SS
ordering), OpenSTA's own `read_liberty` where it is installed, and two that
compile and then simulate the generated behavioural Verilog. Each layer that
could not run is named in the closing banner, so a green run never means more
than it did.
`regen_rom_libs.sh` runs the structural pass by itself at the end of every run,
so a file that does not parse never leaves the generator. Details in
[`tests/README.md`](../tests/README.md).

## `examples/`

`wrom0`..`wrom3`: four ROM macros built on sky130 (1064 words x 32 bit, 134
rows x 256 columns) with all of their characterization logs. Use them to study
the flow without ngspice, or to check a change end to end -- regenerate and
compare against what is committed in `output/`:

```sh
./scripts/rom_char/regen_rom_libs.sh && git diff --stat output/
```
