#!/usr/bin/env python3
"""Per-cell SERIES RESISTANCE model for the ROM array.

WHY THIS FILE EXISTS
--------------------
The parasitic extraction the rest of the flow uses is capacitance-only
(`run_cap_extract.sh`, `extresist off`): Magic 8.3.629 segfaults trying to
extract resistance for the whole macro at once. That left the chain's wire
resistance out of every measurement, with no number attached to it.

Magic does not crash on a SINGLE CELL, though -- which is the same "slice x a
count" trick the rest of the flow already uses. So:

  * for each cell type, resistance is extracted with Magic on the cell alone;
  * where Magic still fails, the value is computed analytically from the .mag
    geometry and the sheet resistances in the PDK tech file;
  * where both work, the two are printed side by side, which is what makes the
    analytic model trustworthy where Magic cannot run.

The known failure is `rom_base_zero_cell`: its source and drain are the same
net (that is what programs a 0), and the resistance extractor segfaults on that
degenerate network. It is also the easy case -- the cell is a plain metal1
strap.

WHAT THE NUMBERS ARE FOR
------------------------
The series resistance of one cell, from the bitline node above it to the
bitline node below it, EXCLUDING the transistor channel (SPICE models that).
`gen_col_tb_parasitic.py --with-resistance` inserts them into the chain.

Scale: on the example macros this is ~508 ohm per one_cell against a channel
resistance of tens of kilohms, i.e. a ~1% effect on access. The point of
measuring it is to replace a guess with a bound.

Usage:
  python3 gen_resistance_model.py <macro> [--no-magic] [--keep]
Output:
  <macro>/char/resistance_model.json  +  a table on stdout
"""

import argparse
import collections
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rom_paths

UNIT_UM = 0.005          # magic internal unit -> um (verified: scnmos 72x30 = 0.36x0.15)


# ----------------------------------------------------------- tech file ------
def sheet_resistances(tech_path=None, variant=None):
    """{type name: ohm/square} from the PDK tech file's resist lines.

    The tech file gives milliohms per square, e.g.
        resist (allm1)/metal1    125
    Keyed by TYPE, not by plane: several types share the "active" plane
    (ndiff at 120 ohm/sq, poly at 48.2), so keying by plane silently picks
    whichever came first in the file.

    The tech file also repeats the whole table once per extraction VARIANT
    (the nominal block, then low/high corner blocks). Only the block for the
    variant actually used by run_cap_extract.sh -- ngspice(si) -- is read;
    taking the last block instead would silently use corner values (poly 42.2
    instead of 48.2 ohm/sq).
    """
    if tech_path is None:
        pdk = os.environ.get("PDK_ROOT", os.path.expanduser("~/OpenLane/pdks"))
        tech_path = os.path.join(pdk, "sky130A", "libs.tech", "magic", "sky130A.tech")
    variant = variant or os.environ.get("EXTRACT_STYLE", "si")
    out = {}
    if not os.path.exists(tech_path):
        return out
    active = True
    for line in open(tech_path):
        vm = re.match(r"\s*variants\s+(.+)", line)
        if vm:
            names = [v.strip().strip("()") for v in vm.group(1).split(",")]
            active = variant in names or (variant == "" and "" in names)
            continue
        m = re.match(r"\s*resist\s+\(?([^)/]+)\)?/(\w+)\s+([\d.]+)", line)
        if not m or not active:
            continue
        ohm = float(m.group(3)) / 1000.0
        for t in m.group(1).split(","):
            out[t.strip().lstrip("*")] = ohm
        out.setdefault("plane:" + m.group(2), ohm)
    return out


# Which tech type carries each magic layer we care about.
LAYER_TYPE = {"metal1": "allm1", "metal2": "allm2", "locali": "allli",
              "poly": "allpolynonres", "ndiff": "ndiff"}


def layer_ohms_per_square(rsheet, layer):
    """Sheet resistance for a .mag layer name, or None."""
    t = LAYER_TYPE.get(layer)
    if t and t in rsheet:
        return rsheet[t]
    return rsheet.get(layer) or rsheet.get("plane:" + layer)


