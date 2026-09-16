#!/usr/bin/env python3
"""
Generate a Liberty (.lib) timing model for an OpenRAM ROM macro.

WHY: OpenRAM's characterizer only writes a .lib for SRAM. The ROM compiler
(rom_compiler) emits just .sp/.v/.lef/.gds. This script builds the .lib that
synthesis and STA need, from the pin/area information in the LEF plus the
timing/power numbers given on the command line.

Macro structure (from the netlist): a classic precharged ROM with NO LATCH:
    clk_out  = clock_driver(clk0)          (inverter chain, non-inverting)
    prechrg  = ~NAND(cs0, clk_out) = cs0 & clk0
    precharge_cell = PMOS, gate = prechrg  -> precharges while prechrg=0
    address buffer: A_out = NAND(clk_out, ~A)  -> decoding only while clk=1
    dout0 = two inverters (bitline_inverter + output_buffer)
Therefore:
    clk0 = 0 -> the bitlines are precharged to VDD, dout0 is all ones
    clk0 = 1 -> the decoder opens, selected cells discharge their bitline
    dout0 is valid ONLY during clk0's high phase.
access = time from clk0's rising edge until dout0 is valid
         (decode + wordline + bitline discharge + buffers).

CAREFUL -- the BASE table below is only a DEFAULT and an analytic guess. The
sign-off flow does NOT use those values: regen_rom_libs.sh reads every term out
of an ngspice log and passes them here with --measured. Under --measured the
derating factors in the CORNERS table are not applied either (the value already
belongs to that corner; multiplying would double count).

Kullanim:
    # normal flow (all values measured, called by the top-level script):
    scripts/rom_char/regen_rom_libs.sh

    # a single macro, by hand:
    python3 scripts/rom_char/gen_rom_lib.py --macro wrom0 --memory-type rom
    python3 scripts/rom_char/gen_rom_lib.py --lef path/x.lef --corner TT_1p8V_25C
    python3 scripts/rom_char/gen_rom_lib.py --macro wrom0 --access 2.4 --hold 2.4
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from collections import OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rom_paths                                        # noqa: E402

# Without --lef the FIRST macro in the tree is used; this used to be a
# hard-coded "rom_17kbyte", which silently produced the wrong pin list for any
# other macro.
_found = rom_paths.discover()
DEFAULT_LEF = rom_paths.lef(_found[0]) if _found else None

# ---------------------------------------------------------------------------
# Timing knobs (ns / mW). TT is the base, the others are derating factors.
# ---------------------------------------------------------------------------
# access  : clk0 rising edge -> dout0 valid (at the smallest load)
# t_pre   : bitline precharge time -> clk0's low phase must be at least this
# setup   : addr0/cs0 must be stable this long before clk0 rises
# hold    : addr0/cs0 must stay stable this long after clk0 rises
#           (the address cannot change during evaluate -> ~access)
BASE = {
    "access": 3.00,
    "t_pre": 2.80,
    "setup": 0.15,
    "hold": 3.00,
    "leakage_mw": 0.050,
}

# name -> (process, voltage, temperature, delay factor, constraint factor)
CORNERS = OrderedDict([
    ("TT_1p8V_25C", (1.0, 1.80, 25, 1.00, 1.00)),
    ("SS_1p6V_100C", (1.0, 1.60, 100, 1.85, 1.50)),
    ("FF_1p95V_n40C", (1.0, 1.95, -40, 0.65, 0.70)),
])

# Load/slew tables -- the same indices as OpenRAM's SRAM libs (pF, ns)
CAP_INDEX = [0.0017224999999999999, 0.006889999999999999, 0.027559999999999998]
SLEW_INDEX = [0.00125, 0.005, 0.04]
# Output driver pinv_dec_4 (wp=5.0 wn=1.68); the load sensitivity was taken
# from an OpenRAM SRAM lib using the same class of driver.
# NOTE: these are fallbacks only -- with --backend-ns/--out-slew-ns the
# measured numbers are used instead.
LOAD_DELTA = [0.000, 0.029, 0.145]
OUT_SLEW = [0.002, 0.005, 0.016]

# Input pin capacitances -- estimated from gate widths in the netlist (pF).
# These are ANALYTIC, not measured; they are the one part of the .lib that
# still comes from a hand calculation.
#   clk0 -> first inverter of the clock driver (pinv: wp=1.12 wn=0.36 um)
#   cs0  -> control_nand input                 (wp=1.12 wn=0.74 um)
#   addr -> inv_array_mod input                (wp=3.00 wn=0.74 um)
PIN_CAP = {"clk0": 0.0025, "cs0": 0.0030, "_default": 0.0060}
MAX_CAP = 0.027559999999999998
MIN_CAP = 0.0017224999999999999
MAX_TRANSITION = 0.04


def parse_lef(path):
    """Extract macro name, size and pin list (directions kept) from the LEF."""
    with open(path) as fh:
        text = fh.read()

    m = re.search(r"^\s*MACRO\s+(\S+)", text, re.M)
    if not m:
        sys.exit("no MACRO found in the LEF: %s" % path)
    name = m.group(1)

    m = re.search(r"^\s*SIZE\s+([\d.]+)\s+BY\s+([\d.]+)\s*;", text, re.M)
    if not m:
        sys.exit("no SIZE found in the LEF: %s" % path)
    width, height = float(m.group(1)), float(m.group(2))

    pins = OrderedDict()
    pat = re.compile(r"^\s*PIN\s+(\S+)(.*?)^\s*END\s+\1\s*$", re.M | re.S)
    for pm in pat.finditer(text):
        pname, body = pm.group(1), pm.group(2)
        dm = re.search(r"DIRECTION\s+(\w+)", body)
        um = re.search(r"USE\s+(\w+)", body)
        pins[pname] = {
            "direction": dm.group(1).lower() if dm else "input",
            "use": um.group(1).lower() if um else None,
        }

    return name, width, height, pins


def group_buses(pins):
    """Group pins written as pin[3] into buses."""
    buses = OrderedDict()
    scalars = OrderedDict()
    for pname, info in pins.items():
        m = re.match(r"^(.*)\[(\d+)\]$", pname)
        if m:
            base, idx = m.group(1), int(m.group(2))
            b = buses.setdefault(base, {"direction": info["direction"],
                                        "bits": []})
            b["bits"].append(idx)
        else:
            scalars[pname] = info
    for b in buses.values():
        b["bits"].sort()
    return buses, scalars


def table(rows, pad):
    """Format a 3x3 lookup table as a Liberty values(...) body."""
    out = []
    for i, row in enumerate(rows):
        prefix = "" if i == 0 else pad
        out.append('%s"%s"' % (prefix, ", ".join("%.4f" % v for v in row)))
    return ",\\\n".join(out)


def constraint_block(setup_rows, hold_rows, indent):
    pad = " " * indent
    inner = pad + " " * 12
    lines = []
    for ttype, rows in (("setup_rising", setup_rows), ("hold_rising", hold_rows)):
        lines.append("%stiming() {" % pad)
        lines.append("%s    timing_type : %s;" % (pad, ttype))
        lines.append('%s    related_pin : "clk0";' % pad)
        for kind in ("rise_constraint", "fall_constraint"):
            lines.append("%s    %s(CONSTRAINT_TABLE) {" % (pad, kind))
            lines.append("%s    values(%s);" % (pad + "    ", table(rows, inner)))
            lines.append("%s    }" % pad)
        lines.append("%s}" % pad)
    return "\n".join(lines)


def gen_lib(name, area, buses, scalars, corner, args):
    proc, volt, temp, dscale, cscale = CORNERS[corner]
    # --measured: access/t_pre/hold ALREADY belong to this corner (measured in
    # ngspice with that corner's own sky130 models) -> scaling them again would
    # be DOUBLE COUNTING.
    # SETUP is now measured too (run_addr_setup.sh); when no measurement exists
    # the caller passes a pessimistic bound of 3 x t_clk2pre instead. Either
    # way the value is already per-corner, so scaling it with cscale again
    # would double count -> sscale = 1 under --measured. The margins (the
    # 0.5/0.2 inside pw_high/pw_low) are analytic, so they keep being scaled by
    # the corner derating.
    mscale = 1.0 if args.measured else dscale   # olculen buyuklukler
    hscale = 1.0 if args.measured else cscale   # hold, olculen access'i izler
    sscale = 1.0 if args.measured else cscale   # setup arrives per corner
    access = args.access * mscale
    t_pre = args.t_pre * mscale
    setup = args.setup * sscale
    hold = args.hold * hscale
    # --- the THREE TERMS of access ---------------------------------------
    # `access` in the .lib runs from clk0's rising edge until dout0 is valid.
    # The column measurement (t_dis_50) is only the MIDDLE term -- it triggers
    # off the internal `precharge` net and ends at the bitline:
    #   1) t_front : clk0 -> precharge / wordline
    #                (gen_periphery_power_tb.py: t_clk2pre / t_clk2wl)
    #   2) access  : precharge -> bitline 50%  (col*_worst_case_parasitic)
    #   3) backend : bitline -> dout0          (gen_backend_delay_tb.py)
    #                bitline inverter + column mux + output buffer
    # Without 1 and 3 the old (INCOMPLETE) behaviour is kept, and the .lib
    # header says so explicitly.
    t_front = (args.t_front or 0.0) * (1.0 if args.measured else dscale)
    be = None
    if args.backend_ns:
        be = [float(x) for x in args.backend_ns.split(",")]
        if len(be) != 3:
            sys.exit("--backend-ns needs exactly 3 values (CELL_TABLE index_2)")
    sl = None
    if args.out_slew_ns:
        sl = [float(x) for x in args.out_slew_ns.split(",")]
        if len(sl) != 3:
            sys.exit("--out-slew-ns needs exactly 3 values")
    # the windows and hold use the FULL access at the worst output load --
    # the data is not valid before that.
    access_eff = (t_front + access + max(be)) if be else (access + max(LOAD_DELTA))

    # NOTE: the windows and hold use the COMPLETE access (front end + bitline
    # + back end, at the worst output load) -- data is not valid before that.
    pw_high = access_eff + 0.5 * dscale  # degerlendirme + pay (pay analitik)
    pw_low = t_pre + 0.2 * dscale        # on-sarj + pay (pay analitik)
    period = pw_high + pw_low
    # column mux ratio: <columns>:<data bits> -- for the .lib header
    _dbits = len(buses["dout0"]["bits"]) if "dout0" in buses else 0
    mux_ratio = ("%d:%d" % (args.cols, _dbits) if args.cols and _dbits
                 else "column")

    leak = args.leakage_mw  # measured directly -- now passed per corner and
                             # NOT scaled by an inverse dscale (that old
                             # assumption could be as wrong as the SS/FF timing
                             # factors turned out to be)

    delay_rows = ([[t_front + access + b for b in be]] * 3 if be
                  else [[access + d for d in LOAD_DELTA]] * 3)
    slew_rows = [list(sl)] * 3 if sl else [list(OUT_SLEW)] * 3
    if be:
        # addr0/cs0 must stay stable through evaluate; that window is now the
        # FULL access (front end + bitline + back end).
        hold = access_eff
    setup_rows = [[setup] * 3] * 3
    hold_rows = [[hold] * 3] * 3

    addr_buses = [b for b, i in buses.items() if i["direction"] == "input"]
    data_buses = [b for b, i in buses.items() if i["direction"] == "output"]
    addr_bits = len(buses[addr_buses[0]]["bits"]) if addr_buses else 0
    data_bits = len(buses[data_buses[0]]["bits"]) if data_buses else 0

    o = []
    w = o.append
    w("/* -------------------------------------------------------------------")
    w(" * %s -- %s" % (name, corner))
    w(" * AUTO-GENERATED by scripts/rom_char/gen_rom_lib.py -- DO NOT EDIT")
    w(" *")
    w(" * The OpenRAM ROM compiler does not write a .lib; this file was built")
    w(" * from the LEF pins plus the circuit structure extracted from %s.sp."
      % name)
    w(" *")
    w(" * Model: precharged NAND-style (series chain) ROM, NO output latch.")
    w(" *   clk0 = 0 -> bitlines precharge (dout0 all ones)")
    w(" *   clk0 = 1 -> evaluate; the selected cells discharge the bitline")
    if args.chain_len:
        w(" *   worst case through ~%d series NMOS (column %s);"
          % (args.chain_len, args.worst_col if args.worst_col else "?"))
        w(" *   dout0 valid %.3f ns later" % access)
    else:
        w(" *   through the series chain;")
        w(" *   dout0 valid %.3f ns later" % access)
    w(" *   dout0 becomes INVALID when clk0 falls. The consumer must either")
    w(" *   sample on clk0's falling edge, or drive the macro with an inverted")
    w(" *   clock (clk0 = ~clk) and capture on the system clock's rising edge.")
    w(" *")
    w(" * SOURCE: access/t_pre come from ngspice measurements on %s"
      % (args.char_source if args.char_source else "an isolated column"))
    w(" * -- THIS corner (%s) was simulated separately with its own" % corner)
    w(" * sky130 model files (tt/ss/ff); no fixed scaling factor was used.")
    w(" * Measurement showed that this matters: the old SS x1.85 assumption was")
    w(" * 33% optimistic against the x2.76 that was actually measured.")
    w(" * Without --access/--t-pre this script falls back to analytic defaults")
    w(" * (based on a wrong NOR model) -- for sign-off ALWAYS call it with")
    w(" * measured values, i.e. through regen_rom_libs.sh.")
    w(" *")
    if be:
        w(" * ACCESS IS THE SUM OF THREE TERMS (all measured):")
        w(" *   clk0 -> precharge/wordline : %.4f ns" % t_front)
        w(" *   precharge -> bitline 50%%   : %.4f ns" % access)
        w(" *   bitline -> dout0           : %.4f .. %.4f ns (vs output load)"
          % (min(be), max(be)))
        w(" *   TOTAL (worst load)         : %.4f ns" % access_eff)
        w(" * Earlier versions had only the MIDDLE term; the front end and the")
        w(" * back end (bitline inverter + %s column mux + output buffer) were"
          % mux_ratio)
        w(" * MISSING.")
    else:
        w(" * WARNING: access covers only the bitline term. clk0 ->")
        w(" * precharge/wordline and bitline -> dout0 (inverter + mux + output")
        w(" * buffer) are MISSING. Pass the measured values with --t-front /")
        w(" * --backend-ns (scripts/rom_char/gen_backend_delay_tb.py).")
    if sl:
        w(" * Output transition time MEASURED: %.4f .. %.4f ns" % (min(sl), max(sl)))
    else:
        w(" * WARNING: rise/fall_transition NOT MEASURED (fixed guess) --")
        w(" * measurement showed that guess was 30-300x too low.")
    if args.energy_pj or args.energy_idle_pj:
        w(" *")
        w(" * POWER MODEL: internal_power on clk0 is ENERGY PER CYCLE (pJ);")
        w(" * the power tool applies the frequency (P = E*f*activity).")
        if args.energy_pj:
            w(" *   when \"cs0\"  = %.4f pJ  (read: column array + periphery)"
              % args.energy_pj)
        if args.energy_idle_pj:
            w(" *   when \"!cs0\" = %.4f pJ  (IDLE: cs0 only gates the"
              % args.energy_idle_pj)
            w(" *     precharge; the clk_int tree, the address buffers, the row")
            w(" *     decoder and %s wordlines switch even when deselected."
              % (args.rows if args.rows else "all"))
            w(" *     Leave this block out and OpenSTA silently scores it 0.)")
        else:
            w(" *   when \"!cs0\" = NOT WRITTEN -- idle power is then taken as")
            w(" *     ZERO, which is WRONG. Measure it with")
            w(" *     scripts/rom_char/gen_periphery_power_tb.py and pass")
            w(" *     --energy-idle-pj.")
    w(" * ----------------------------------------------------------------- */")
    w("library (%s_%s) {" % (name, corner))
    w('    delay_model : "table_lookup";')
    w('    time_unit : "1ns";')
    w('    voltage_unit : "1V";')
    w('    current_unit : "1mA";')
    w('    resistance_unit : "1kohm";')
    w("    capacitive_load_unit(1, pF);")
    w('    leakage_power_unit : "1mW";')
    w('    pulling_resistance_unit : "1kohm";')
    w("")
    w("    operating_conditions(OC) {")
    w("        process : %.1f;" % proc)
    w("        voltage : %.2f;" % volt)
    w("        temperature : %d;" % temp)
    w("    }")
    w("    default_operating_conditions : OC;")
    w("    nom_process : %.1f;" % proc)
    w("    nom_voltage : %.2f;" % volt)
    w("    nom_temperature : %d;" % temp)
    w("")
    w("    input_threshold_pct_fall       : 50.0;")
    w("    output_threshold_pct_fall      : 50.0;")
    w("    input_threshold_pct_rise       : 50.0;")
    w("    output_threshold_pct_rise      : 50.0;")
    w("    slew_lower_threshold_pct_fall  : 10.0;")
    w("    slew_upper_threshold_pct_fall  : 90.0;")
    w("    slew_lower_threshold_pct_rise  : 10.0;")
    w("    slew_upper_threshold_pct_rise  : 90.0;")
    w("")
    w("    default_cell_leakage_power    : 0.0;")
    w("    default_leakage_power_density : 0.0;")
    w("    default_input_pin_cap    : 1.0;")
    w("    default_inout_pin_cap    : 1.0;")
    w("    default_output_pin_cap   : 0.0;")
    # default_max_transition MUST COVER the measured output slew: at SS the
    # dout0 transition reaches 5.35 ns (the bitline falls very slowly), and the
    # old fixed 0.5 ns left the library SELF-INCONSISTENT -- tools flagged the
    # macro's own output as a max_transition violation.
    w("    default_max_transition   : %.4f;"
      % (max(sl) * 1.2 if sl else 0.5))
    w("    default_fanout_load      : 1.0;")
    w("    default_max_fanout       : 4.0;")
    w("    default_connection_class : universal;")
    w("")
    w("    voltage_map ( VCCD1, %.2f );" % volt)
    w("    voltage_map ( VSSD1, 0 );")
    w("")
    w("    lu_table_template(CELL_TABLE) {")
    w("        variable_1 : input_net_transition;")
    w("        variable_2 : total_output_net_capacitance;")
    w('        index_1("%s");' % ", ".join(str(x) for x in SLEW_INDEX))
    w('        index_2("%s");' % ", ".join(str(x) for x in CAP_INDEX))
    w("    }")
    w("")
    w("    lu_table_template(CONSTRAINT_TABLE) {")
    w("        variable_1 : related_pin_transition;")
    w("        variable_2 : constrained_pin_transition;")
    w('        index_1("%s");' % ", ".join(str(x) for x in SLEW_INDEX))
    w('        index_2("%s");' % ", ".join(str(x) for x in SLEW_INDEX))
    w("    }")
    w("")
    w("    type (rom_data) {")
    w("        base_type : array;")
    w("        data_type : bit;")
    w("        bit_width : %d;" % data_bits)
    w("        bit_from : %d;" % (data_bits - 1))
    w("        bit_to : 0;")
    w("    }")
    w("")
    w("    type (rom_addr) {")
    w("        base_type : array;")
    w("        data_type : bit;")
    w("        bit_width : %d;" % addr_bits)
    w("        bit_from : %d;" % (addr_bits - 1))
    w("        bit_to : 0;")
    w("    }")
    w("")
    w("cell (%s) {" % name)
    w("    memory() {")
    # Liberty also knows the "rom" type; the default is "ram" because some old
    # parsers only accept that (switch with --memory-type rom).
    w("        type : %s;" % args.memory_type)
    w("        address_width : %d;" % addr_bits)
    w("        word_width : %d;" % data_bits)
    w("    }")
    w("    interface_timing : true;")
    w("    dont_use   : true;")
    w("    map_only   : true;")
    w("    dont_touch : true;")
    w("    area : %.4f;" % area)
    w("")
    w("    pg_pin(vccd1) {")
    w("        voltage_name : VCCD1;")
    w("        pg_type : primary_power;")
    w("    }")
    w("    pg_pin(vssd1) {")
    w("        voltage_name : VSSD1;")
    w("        pg_type : primary_ground;")
    w("    }")
    w("")
    w("    leakage_power () {")
    w("        value : %.6f;" % leak)
    w("    }")
    w("    cell_leakage_power : %.6f;" % leak)
    w("")

    pad20 = " " * 20
    for bname in data_buses:
        bits = buses[bname]["bits"]
        w("    bus(%s) {" % bname)
        w("        bus_type : rom_data;")
        w("        direction : output;")
        w("        max_capacitance : %s;" % MAX_CAP)
        w("        min_capacitance : %s;" % MIN_CAP)
        w("        memory_read() {")
        w("            address : %s;" % (addr_buses[0] if addr_buses else "addr0"))
        w("        }")
        w("        pin(%s[%d:%d]) {" % (bname, bits[-1], bits[0]))
        w("        timing() {")
        w("            timing_sense : non_unate;")
        w('            related_pin : "clk0";')
        # On-sarjli dizi clk YUKSELEN kenarda degerlendirmeye baslar.
        w("            timing_type : rising_edge;")
        for kind, rows in (("cell_rise", delay_rows), ("cell_fall", delay_rows),
                           ("rise_transition", slew_rows),
                           ("fall_transition", slew_rows)):
            w("            %s(CELL_TABLE) {" % kind)
            w("            values(%s);" % table(rows, pad20))
            w("            }")
        w("        }")
        w("        }")
        w("    }")
        w("")

    for bname in addr_buses:
        bits = buses[bname]["bits"]
        w("    bus(%s) {" % bname)
        w("        bus_type : rom_addr;")
        w("        direction : input;")
        w("        capacitance : %s;" % PIN_CAP["_default"])
        w("        max_transition : %s;" % MAX_TRANSITION)
        w("        pin(%s[%d:%d]) {" % (bname, bits[-1], bits[0]))
        w(constraint_block(setup_rows, hold_rows, indent=8))
        w("        }")
        w("    }")
        w("")

    for pname, info in scalars.items():
        if info["use"] in ("power", "ground") or pname == "clk0":
            continue
        w("    pin(%s) {" % pname)
        w("        direction : input;")
        w("        capacitance : %s;" % PIN_CAP.get(pname, PIN_CAP["_default"]))
        w("        max_transition : %s;" % MAX_TRANSITION)
        w(constraint_block(setup_rows, hold_rows, indent=8))
        w("    }")
        w("")

    w("    pin(clk0) {")
    w("        clock : true;")
    w("        direction : input;")
    w("        capacitance : %s;" % PIN_CAP["clk0"])
    w("        max_transition : %s;" % MAX_TRANSITION)
    w("        timing() {")
    w('            timing_type : "min_pulse_width";')
    w("            related_pin : clk0;")
    # rise = YUKSEK faz (degerlendirme), fall = DUSUK faz (on-sarj).
    w('            rise_constraint(scalar) { values("%.4f"); }' % pw_high)
    w('            fall_constraint(scalar) { values("%.4f"); }' % pw_low)
    w("        }")
    w("        timing() {")
    w('            timing_type : "minimum_period";')
    w("            related_pin : clk0;")
    w('            rise_constraint(scalar) { values("%.4f"); }' % period)
    w('            fall_constraint(scalar) { values("%.4f"); }' % period)
    w("        }")
    if args.energy_pj or args.energy_idle_pj:
        # internal_power is ENERGY per switching event (NOT power!).
        # Its Liberty units are V*mA*ns = pJ. The power tool applies the
        # frequency itself:
        #     P_dynamic = E * f * activity
        # so characterization never needs to know the frequency. What is
        # measured is the charge Q drawn from VDD over one cycle; E = Q*VDD.
        # Frequency independence was verified experimentally (2026-09-05):
        #     TCLK=200n -> q=2.342e-13 C ; TCLK=400n -> q=2.419e-13 C  (3.3%)
        # The energy is attached to the clk0 pin because the ROM precharges and
        # evaluates ALL bitlines on every clock cycle.
        # The "when" clause IS REQUIRED: OpenSTA does not count an
        # unconditional internal_power block (verified 2026-09-05 -- with an
        # unconditional block the macro internal power never changed and
        # report_power showed 0.000000e+00).
        # Working reference: sky130_sram_*.lib, inside pin(clk0)
        #   internal_power(){ when : "!csb0 & !web0"; rise_power(scalar){...} }
        # In this ROM cs0 is active HIGH (control_nand(CS, clk_out)), so a read
        # happens at cs0=1.
        #
        # BOTH STATES ARE WRITTEN. For a state left out, OpenSTA silently
        # scores zero -- without a warning -- and the power report comes out too
        # low. The reference OpenRAM SRAM .lib also writes all four csb/web
        # combinations.
        #
        # WHY !cs0 IS NOT ZERO: cs0 only gates the precharge path.
        #     clk_int   = clock_driver(clk0)        -> INDEPENDENT of cs0
        #     precharge = ~NAND(cs0, clk_int)       -> stuck at 0 while cs0=0
        # The row decoder is driven by clk_int (its clk port is tied to
        # clk_int at top level), so even while the macro is DESELECTED the
        # clock tree, the address buffers, the decoder and all the wordlines
        # switch every cycle. The bitlines stay at VDD with the foot transistor
        # off -> their contribution is leakage only, already counted in
        # leakage_power.
        # Measured by scripts/rom_char/gen_periphery_power_tb.py (periphery in
        # isolation, the cell array represented by a lumped load -- the same
        # method as the column slice).
        if args.energy_pj:
            w("        internal_power() {")
            w('            when : "cs0";')
            w('            rise_power(scalar) { values("%.4f"); }' % args.energy_pj)
            w('            fall_power(scalar) { values("%.4f"); }' % args.energy_pj)
            w("        }")
        if args.energy_idle_pj:
            w("        internal_power() {")
            w('            when : "!cs0";')
            w('            rise_power(scalar) { values("%.4f"); }'
              % args.energy_idle_pj)
            w('            fall_power(scalar) { values("%.4f"); }'
              % args.energy_idle_pj)
            w("        }")
    w("    }")
    w("")
    w("}")
    w("}")
    return "\n".join(o) + "\n"


def main():
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--lef", default=DEFAULT_LEF)
    ap.add_argument("--macro", default=None,
                    help="macro name -- its LEF is found in the tree (instead of --lef)")
    ap.add_argument("--macros-dir", default=None,
                    help="macro tree (default: ROM_MACROS_DIR / <repo>/examples)")
    ap.add_argument("--outdir", default=None,
                    help="output directory (default: $ROM_OUT_DIR/lib)")
    ap.add_argument("--corner", action="append", choices=list(CORNERS),
                    help="corner to generate (may be given more than once)")
    ap.add_argument("--memory-type", default="ram", choices=["ram", "rom"])
    ap.add_argument("--chain-len", type=int, default=None,
                    help="series NMOS count of the worst column (.lib header only)")
    ap.add_argument("--worst-col", type=int, default=None,
                    help="worst column number (.lib header only)")
    ap.add_argument("--rows", type=int, default=None,
                    help="array row count (= number of wordlines, .lib header only)")
    ap.add_argument("--cols", type=int, default=None,
                    help="array column count (.lib header only)")
    ap.add_argument("--char-source", default=None,
                    help="description of the measurement source (.lib header only)")
    ap.add_argument("--energy-pj", type=float, default=None,
                    help="ENERGY of one read cycle (pJ, measured). If given, "
                         "an internal_power block is written on clk0. No "
                         "frequency needed -- the power tool computes "
                         "P=E*f*activity itself.")
    ap.add_argument("--t-front", type=float, default=None,
                    help="clk0 -> precharge/wordline delay (ns, measured). "
                         "Because the column measurement triggers off the "
                         "internal precharge net, this term was MISSING from "
                         "access.")
    ap.add_argument("--backend-ns", default=None,
                    help="bitline -> dout0 delay as a comma-separated list "
                         "(ns, measured) for the THREE CELL_TABLE index_2 load "
                         "points: bitline inverter + column mux + output "
                         "buffer. Without it the old (incomplete) LOAD_DELTA "
                         "guess is used.")
    ap.add_argument("--out-slew-ns", default=None,
                    help="dout0 transition time (10%%-90%%) as a comma-"
                         "separated list (ns, measured) for the three load "
                         "points. Without it the old fixed OUT_SLEW guess is "
                         "used -- which turned out to be 30-300x too low.")
    ap.add_argument("--energy-idle-pj", type=float, default=None,
                    help="ENERGY of one clk0 cycle while the macro is "
                         "DESELECTED (cs0=0) (pJ, measured). If given, a "
                         "when:\"!cs0\" internal_power block is written on "
                         "clk0. cs0 only gates the precharge; the clock tree "
                         "and the row decoder keep running -- this value is "
                         "NOT ZERO.")
    ap.add_argument("--measured", action="store_true",
                    help="the access/t_pre passed in ALREADY belong to the "
                         "corner given with --corner (that corner's own "
                         "ngspice measurement); the dscale/cscale factors in "
                         "the CORNERS table are NOT applied. Since all three "
                         "corners are measured separately, this is the correct "
                         "usage for sign-off.")
    for key, val in BASE.items():
        ap.add_argument("--" + key.replace("_", "-"), dest=key, type=float,
                        default=val, help="default %s" % val)
    args = ap.parse_args()

    if args.macro:
        args.lef = rom_paths.lef(args.macro, args.macros_dir)
    if not args.lef:
        sys.exit("ERROR: no LEF. Pass --lef <path> or --macro <name> "
                 "(or set ROM_MACROS_DIR).")

    name, width, height, pins = parse_lef(args.lef)
    area = width * height
    buses, scalars = group_buses(pins)
    # Deliverables go to $ROM_OUT_DIR/lib by default, not next to the macro.
    outdir = args.outdir or rom_paths.lib_dir()
    corners = args.corner or list(CORNERS)

    print("macro    : %s" % name)
    print("size     : %.2f x %.2f um -> area %.2f um2" % (width, height, area))
    print("buses    : %s" % ", ".join(
        "%s[%d:0] (%s)" % (b, len(i["bits"]) - 1, i["direction"])
        for b, i in buses.items()))
    print("scalars  : %s" % ", ".join(scalars))
    print("access   : %.3f ns (TT), hold %.3f ns, precharge %.3f ns"
          % (args.access, args.hold, args.t_pre))
    for corner in corners:
        text = gen_lib(name, area, buses, scalars, corner, args)
        path = os.path.join(outdir, "%s_%s.lib" % (name, corner))
        with open(path, "w") as fh:
            fh.write(text)
        print("written  : %s (%d lines)" % (path, text.count("\n")))


if __name__ == "__main__":
    main()
