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

# Without --lef the FIRST macro in the tree is used.
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

# Load/slew tables (pF, ns).
# CAP_INDEX came from OpenRAM's SRAM libs and IS measured -- run_backend_delay.sh
# sweeps exactly these three loads.
CAP_INDEX = [0.0017224999999999999, 0.006889999999999999, 0.027559999999999998]
# SLEW_INDEX is the axis run_slew_sweep.sh actually drives (--slew-index), and
# max_transition on the input pins is its top point, so the library cannot
# declare a slew it was never characterised at. The default below is the
# fallback for a call that passes no axis.
SLEW_INDEX = [0.05, 0.2, 0.5]
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


def _three(value, flag):
    """A CLI number that may be given once (flat) or once per index_1 point."""
    if value is None:
        return [0.0, 0.0, 0.0]
    if isinstance(value, (int, float)):
        return [float(value)] * 3
    parts = [p for p in str(value).split(",") if p.strip()]
    if len(parts) == 1:
        return [float(parts[0])] * 3
    if len(parts) != 3:
        sys.exit("%s takes 1 or 3 comma-separated values, got %d"
                 % (flag, len(parts)))
    return [float(p) for p in parts]


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
    # SETUP is measured too (run_addr_setup.sh); when no measurement exists
    # the caller passes a pessimistic bound of 3 x t_clk2pre instead. Either
    # way the value is already per-corner, so scaling it with cscale again
    # would double count -> sscale = 1 under --measured. The margins (the
    # 0.5/0.2 inside pw_high/pw_low) are analytic, so they keep being scaled by
    # the corner derating.
    mscale = 1.0 if args.measured else dscale   # measured quantities
    hscale = 1.0 if args.measured else cscale   # hold tracks the measured access
    sscale = 1.0 if args.measured else cscale   # setup arrives per corner
    access = args.access * mscale
    t_pre = args.t_pre * mscale
    setup = args.setup * sscale
    hold = args.hold * hscale
    # --- the COLUMN DECODER: a race with the bitline, not a fourth term ---
    # rom_column_decode takes addr0[0:2] and drives the eight column mux
    # selects. Its clk AND its precharge port are both tied to the internal
    # precharge net -- the same net the bitline measurement triggers off -- so
    # the decoder and the discharge start on the same edge and run in
    # PARALLEL. The mux output is valid when the LATER of the two is done:
    #     middle term = max(t_dis_50, t_coldec)
    # Measured by run_coldec_delay.sh. On the example macros the decoder wins
    # by more than an order of magnitude and access is unchanged -- but that
    # is now a measured fact instead of the assumption it used to be, and a
    # macro with a short chain and a wide mux could flip it.
    t_coldec = args.t_coldec * mscale if args.t_coldec is not None else None
    coldec_wins = t_coldec is not None and t_coldec > access
    if coldec_wins:
        access = t_coldec
    # --- the THREE TERMS of access ---------------------------------------
    # `access` in the .lib runs from clk0's rising edge until dout0 is valid.
    # The column measurement (t_dis_50) is only the MIDDLE term -- it triggers
    # off the internal `precharge` net and ends at the bitline:
    #   1) t_front : clk0 -> precharge / wordline
    #                (gen_periphery_power_tb.py: t_clk2pre / t_clk2wl)
    #   2) access  : precharge -> bitline 50%  (col*_worst_case_parasitic)
    #   3) backend : bitline -> dout0          (gen_backend_delay_tb.py)
    #                bitline inverter + column mux + output buffer
    # Without 1 and 3 only the middle term is written, and the .lib header
    # says so explicitly.
    # --- the slew axis, and what varies along it --------------------------
    slew_index = ([float(x) for x in args.slew_index.split(",")]
                  if args.slew_index else list(SLEW_INDEX))
    if len(slew_index) != 3:
        sys.exit("--slew-index needs exactly 3 values (CELL_TABLE index_1)")
    if any(b <= a for a, b in zip(slew_index, slew_index[1:])):
        sys.exit("--slew-index must be strictly increasing: %s" % slew_index)
    # An input may not be declared faster or slower than the axis it was
    # characterised on.
    max_transition = max(slew_index)

    # t_front is the ONLY term of access that depends on the clk0 edge (the
    # bitline measurement triggers off the internal precharge net and the back
    # end is driven by the bitline), so one value per slew point is the whole
    # index_1 dependence. One value is still accepted and means "flat".
    t_front_list = _three(args.t_front, "--t-front")
    dsc = 1.0 if args.measured else dscale
    t_front_list = [v * dsc for v in t_front_list]
    t_front = max(t_front_list)      # the late one, for the header and windows
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
    # the windows and hold use the COMPLETE access (front end + bitline +
    # back end, at the worst output load) -- the data is not valid before that.
    access_eff = (t_front + access + max(be)) if be else (access + max(LOAD_DELTA))

    pw_high = access_eff + 0.5 * dscale  # evaluate + margin (margin analytic)
    pw_low = t_pre + 0.2 * dscale        # precharge + margin (margin analytic)
    period = pw_high + pw_low
    # column mux ratio: <columns>:<data bits> -- for the .lib header
    _dbits = len(buses["dout0"]["bits"]) if "dout0" in buses else 0
    mux_ratio = ("%d:%d" % (args.cols, _dbits) if args.cols and _dbits
                 else "column")

    leak = args.leakage_mw  # measured per corner -- NOT scaled by an
                            # inverse dscale

    # A REAL 2-D table at last: index_1 (clk0 slew) moves t_front, index_2
    # (output load) moves the back-end term. Both axes are measured; the
    # bitline term in the middle sits on neither.
    delay_rows = ([[tf + access + b for b in be] for tf in t_front_list] if be
                  else [[access + d for d in LOAD_DELTA]] * 3)

    # --- the EARLY path: retain_rise / retain_fall -------------------------
    # Everything above is LATE data, measured on the worst column. retain_* is
    # Liberty's early bound: how long dout0 keeps the PREVIOUS cycle's value
    # after clk0 rises. Without it the tool believes the old data is held right
    # up to the access time, so a race that eats it before the capture flop
    # takes it passes silently -- there is simply nothing for a hold check to
    # fail on.
    #
    # It needs the BEST column (shortest series chain, fastest discharge), not
    # the worst; run_early_path.sh measures it. The caller passes the complete
    # sum per slew point, flat over the load axis: the load-dependent part is
    # the back-end term and taking its smallest-load value at every load keeps
    # the bound the earliest one everywhere -- the same argument as the
    # falling_edge arc.
    retain_list = (_three(args.retain_ns, "--retain-ns")
                   if args.retain_ns else None)
    if retain_list:
        retain_list = [v * dsc for v in retain_list]
        retain_rows = [[v] * 3 for v in retain_list]
        # retaining_* is the transition time of that early change. It is not
        # separately measured; the output slew of the same buffer at the
        # smallest load is the closest thing the flow has, and it is stated
        # here rather than passed off as a measurement.
        retaining_rows = [[(min(sl) if sl else OUT_SLEW[0])] * 3] * 3
    else:
        retain_rows = retaining_rows = None
    slew_rows = [list(sl)] * 3 if sl else [list(OUT_SLEW)] * 3
    # --- the falling_edge arc on dout0 -----------------------------------
    # There is no output latch: once clk0 falls the precharge PMOS turns on,
    # the bitline is pulled back to VDD and every dout0 bit returns to 1.
    # The data is gone. Without this arc the Liberty model says nothing about
    # it, so STA assumes dout0 holds until the next capture edge and reports a
    # FALSE PASS -- the header text above is not data a tool can read.
    #
    # The number is the EARLIEST invalidation, i.e. the sum of the three
    # minimum terms along the same path the access time uses, in reverse:
    #   clk0 fall -> precharge   t_clk2pre   (same inverter chain + NAND)
    #   precharge -> bitline 50% t_pre_50    (inverter trip point, NOT
    #                                         t_pre_90/99 = recharge complete)
    #   bitline   -> dout0       t_bl2dout at the SMALLEST load
    # Earliest is the right choice: what has to be proven is that the consumer
    # captured BEFORE the data went away, which is a min-delay question, and a
    # single NLDM table serves both min and max analysis. Being early is
    # pessimistic for max analysis and safe for min -- the other way round
    # would be a silent hole.
    #
    # The table is FLAT over index_2 on purpose: the load-dependent part is
    # the back-end term, and taking its smallest-load value at every load
    # keeps the arc the earliest one everywhere.
    t_invalid = ((args.t_invalid or 0.0) * (1.0 if args.measured else dscale)
                 if args.t_invalid else None)
    invalid_rows = [[t_invalid] * 3] * 3 if t_invalid else None
    if be:
        # addr0/cs0 must stay stable through evaluate; that window is the
        # FULL access (front end + bitline + back end).
        hold = access_eff
    setup_rows = [[setup] * 3] * 3
    hold_rows = [[hold] * 3] * 3

    # --- power/ground pins, and the rails they belong to -------------------
    # The names come out of the LEF (USE POWER / USE GROUND), for the same
    # reason the macro list and the geometry do: a ROM built on another PDK,
    # or with renamed supplies, otherwise gets a .lib whose pg_pins name nets
    # it does not have.
    pwr_pins = [n for n, i in scalars.items() if i["use"] == "power"]
    gnd_pins = [n for n, i in scalars.items() if i["use"] == "ground"]
    if not pwr_pins or not gnd_pins:
        # Without a supply pin there is nothing to attach power to; say so
        # rather than writing a plausible-looking pair nobody checked.
        print("WARNING: %s: the LEF declares no %s pin -- falling back to "
              "%s. Power analysis will be attributed to a net that may not "
              "exist."
              % (name, "POWER" if not pwr_pins else "GROUND",
                 "vccd1/vssd1"), file=sys.stderr)
        pwr_pins = pwr_pins or ["vccd1"]
        gnd_pins = gnd_pins or ["vssd1"]
    pwr, gnd = pwr_pins[0], gnd_pins[0]
    # voltage_map ties a rail NAME to a voltage; pg_pin's voltage_name points
    # at it, and related_power_pin on each signal pin points at the pg_pin.
    # All three links have to exist or a multi-voltage power tool cannot walk
    # from a pin to its supply: declaring the rails without referencing them
    # leaves the analysis unattributed.
    rails = [(r.upper(), volt) for r in pwr_pins] + [(r.upper(), 0.0)
                                                     for r in gnd_pins]

    # --- MEASURED input pin capacitances ----------------------------------
    # run_pin_cap.sh passes '<pin>=<fF>,...'; Liberty wants pF. Anything not
    # measured keeps the analytic PIN_CAP estimate, and the header names those
    # pins rather than letting a guess pass for a measurement.
    meas_cap = {}
    if args.pin_cap:
        for item in args.pin_cap.split(","):
            if not item.strip():
                continue
            k, _, v = item.partition("=")
            try:
                meas_cap[k.strip()] = float(v) * 1e-3   # fF -> pF
            except ValueError:
                sys.exit("--pin-cap wants '<pin>=<fF>' pairs, got %r" % item)

    def pin_cap(name, bits=None):
        """Measured capacitance in pF, else the analytic fallback.

        For a BUS the worst bit wins. Liberty carries a single capacitance on
        the ranged pin, so the alternative to the worst is telling a driver it
        will find less load than it does.
        """
        if bits is not None:
            vals = [meas_cap[k] for k in
                    ("%s[%d]" % (name, b) for b in bits) if k in meas_cap]
            if vals:
                return max(vals)
        if name in meas_cap:
            return meas_cap[name]
        return PIN_CAP.get(name, PIN_CAP["_default"])

    def cap_is_measured(name, bits=None):
        if bits is not None:
            return any("%s[%d]" % (name, b) in meas_cap for b in bits)
        return name in meas_cap

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
    if invalid_rows:
        w(" *   That invalidation IS in the data: bus(dout0) carries a second")
        w(" *   timing() group with timing_type : falling_edge and a delay of")
        w(" *   %.4f ns (clk0 falling -> dout0 leaving its valid level)." % t_invalid)
        w(" *   It is the EARLIEST invalidation -- t_clk2pre + t_pre_50 +")
        w(" *   t_bl2dout at the smallest load -- because what must be proven")
        w(" *   is that the consumer captured BEFORE the data went away.")
    else:
        w(" *   WARNING: that invalidation is NOT in the Liberty data (no")
        w(" *   --t-invalid given). STA will then assume dout0 holds until the")
        w(" *   next capture edge and report a FALSE PASS. Pass --t-invalid,")
        w(" *   i.e. run through regen_rom_libs.sh.")
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
        w(" * The back-end term covers the bitline inverter, the %s column"
          % mux_ratio)
        w(" * mux and the output buffer.")
        w(" *")
        if t_coldec is None:
            w(" * THE COLUMN DECODER WAS NEVER SIMULATED. rom_column_decode")
            w(" * drives the mux selects off the same precharge net as the")
            w(" * bitline, so it RACES the middle term. Nothing here proves")
            w(" * it loses that race -- run run_coldec_delay.sh and pass")
            w(" * --t-coldec.")
        elif coldec_wins:
            w(" * THE COLUMN DECODER WINS THE RACE: precharge -> column")
            w(" *   select is %.4f ns against %.4f ns of bitline, so the"
              % (t_coldec, args.access * mscale))
            w(" *   middle term above IS the decoder, not the discharge.")
            w(" *   That is unusual for this topology -- a short chain and a")
            w(" *   wide mux -- and worth confirming before sign-off.")
        else:
            w(" * COLUMN DECODER (measured, run_coldec_delay.sh): precharge ->")
            w(" *   column select takes %.4f ns against %.4f ns for the"
              % (t_coldec, access))
            w(" *   bitline, i.e. the mux is open %.0fx earlier than the data"
              % (access / t_coldec if t_coldec else 0))
            w(" *   needs it. It shares the precharge edge with the discharge")
            w(" *   rather than following it, so it adds NOTHING to access.")
            w(" *   This used to be an estimate; it is now a measurement.")
    else:
        w(" * WARNING: access covers only the bitline term. clk0 ->")
        w(" * precharge/wordline and bitline -> dout0 (inverter + mux + output")
        w(" * buffer) are MISSING. Pass the measured values with --t-front /")
        w(" * --backend-ns (scripts/rom_char/gen_backend_delay_tb.py).")
    w(" *")
    # clk0 is emitted as its own pin() group after the scalar loop skips it,
    # so it has to be appended here -- but only if the LEF did not already
    # list it among the scalars, or the header names it twice.
    _scalar_names = [p_ for p_ in scalars
                     if scalars[p_].get("use") not in ("power", "ground")]
    if "clk0" not in _scalar_names:
        _scalar_names.append("clk0")
    _in_pins = ([(b, buses[b]["bits"]) for b in addr_buses]
                + [(p_, None) for p_ in _scalar_names])
    _unmeas = [p_ for p_, bits in _in_pins if not cap_is_measured(p_, bits)]
    if not meas_cap:
        w(" * INPUT PIN CAPACITANCES ARE ANALYTIC, NOT MEASURED. They come")
        w(" * from gate widths in the netlist (PIN_CAP in gen_rom_lib.py) and")
        w(" * one value covers every address bit, which the extraction says")
        w(" * cannot be right -- the wire load alone varies several-fold")
        w(" * across the bus. Run run_pin_cap.sh and pass --pin-cap.")
    else:
        w(" * INPUT PIN CAPACITANCES ARE MEASURED (run_pin_cap.sh):")
        w(" *   C = Q(VDD)/VDD, the charge the pin itself supplies over a full")
        w(" *   swing -- its wire C, the gate C of the first stage it drives,")
        w(" *   and the Miller charge pushed back as that stage switches.")
        for _p, _b in _in_pins:
            if not cap_is_measured(_p, _b):
                continue
            _v = pin_cap(_p, _b)
            if _b is not None:
                _all = sorted(meas_cap["%s[%d]" % (_p, k)] for k in _b
                              if "%s[%d]" % (_p, k) in meas_cap)
                w(" *   %-8s %.4f pF  (worst of %d bits, %.4f .. %.4f)"
                  % (_p, _v, len(_all), _all[0], _all[-1]))
            else:
                w(" *   %-8s %.4f pF" % (_p, _v))
        if _in_pins and any(b is not None for _, b in _in_pins):
            w(" *   A bus carries ONE Liberty capacitance, so the ranged pin")
            w(" *   takes the WORST bit: telling a driver it will find less")
            w(" *   load than it does is the unsafe direction. The per-bit")
            w(" *   spread is above; it is real, not measurement noise.")
        if _unmeas:
            w(" *   STILL ANALYTIC (no measurement passed): %s"
              % ", ".join(_unmeas))
    if be and len(set(t_front_list)) > 1:
        w(" *")
        w(" * BOTH AXES OF THE TABLE ARE MEASURED.")
        w(" *   index_2 (output load)  : the back-end term, %.4f .. %.4f ns"
          % (min(be), max(be)))
        w(" *   index_1 (clk0 slew)    : the front-end term, %.4f .. %.4f ns"
          % (min(t_front_list), max(t_front_list)))
        w(" *     at clk0 transitions %s ns"
          % ", ".join("%g" % x for x in slew_index))
        w(" * t_front is the only term that depends on the clk0 edge: the")
        w(" * bitline measurement triggers off the internal precharge net and")
        w(" * the back end is driven by the bitline, so neither can see clk0.")
        w(" * That is also why the output transition table stays flat along")
        w(" * index_1.")
        w(" * max_transition on the inputs is %g ns, the top of that axis --"
          % max_transition)
        w(" * the library cannot declare a slew it was never measured at.")
    elif be:
        w(" *")
        w(" * WARNING: index_1 (clk0 slew) carries ONE number repeated three")
        w(" * times -- the slew axis was NOT measured. Run"
          )
        w(" * scripts/rom_char/run_slew_sweep.sh and pass --t-front a,b,c.")
    if retain_rows:
        w(" *")
        w(" * EARLY PATH (retain_rise/retain_fall on dout0): dout0 keeps the")
        w(" * PREVIOUS cycle's value for %.4f .. %.4f ns after clk0 rises."
          % (min(retain_list), max(retain_list)))
        w(" * Measured on the FASTEST ARRAY this geometry can hold, where")
        w(" * everything else in this file uses the worst column. A stored 0")
        w(" * is a metal strap and leaves the series path; a stored 1 is a")
        w(" * transistor in it, so the discharge speed is set by the CONTENTS.")
        w(" * The bound therefore comes from the limit case -- every data")
        w(" * cell strapped out, with only the foot transistor left in series")
        w(" * -- and stays valid if this geometry is reprogrammed. At that")
        w(" * limit the bound is set by the fixed circuitry (foot transistor,")
        w(" * precharge PMOS, bitline wire and inverter) rather than by the")
        w(" * array, which is why it must be measured per macro but not")
        w(" * per .bin. Without it the tool believes the old data is held")
        w(" * right up to the access time and a race that eats it before the")
        w(" * capture flop takes it passes silently: a hold check has nothing")
        w(" * to fail on.")
        w(" * retaining_rise/fall is the smallest-load output slew, not a")
        w(" * separate measurement.")
    else:
        w(" *")
        w(" * WARNING: no retain_rise/retain_fall -- this file carries LATE")
        w(" * data only (worst column). Nothing bounds how SOON dout0 can")
        w(" * move, so a hold check against the capture flop cannot fail.")
        w(" * Run scripts/rom_char/run_early_path.sh and pass --retain-ns.")
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
    w(" *")
    if args.leakage_idle_mw is not None:
        w(" * LEAKAGE covers the ARRAY AND THE PERIPHERY, both measured with")
        w(" * .op in the same idle state (clk0 low):")
        w(" *   when \"cs0\"  = %.6f mW" % args.leakage_mw)
        w(" *   when \"!cs0\" = %.6f mW" % args.leakage_idle_mw)
        w(" *   cell_leakage_power = %.6f mW, the worse of the two."
          % max(args.leakage_mw, args.leakage_idle_mw))
        w(" * The periphery half is one slice per block times a count from")
        w(" * the netlist (run_periphery_leak.sh), gmin-swept: gmin is added")
        w(" * in parallel with the leakage and at the pA level it becomes the")
        w(" * answer, so each slice is taken where the sweep stops moving.")
    else:
        w(" * WARNING: cell_leakage_power covers the CELL ARRAY ONLY. The")
        w(" * clock driver, control NAND, precharge driver, address buffers,")
        w(" * row and column decoders and %s wordline drivers are scored as"
          % (args.rows if args.rows else "the"))
        w(" * ZERO. Run scripts/rom_char/run_periphery_leak.sh and pass")
        w(" * --leakage-idle-mw.")
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
    # dout0 transition reaches 5.35 ns (the bitline falls very slowly), so a
    # fixed limit below that leaves the library SELF-INCONSISTENT -- tools
    # flag the macro's own output as a max_transition violation.
    w("    default_max_transition   : %.4f;"
      % (max(sl) * 1.2 if sl else 0.5))
    w("    default_fanout_load      : 1.0;")
    w("    default_max_fanout       : 4.0;")
    w("    default_connection_class : universal;")
    w("")
    for rail, value in rails:
        w("    voltage_map ( %s, %.2f );" % (rail, value))
    w("")
    w("    lu_table_template(CELL_TABLE) {")
    w("        variable_1 : input_net_transition;")
    w("        variable_2 : total_output_net_capacitance;")
    w('        index_1("%s");' % ", ".join(str(x) for x in slew_index))
    w('        index_2("%s");' % ", ".join(str(x) for x in CAP_INDEX))
    w("    }")
    w("")
    w("    lu_table_template(CONSTRAINT_TABLE) {")
    w("        variable_1 : related_pin_transition;")
    w("        variable_2 : constrained_pin_transition;")
    w('        index_1("%s");' % ", ".join(str(x) for x in slew_index))
    w('        index_2("%s");' % ", ".join(str(x) for x in slew_index))
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
    # Liberty also knows the "rom" type; the default is "ram" because some
    # parsers accept only that (switch with --memory-type rom).
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
    # The first POWER/GROUND pin in the LEF is the primary rail; anything
    # beyond that is written as a backup rail rather than dropped silently.
    for i, pin_name in enumerate(pwr_pins):
        w("    pg_pin(%s) {" % pin_name)
        w("        voltage_name : %s;" % pin_name.upper())
        w("        pg_type : %s;" % ("primary_power" if i == 0
                                     else "backup_power"))
        w("    }")
    for i, pin_name in enumerate(gnd_pins):
        w("    pg_pin(%s) {" % pin_name)
        w("        voltage_name : %s;" % pin_name.upper())
        w("        pg_type : %s;" % ("primary_ground" if i == 0
                                     else "backup_ground"))
        w("    }")
    w("")
    # One group per cs0 state when both were measured. cs0 gates only the
    # precharge path -- the clock tree, the address buffers and the decoder
    # leak whatever the macro is doing -- so the two states differ by the
    # periphery term, not by the array. cell_leakage_power is the WORSE of
    # them: it is the single number a tool reads when it ignores the groups.
    leak_idle = args.leakage_idle_mw
    if leak_idle is not None:
        for cond, value in (('"cs0"', leak), ('"!cs0"', leak_idle)):
            w("    leakage_power () {")
            w("        when : %s;" % cond)
            w("        related_pg_pin : %s;" % pwr)
            w("        value : %.6f;" % value)
            w("    }")
        leak = max(leak, leak_idle)
    else:
        w("    leakage_power () {")
        w("        related_pg_pin : %s;" % pwr)
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
        w("        related_power_pin  : %s;" % pwr)
        w("        related_ground_pin : %s;" % gnd)
        w("        timing() {")
        w("            timing_sense : non_unate;")
        w('            related_pin : "clk0";')
        # A precharged array starts evaluating on clk's RISING edge.
        w("            timing_type : rising_edge;")
        tables = [("cell_rise", delay_rows), ("cell_fall", delay_rows),
                  ("rise_transition", slew_rows),
                  ("fall_transition", slew_rows)]
        if retain_rows:
            # retain_* must be accompanied by retaining_* or most parsers
            # ignore the pair.
            tables += [("retain_rise", retain_rows),
                       ("retain_fall", retain_rows),
                       ("retaining_rise", retaining_rows),
                       ("retaining_fall", retaining_rows)]
        for kind, rows in tables:
            w("            %s(CELL_TABLE) {" % kind)
            w("            values(%s);" % table(rows, pad20))
            w("            }")
        w("        }")
        if invalid_rows:
            # clk0 FALLING -> dout0 invalid. Physically only the RISING
            # direction happens (the bitline is pulled back to VDD, so a bit
            # that read 0 goes to 1 and a bit that read 1 never moves), but
            # cell_fall is written with the same value: a tool that picks the
            # falling table must not silently get nothing.
            w("        timing() {")
            w("            timing_sense : non_unate;")
            w('            related_pin : "clk0";')
            w("            timing_type : falling_edge;")
            for kind, rows in (("cell_rise", invalid_rows),
                               ("cell_fall", invalid_rows),
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
        w("        capacitance : %s;" % pin_cap(bname, bits))
        w("        max_transition : %s;" % max_transition)
        w("        pin(%s[%d:%d]) {" % (bname, bits[-1], bits[0]))
        w("        related_power_pin  : %s;" % pwr)
        w("        related_ground_pin : %s;" % gnd)
        w(constraint_block(setup_rows, hold_rows, indent=8))
        w("        }")
        w("    }")
        w("")

    for pname, info in scalars.items():
        if info["use"] in ("power", "ground") or pname == "clk0":
            continue
        w("    pin(%s) {" % pname)
        w("        direction : input;")
        w("        capacitance : %s;" % pin_cap(pname))
        w("        max_transition : %s;" % max_transition)
        w("        related_power_pin  : %s;" % pwr)
        w("        related_ground_pin : %s;" % gnd)
        w(constraint_block(setup_rows, hold_rows, indent=8))
        w("    }")
        w("")

    w("    pin(clk0) {")
    w("        clock : true;")
    w("        direction : input;")
    w("        capacitance : %s;" % pin_cap("clk0"))
    w("        max_transition : %s;" % max_transition)
    w("        related_power_pin  : %s;" % pwr)
    w("        related_ground_pin : %s;" % gnd)
    w("        timing() {")
    w('            timing_type : "min_pulse_width";')
    w("            related_pin : clk0;")
    # rise = HIGH phase (evaluate), fall = LOW phase (precharge).
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
            w("            related_pg_pin : %s;" % pwr)
            w('            when : "cs0";')
            w('            rise_power(scalar) { values("%.4f"); }' % args.energy_pj)
            w('            fall_power(scalar) { values("%.4f"); }' % args.energy_pj)
            w("        }")
        if args.energy_idle_pj:
            w("        internal_power() {")
            w("            related_pg_pin : %s;" % pwr)
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
    ap.add_argument("--t-front", default=None,
                    help="clk0 -> precharge/wordline delay (ns, measured). "
                         "Because the column measurement triggers off the "
                         "internal precharge net, this term was MISSING from "
                         "access.")
    ap.add_argument("--pin-cap", default=None,
                    help="measured input pin capacitances, "
                         "'<pin>=<fF>,<pin>=<fF>,...' from run_pin_cap.sh "
                         "(note: fF, while Liberty wants pF -- the conversion "
                         "happens here). Anything not listed falls back to the "
                         "analytic PIN_CAP estimate and the header says which "
                         "pins those were. A bus takes the WORST of its bits: "
                         "Liberty carries one capacitance for the ranged pin, "
                         "and a driver told to expect less than it finds is "
                         "the unsafe direction.")
    ap.add_argument("--t-coldec", type=float, default=None,
                    help="measured precharge -> column select, ns (worst "
                         "address/corner, run_coldec_delay.sh). The column "
                         "decoder is clocked by the precharge net itself, so "
                         "it RACES the bitline rather than adding to it: the "
                         "middle term of access is max(t_dis_50, t_coldec). "
                         "Pass it and the header records which one won and by "
                         "how much; leave it out and the library says the "
                         "block was never simulated.")
    ap.add_argument("--slew-index", default=None,
                    help="3 comma-separated ns values: the CELL_TABLE index_1 "
                         "(clk0 input transition) axis. Must match what "
                         "run_slew_sweep.sh drove; its top becomes "
                         "max_transition on the input pins.")
    ap.add_argument("--retain-ns", default=None,
                    help="ns: how long dout0 keeps the PREVIOUS value after "
                         "clk0 rises (retain_rise/retain_fall, the early "
                         "bound). 1 or 3 values, one per index_1 point. "
                         "regen_rom_libs.sh builds it from the BEST column: "
                         "t_clk2pre + t_dis_50(best) + smallest-load "
                         "t_bl2dout.")
    ap.add_argument("--t-invalid", type=float, default=None,
                    help="ns: clk0 FALLING edge -> dout0 leaves its valid "
                         "level (falling_edge arc). Earliest = safest; "
                         "regen_rom_libs.sh builds it from "
                         "t_clk2pre + t_pre_50 + the smallest-load t_bl2dout.")
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
    ap.add_argument("--leakage-idle-mw", type=float, default=None,
                    help="total static leakage while the macro is DESELECTED "
                         "(cs0=0) (mW, measured). With it the library carries "
                         "one leakage_power group per cs0 state and "
                         "cell_leakage_power becomes the worse of the two. "
                         "cs0 only gates the precharge path, so the two "
                         "states differ in the periphery, not in the array.")
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