# ---------------------------------------------------------- .mag parsing ----
def read_mag(path):
    """{layer: [(x0,y0,x1,y1), ...]} plus {label: (rect, layer)}."""
    layers = collections.defaultdict(list)
    labels = {}
    layer = None
    for line in open(path):
        s = line.strip()
        if s.startswith("<<"):
            layer = s.split()[1]
            continue
        if s.startswith("rect") and layer and layer not in ("labels", "properties"):
            x0, y0, x1, y1 = (int(v) for v in s.split()[1:5])
            layers[layer].append((x0, y0, x1, y1))
        elif s.startswith("rlabel"):
            t = s.split()
            # rlabel <layer> <dir> x0 y0 x1 y1 <font> <name>
            labels[t[-1]] = ((int(t[3]), int(t[4]), int(t[5]), int(t[6])), t[1])
    return layers, labels


# ------------------------------------------------- analytic strap model -----
def analytic_strap_ohms(mag_path, rsheet, port_a="S", port_b="D"):
    """Resistance of the metal1 strap that shorts two ports, from geometry.

    Only valid for the shorted (zero) cell, where the two port regions are
    bridged by metal on one layer. Squares are counted along the bridging
    rectangle: length / width in the direction of current flow. The wide port
    pads on either side contribute a fraction of a square and are ignored --
    the whole number is ~0.2 ohm against ~500 ohm for a real cell, so the
    approximation cannot matter.
    """
    layers, labels = read_mag(mag_path)
    if port_a not in labels or port_b not in labels:
        return None, "no %s/%s port labels" % (port_a, port_b)
    (ax0, ay0, ax1, ay1), alayer = labels[port_a]
    (bx0, by0, bx1, by1), _ = labels[port_b]
    lo, hi = (ay1, by0) if ay1 <= by0 else (by1, ay0)   # the gap in y
    if hi <= lo:
        return None, "port regions overlap; no gap to bridge"

    best = None
    for (x0, y0, x1, y1) in layers.get(alayer, []):
        if y0 <= lo and y1 >= hi:                        # spans the gap
            w = x1 - x0
            if w > 0 and (best is None or w < best[0]):
                best = (w, y1 - y0)
    if best is None:
        return None, "no %s rectangle bridges the gap" % alayer
    w, _h = best
    squares = (hi - lo) / float(w)
    rs = layer_ohms_per_square(rsheet, alayer)
    if rs is None:
        return None, "no sheet resistance for %s in the tech file" % alayer
    return squares * rs, "%s, %.2f squares x %.3f ohm/sq" % (alayer, squares, rs)


def analytic_poly_per_pitch(mag_path, rsheet, pitch_units):
    """Wordline poly resistance across one cell pitch (ohm)."""
    layers, _ = read_mag(mag_path)
    poly = layers.get("poly", [])
    if not poly:
        return None
    width = max(y1 - y0 for x0, y0, x1, y1 in poly)      # the wordline width
    rs = layer_ohms_per_square(rsheet, "poly")
    if rs is None:
        return None
    return (pitch_units / float(width)) * rs


# -------------------------------------------------- magic cell extraction ---
MAGIC_SCRIPT = """drc off
set VDD vdd
set GND gnd
set SUB gnd
load {cell}
port makeall
extract do resistance
extract all
ext2sim labels on
ext2sim
extresist tolerance 1
extresist all
ext2spice hierarchy on
ext2spice format ngspice
ext2spice cthresh 0
ext2spice rthresh 0
ext2spice extresist on
ext2spice scale off
ext2spice subcircuit top on
ext2spice -o {cell}_res.spice
quit -noprompt
"""


def magic_extract_cell(mag_path, workdir, magic_bin, tech_file):
    """Run Magic resistance extraction on one cell. Returns the .spice text."""
    cell = os.path.basename(mag_path)[:-4]
    shutil.copy(mag_path, workdir)
    cmd = [magic_bin, "-dnull", "-noconsole"]
    if tech_file:
        cmd += ["-T", tech_file]
    try:
        subprocess.run(cmd, input=MAGIC_SCRIPT.format(cell=cell), text=True,
                       cwd=workdir, capture_output=True, timeout=600)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return None, "magic did not run (%s)" % exc
    out = os.path.join(workdir, cell + "_res.spice")
    if not os.path.exists(out):
        return None, "magic produced no netlist (it segfaults on degenerate nets)"
    return open(out).read(), None


def two_point_resistance(resistors, a, b):
    """Resistance between nodes a and b of a resistor network (ohm).

    Nodal analysis with 1 A injected at a and drained at b, b as reference.
    The networks here have a handful of nodes, so a plain Gaussian elimination
    is plenty.
    """
    # Only the component containing a and b: a floating island elsewhere in
    # the network makes the nodal matrix singular.
    adj = collections.defaultdict(set)
    for n1, n2, _v in resistors:
        adj[n1].add(n2)
        adj[n2].add(n1)
    if a not in adj or b not in adj:
        return None
    comp, stack = {a}, [a]
    while stack:
        for nb in adj[stack.pop()]:
            if nb not in comp:
                comp.add(nb)
                stack.append(nb)
    if b not in comp:
        return None
    resistors = [r for r in resistors if r[0] in comp and r[1] in comp]
    nodes = sorted(comp)
    idx = {n: i for i, n in enumerate(n for n in nodes if n != b)}
    size = len(idx)
    if size == 0:
        return 0.0
    G = [[0.0] * size for _ in range(size)]
    for n1, n2, val in resistors:
        if val <= 0:
            val = 1e-9
        g = 1.0 / val
        i, j = idx.get(n1), idx.get(n2)
        if i is not None:
            G[i][i] += g
        if j is not None:
            G[j][j] += g
        if i is not None and j is not None:
            G[i][j] -= g
            G[j][i] -= g
    I = [0.0] * size
    I[idx[a]] = 1.0
    # Gaussian elimination with partial pivoting
    for col in range(size):
        piv = max(range(col, size), key=lambda r: abs(G[r][col]))
        if abs(G[piv][col]) < 1e-18:
            return None
        G[col], G[piv] = G[piv], G[col]
        I[col], I[piv] = I[piv], I[col]
        for row in range(col + 1, size):
            f = G[row][col] / G[col][col]
            if f:
                for k in range(col, size):
                    G[row][k] -= f * G[col][k]
                I[row] -= f * I[col]
    x = [0.0] * size
    for row in range(size - 1, -1, -1):
        acc = I[row] - sum(G[row][k] * x[k] for k in range(row + 1, size))
        x[row] = acc / G[row][row]
    return x[idx[a]]


def parse_res_spice(text):
    """(series resistance in ohm, note) from a resistance-extracted cell."""
    resistors, device = [], None
    for line in text.splitlines():
        t = line.split()
        if not t:
            continue
        if t[0].startswith("R") and len(t) >= 4:
            try:
                resistors.append((t[1], t[2], float(t[3])))
            except ValueError:
                pass
        elif t[0].startswith("X") and len(t) >= 5:
            device = t                     # X<n> drain gate source bulk model
    if not resistors:
        return 0.0, "no R elements (nothing in series with the channel)"
    if device is None:
        return None, "no device line found"
    drain, source = device[1], device[3]
    ports = [n for n in {n for r in resistors for n in r[:2]}
             if n in ("S", "D")]
    total, parts = 0.0, []
    for port, term in (("S", source), ("D", drain)):
        if port in ports and term != port:
            r = two_point_resistance(resistors, port, term)
            if r is not None:
                total += r
                parts.append("%s->channel %.1f" % (port, r))
    return total, "; ".join(parts) if parts else "ports and terminals coincide"


# ------------------------------------------------------------------ main ----
def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("macro")
    ap.add_argument("--macros-dir", default=None,
                    help="macro tree (default: ROM_MACROS_DIR / <repo>/examples)")
    ap.add_argument("--no-magic", action="store_true",
                    help="skip extraction, use the analytic model only")
    ap.add_argument("--keep", action="store_true",
                    help="keep the Magic working directory (for debugging)")
    args = ap.parse_args()

    mdir = rom_paths.macro_dir(args.macro, args.macros_dir)
    g = rom_paths.geometry(args.macro, args.macros_dir)
    rsheet = sheet_resistances()
    if not rsheet:
        print("WARNING: no sheet resistances found -- set PDK_ROOT so the "
              "analytic model can read sky130A.tech", file=sys.stderr)

    cells = ["%s_rom_base_one_cell" % args.macro,
             "%s_rom_base_zero_cell" % args.macro,
             "%s_precharge_cell" % args.macro]

    # WHERE THE .mag FILES LIVE.
    #
    # Only four are ever read -- the three cells above and the array, for the
    # wordline pitch -- and they are not a per-macro choice: they are the
    # first four entries of rom_paths.REQUIRED_SUBCKTS, i.e. sub-circuits
    # pre-flight already demands of every macro. So the set is fixed and
    # generic; only the <macro>_ prefix changes.
    #
    # The example macros carry their .mag at the macro root (they arrived
    # that way and are tracked there), while a macro whose layout this flow
    # writes itself gets them in <macro>/mags/ -- a whole GDS hierarchy is
    # ~90 files and does not belong loose in the directory the netlist and
    # the LEF live in. Look in mags/ first, fall back to the root, so both
    # layouts work and nothing existing has to move.
    def mag_path(name):
        sub = os.path.join(mdir, "mags", name + ".mag")
        return sub if os.path.exists(sub) else os.path.join(mdir, name + ".mag")

    magic_bin = os.environ.get("MAGIC_BIN", "magic")
    pdk = os.environ.get("PDK_ROOT", os.path.expanduser("~/OpenLane/pdks"))
    tech_file = os.path.join(pdk, "sky130A", "libs.tech", "magic", "sky130A.tech")
    tech_file = tech_file if os.path.exists(tech_file) else None

    workdir = tempfile.mkdtemp(prefix="romres_")
    result = {"macro": args.macro, "unit_um": UNIT_UM, "cells": {}}
    rows = []
    try:
        for cell in cells:
            mag = mag_path(cell)
            if not os.path.exists(mag):
                rows.append((cell, None, None, "no .mag file"))
                continue

            extracted, err = (None, "skipped")
            if not args.no_magic:
                text, err = magic_extract_cell(mag, workdir, magic_bin, tech_file)
                if text:
                    extracted, note = parse_res_spice(text)
                    err = note

            analytic, anote = analytic_strap_ohms(mag, rsheet)

            value = extracted if extracted is not None else analytic
            source = ("magic" if extracted is not None
                      else ("analytic" if analytic is not None else "unknown"))
            result["cells"][cell] = {
                "series_ohm": value,
                "source": source,
                "magic_ohm": extracted,
                "analytic_ohm": analytic,
                "magic_note": err,
                "analytic_note": anote,
            }
            rows.append((cell, extracted, analytic, err if extracted is None else ""))
    finally:
        if args.keep:
            print("magic workdir kept: %s" % workdir)
        else:
            shutil.rmtree(workdir, ignore_errors=True)

    # wordline poly per cell pitch, for reference
    one_mag = mag_path("%s_rom_base_one_cell" % args.macro)
    pitch = None
    arr_mag = mag_path("%s_rom_base_array" % args.macro)
    if os.path.exists(arr_mag):
        xs = [int(l.split()[3]) for l in open(arr_mag) if l.startswith("transform ")]
        deltas = collections.Counter(abs(a - b) for a, b in zip(xs, xs[1:]) if a != b)
        if deltas:
            pitch = deltas.most_common(1)[0][0]
    wl = (analytic_poly_per_pitch(one_mag, rsheet, pitch)
          if pitch and os.path.exists(one_mag) else None)
    result["wordline"] = {"pitch_units": pitch,
                          "pitch_um": pitch * UNIT_UM if pitch else None,
                          "poly_ohm_per_pitch": wl}

    print("%-34s %12s %12s  %s" % ("cell", "magic", "analytic", "note"))
    for cell, ext, ana, note in rows:
        print("%-34s %12s %12s  %s"
              % (cell,
                 "%.1f" % ext if ext is not None else "-",
                 "%.3f" % ana if ana is not None else "-",
                 note))

    chain_r = None
    one = result["cells"].get("%s_rom_base_one_cell" % args.macro, {})
    zero = result["cells"].get("%s_rom_base_zero_cell" % args.macro, {})
    if one.get("series_ohm") is not None:
        n_zero = g["rows"] - g["chain"]
        chain_r = one["series_ohm"] * g["chain"] + (zero.get("series_ohm") or 0) * n_zero
        result["worst_chain_ohm"] = chain_r
        print("\nworst column %d: %d one_cell x %.1f ohm + %d zero_cell x %.2f ohm"
              % (g["worst_col"], g["chain"], one["series_ohm"],
                 n_zero, zero.get("series_ohm") or 0))
        print("  -> %.1f kohm of WIRE resistance in the discharge path"
              % (chain_r / 1000.0))
        print("  (the transistor channels are on top of this and dominate; "
              "SPICE models them)")
    if wl:
        print("\nwordline poly: %.0f ohm per %.2f um cell pitch"
              % (wl, pitch * UNIT_UM))
        print("  the array straps the wordline to metal periodically, so only "
              "the poly between two straps is in series -- count the polycont "
              "spacing in %s_rom_base_array.mag before using this."
              % args.macro)

    out = os.path.join(rom_paths.char_dir(args.macro, args.macros_dir),
                       "resistance_model.json")
    json.dump(result, open(out, "w"), indent=1)
    print("\nwritten: %s" % out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
