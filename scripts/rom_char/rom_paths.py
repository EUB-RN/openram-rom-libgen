#!/usr/bin/env python3
"""Path resolution + macro GEOMETRY -- the single source of truth for the flow.

WHY THIS FILE EXISTS
--------------------
Every script used to repeat the same facts by hand:

  * the macro list        ("wrom0 wrom1 wrom2 wrom3")
  * worst column / chain  (a "wrom0:236:82" table, duplicated in 4 files)
  * the column count      (a literal 256; the energy/leakage multiplier)
  * the repository path   ("/home/hpw/Desktop/.../asic/macros/<macro>")

When a ROM is regenerated (different word_size / words_per_row / .bin) all
four change -- but the scripts did not notice: a stale column count silently
mis-scales energy and leakage, a stale worst column silently makes the .lib
optimistic. This module derives all four from the netlist / LEF / config so
that cannot happen.

WHAT IS DERIVED FROM WHERE
--------------------------
  rows/cols/worst_col/chain : <macro>.sp  (find_worst_column.analyse -- only
                              the `*_rom_base_array` scope is counted)
  word_size/words_per_row   : config/<macro>.py  (if present; cross-check)
  addr_bits/data_bits       : <macro>.lef  count of PIN addr0[..] / dout0[..]
  words                     : rom_configs/<macro>.bin size / (data_bits/8)

The NETLIST wins for the column count (it is physical truth); the config is
read only to cross-check: if word_size*8*words_per_row disagrees with the
netlist, you get a warning.

USAGE
-----
  Python:  import rom_paths; g = rom_paths.geometry("wrom0")
  Shell :  eval "$(python3 rom_paths.py wrom0 --sh)"   # G_COLS, G_WORST_COL...
           python3 rom_paths.py --list                 # macro names
           python3 rom_paths.py wrom0                  # human-readable summary
           python3 rom_paths.py --check wrom0          # pre-flight check

MACRO TREE
----------
Defaults to <repo>/examples. For your own macros:
  ROM_MACROS_DIR=/path/to/macros python3 rom_paths.py --list
Any directory holding <macro>/<macro>.sp works.

OUTPUTS
-------
Liberty files go to <repo>/output/lib, behavioural Verilog to
<repo>/output/verilog; override the root with ROM_OUT_DIR.
"""

from __future__ import annotations

import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))          # repository root
DEFAULT_MACROS_DIR = os.path.join(ROOT, "examples")
USER_MACROS_DIR = os.path.join(ROOT, "user")
DEFAULT_OUT_DIR = os.path.join(ROOT, "output")

sys.path.insert(0, HERE)
import find_worst_column                                # noqa: E402


# ----------------------------------------------------------------- paths ---
def default_macros_dir():
    """Default macro tree: prefer user/ if user has placed macros, else examples/."""
    if os.path.isdir(USER_MACROS_DIR):
        for name in os.listdir(USER_MACROS_DIR):
            if os.path.exists(os.path.join(USER_MACROS_DIR, name, name + ".sp")):
                return USER_MACROS_DIR
    return DEFAULT_MACROS_DIR


def macros_dir(explicit=None):
    """Macro tree: --macros-dir > ROM_MACROS_DIR > <repo>/examples."""
    """Macro tree: --macros-dir > ROM_MACROS_DIR > <repo>/user (if has macros) > <repo>/examples."""
    return os.path.abspath(explicit or os.environ.get("ROM_MACROS_DIR")
                           or DEFAULT_MACROS_DIR)
                           or default_macros_dir())


def split_macro(macro, explicit=None):
    """Return (clean_name, resolved_macro_dir).

    Handles:
      - Trailing slashes: 'wrom0/' -> ('wrom0', '<dir>/wrom0')
      - Direct directory paths: 'user/my_rom/' or '/tmp/my_rom' -> ('my_rom', '/tmp/my_rom')
      - Direct netlist paths: 'user/my_rom/my_rom.sp' -> ('my_rom', 'user/my_rom')
      - Bare macro names: 'my_rom' -> ('my_rom', '<macros_dir>/my_rom')
    """
    if macro.endswith(".sp"):
        clean_name = os.path.basename(macro)[:-3]
        return clean_name, os.path.dirname(os.path.abspath(macro))

    stripped = macro.rstrip("/\\")
    clean_name = os.path.basename(stripped)

    # If macro is already a path or directory that exists
    if ("/" in stripped or "\\" in stripped) or os.path.isdir(stripped):
        return clean_name, os.path.abspath(stripped)

    # Otherwise look up in macros_dir
    base = macros_dir(explicit)
    candidate = os.path.join(base, clean_name)
    if not os.path.exists(candidate) and explicit is None:
        user_c = os.path.join(USER_MACROS_DIR, clean_name)
        ex_c = os.path.join(DEFAULT_MACROS_DIR, clean_name)
        if os.path.exists(user_c):
            return clean_name, user_c
        elif os.path.exists(ex_c):
            return clean_name, ex_c

    return clean_name, candidate


def macro_name(macro):
    name, _ = split_macro(macro)
    return name


def macro_dir(macro, explicit=None):
    return os.path.join(macros_dir(explicit), macro)
    _, d = split_macro(macro, explicit)
    return d


def char_dir(macro, explicit=None, create=True):
    """Where characterization decks and logs live: <macro>/char."""
    d = os.path.join(macro_dir(macro, explicit), "char")
    _, d = split_macro(macro, explicit)
    cd = os.path.join(d, "char")
    if create:
        os.makedirs(d, exist_ok=True)
    return d
        os.makedirs(cd, exist_ok=True)
    return cd


def netlist(macro, explicit=None):
    return os.path.join(macro_dir(macro, explicit), macro + ".sp")
    name, d = split_macro(macro, explicit)
    return os.path.join(d, name + ".sp")


def cap_netlist(macro, explicit=None):
    """Capacitance-only parasitic netlist from Magic (run_cap_extract.sh)."""
    return os.path.join(macro_dir(macro, explicit), macro + "_cap_only.spice")
    name, d = split_macro(macro, explicit)
    return os.path.join(d, name + "_cap_only.spice")


def lef(macro, explicit=None):
    return os.path.join(macro_dir(macro, explicit), macro + ".lef")
    name, d = split_macro(macro, explicit)
    return os.path.join(d, name + ".lef")


def out_dir(kind=None, create=True):
    """Deliverable directory: ROM_OUT_DIR (or <repo>/output) [+ kind]."""
    base = os.path.abspath(os.environ.get("ROM_OUT_DIR") or DEFAULT_OUT_DIR)
def out_dir(kind=None, create=True, explicit=None):
    """Deliverable directory: explicit > ROM_OUT_DIR (or <repo>/output) [+ kind]."""
    base = os.path.abspath(explicit or os.environ.get("ROM_OUT_DIR") or DEFAULT_OUT_DIR)
    d = os.path.join(base, kind) if kind else base
    if create:
        os.makedirs(d, exist_ok=True)
    return d


def lib_dir(create=True):
def lib_dir(create=True, explicit=None):
    """Liberty (.lib) output directory."""
    return out_dir("lib", create)
    return out_dir("lib", create, explicit)


def verilog_dir(create=True):
def verilog_dir(create=True, explicit=None):
    """Behavioural Verilog (.v) output directory."""
    return out_dir("verilog", create)
    return out_dir("verilog", create, explicit)


def discover(explicit=None):
    """Every directory holding <macro>/<macro>.sp (alphabetical)."""
    base = macros_dir(explicit)
    if not os.path.isdir(base):
        return []
    out = []
    for name in sorted(os.listdir(base)):
        if os.path.exists(os.path.join(base, name, name + ".sp")):
            out.append(name)
    return out


# -------------------------------------------------------------- geometry ---
def _config_sizes(macro, explicit=None):
    """(word_size, words_per_row) from config/<macro>.py, else (None, None).
    """(word_size, words_per_row) from config/<macro>.py or <macro>.py, else (None, None).

    In an OpenRAM ROM config word_size is in BYTES (word_size=4 -> 32 bit),
    so the column count is word_size*8*words_per_row.
    """
    cfg = os.path.join(macro_dir(macro, explicit), "config", macro + ".py")
    if not os.path.exists(cfg):
    name, md = split_macro(macro, explicit)
    cfg1 = os.path.join(md, "config", name + ".py")
    cfg2 = os.path.join(md, name + ".py")
    cfg = cfg1 if os.path.exists(cfg1) else (cfg2 if os.path.exists(cfg2) else None)
    if not cfg:
        return None, None
    txt = open(cfg).read()

    def grab(key):
        m = re.search(r"^\s*%s\s*=\s*(\d+)" % key, txt, re.M)
        return int(m.group(1)) if m else None

    return grab("word_size"), grab("words_per_row")


def _lef_widths(macro, explicit=None):
    """(addr_bits, data_bits) from counting LEF pins."""
    path = lef(macro, explicit)
    if not os.path.exists(path):
        return 0, 0
    txt = open(path).read()
    return (len(re.findall(r"^\s*PIN\s+addr0\[", txt, re.M)),
            len(re.findall(r"^\s*PIN\s+dout0\[", txt, re.M)))


def _cache_path(macro, explicit=None):
    return os.path.join(char_dir(macro, explicit), ".geometry.json")


def geometry(macro, explicit=None, use_cache=True, quiet=False):
    """Everything size-related about a macro, as a dict.

    Keys: macro, dir, char, sp, lef, rows, cols, worst_col, chain, chain_avg,
          chain_min, word_size, words_per_row, addr_bits, data_bits, words.
    Scanning the netlist reads a few MB; the result is cached in
    <macro>/char/.geometry.json and refreshes itself when the netlist changes
    (mtime + size).
    """
    name, md = split_macro(macro, explicit)
    sp = netlist(macro, explicit)
    if not os.path.exists(sp):
        raise SystemExit("ERROR: no netlist at %s\n"
                         "       (is ROM_MACROS_DIR correct?)" % sp)
    st = os.stat(sp)
    # The stamp carries a schema version, so a cache written by an earlier
    # key set is refreshed instead of silently answering without the keys the
    # caller expects.
    stamp = "v2:%d:%d" % (st.st_mtime_ns, st.st_size)

    cache = _cache_path(macro, explicit)
    if use_cache and os.path.exists(cache):
        try:
            data = json.load(open(cache))
            if data.get("_stamp") == stamp:
                return data
        except (ValueError, OSError):
            pass

    r = find_worst_column.analyse(sp)
    if r is None:
        raise SystemExit("ERROR: no Xbit_r*_c* instances in %s -- is this an "
                         "OpenRAM ROM netlist?" % sp)
    rows, cols, worst_col, chain, avg, mn, best_col = r

    word_size, wpr = _config_sizes(macro, explicit)
    addr_bits, data_bits = _lef_widths(macro, explicit)

    # Cross-check config against netlist -- a loud warning beats silent
    # mis-scaling. The netlist wins.
    if word_size and wpr and not quiet:
        expect = word_size * 8 * wpr
        if expect != cols:
            print("WARNING %s: config says word_size=%d x 8 x words_per_row=%d "
                  "= %d columns, netlist has %d -- using the netlist."
                  % (macro, word_size, wpr, expect, cols), file=sys.stderr)
                  % (name, word_size, wpr, expect, cols), file=sys.stderr)
    if wpr and wpr & (wpr - 1) and not quiet:
        print("WARNING %s: words_per_row=%d is not a power of two -- the "
              "address space will have holes (word index != address)."
              % (macro, wpr), file=sys.stderr)
              % (name, wpr), file=sys.stderr)

    words = 0
    binf = os.path.join(macro_dir(macro, explicit), "rom_configs", macro + ".bin")
    binf1 = os.path.join(md, "rom_configs", name + ".bin")
    binf2 = os.path.join(md, name + ".bin")
    binf = binf1 if os.path.exists(binf1) else (binf2 if os.path.exists(binf2) else binf1)
    if data_bits and os.path.exists(binf):
        words = os.path.getsize(binf) // (data_bits // 8)

    data = {
        "_stamp": stamp,
        "macro": macro,
        "dir": macro_dir(macro, explicit),
        "macro": name,
        "dir": md,
        "char": char_dir(macro, explicit),
        "sp": sp,
        "lef": lef(macro, explicit),
        "rows": rows,
        "cols": cols,
        "worst_col": worst_col,
        "chain": chain,
        "chain_avg": round(avg, 2),
        "chain_min": mn,
        # the shortest chain -- the EARLY path (retain times in the .lib)
        "best_col": best_col,
        "best_chain": mn,
        "word_size": word_size or 0,
        "words_per_row": wpr or 0,
        "addr_bits": addr_bits,
        "data_bits": data_bits,
        "words": words,
    }
    try:
        json.dump(data, open(cache, "w"), indent=1)
    except OSError:
        pass
    return data


# ------------------------------------------------------------ pdk models ---
DEFAULT_SKY130_LIB = os.path.join(
    os.environ.get("PDK_ROOT", os.path.expanduser("~/OpenLane/pdks")),
    "sky130A", "libs.tech", "ngspice", "sky130.lib.spice")
def find_pdk_root():
    """Discover PDK_ROOT from environment or standard paths."""
    if os.environ.get("PDK_ROOT"):
        return os.environ.get("PDK_ROOT")

    # 1. Volare default path
    volare_base = os.path.expanduser("~/.volare/volare/sky130/versions")
    if os.path.isdir(volare_base):
        try:
            versions = sorted(
                [os.path.join(volare_base, d) for d in os.listdir(volare_base)],
                key=os.path.getmtime,
                reverse=True
            )
            for v in versions:
                if os.path.isdir(os.path.join(v, "sky130A")):
                    return v
        except OSError:
            pass

    # 2. OpenLane default pdks
    openlane_pdk = os.path.expanduser("~/OpenLane/pdks")
    if os.path.isdir(os.path.join(openlane_pdk, "sky130A")):
        return openlane_pdk

    # 3. System pdk
    sys_pdk = "/usr/local/share/pdk"
    if os.path.isdir(os.path.join(sys_pdk, "sky130A")):
        return sys_pdk

    return openlane_pdk


def sky130_lib():
    """ngspice model file: SKY130_LIB > PDK_ROOT/... > ~/OpenLane/pdks/...
    """ngspice model file: SKY130_LIB > PDK_ROOT/... > Volare > OpenLane > /usr/local/share/pdk"""
    if os.environ.get("SKY130_LIB"):
        return os.environ.get("SKY130_LIB")
    pdk = find_pdk_root()
    return os.path.join(pdk, "sky130A", "libs.tech", "ngspice", "sky130.lib.spice")

    This path used to be hard-coded into every generated deck
    (/home/hpw/OpenLane/...), so no run worked on any other machine.
    """
    return os.environ.get("SKY130_LIB") or DEFAULT_SKY130_LIB


# ------------------------------------------------------------- preflight ---
# Sub-circuit names the flow expects. They are what OpenRAM's rom_compiler
# emits; a hand-written or renamed ROM needs either the same names or edits
# in the generators that look for them.
REQUIRED_SUBCKTS = [
    ("{m}_rom_base_array", "cell array (geometry, worst column)"),
    ("{m}_rom_base_one_cell", "cell with a real NMOS (series chain)"),
    ("{m}_rom_base_zero_cell", "shorted cell"),
    ("{m}_precharge_cell", "bitline precharge PMOS"),
    ("{m}_rom_control_logic", "clock driver + precharge NAND"),
    ("{m}_rom_row_decode", "address buffers + row decoder + wordline drivers"),
    ("{m}_rom_bitline_inverter", "bitline inverter (back end)"),
    ("{m}_rom_column_mux_array", "column mux (back end)"),
    ("{m}_rom_output_buffer", "output buffer (back end)"),
]


def check(macro, explicit=None):
    """Pre-flight: report what a macro directory is missing. Returns 0/1."""
    md = macro_dir(macro, explicit)
    name, md = split_macro(macro, explicit)
    print("macro           : %s" % name)
    print("macro directory : %s" % md)
    rc = 0

    cfg_cand = os.path.join(md, "config", name + ".py")
    if not os.path.exists(cfg_cand):
        cfg_cand = os.path.join(md, name + ".py")

    bin_cand = os.path.join(md, "rom_configs", name + ".bin")
    if not os.path.exists(bin_cand):
        bin_cand = os.path.join(md, name + ".bin")

    files = [
        (netlist(macro, explicit), True,
         "schematic netlist -- geometry, worst column"),
        (lef(macro, explicit), True,
         "LEF -- pin list, bus widths and area for the .lib"),
        (os.path.join(md, macro + ".gds"), False,
        (os.path.join(md, name + ".gds"), False,
         "GDS -- needed by run_cap_extract.sh"),
        (cap_netlist(macro, explicit), False,
         "parasitic netlist -- produced by run_cap_extract.sh"),
        (os.path.join(md, "config", macro + ".py"), False,
        (cfg_cand, False,
         "OpenRAM config -- cross-check only"),
        (os.path.join(md, "rom_configs", macro + ".bin"), False,
        (bin_cand, False,
         "ROM contents -- word count for the Verilog model"),
    ]
    print("\nfiles:")
    for path, required, why in files:
        ok = os.path.exists(path)
        tag = "ok  " if ok else ("MISSING" if required else "absent ")
        print("  %-7s %-28s %s" % (tag, os.path.basename(path), why))
        if required and not ok:
            rc = 1
    if rc:
        print("\nA required file is missing; stopping here.")
        return rc

    text = open(netlist(macro, explicit)).read()
    print("\nsub-circuits expected by the flow:")
    for pattern, why in REQUIRED_SUBCKTS:
        name = pattern.format(m=macro)
        ok = re.search(r"^\.SUBCKT\s+%s\s" % re.escape(name), text,
        sname = pattern.format(m=name)
        ok = re.search(r"^\.SUBCKT\s+%s\s" % re.escape(sname), text,
                       re.M | re.I) is not None
        print("  %-7s %-34s %s" % ("ok  " if ok else "MISSING", name, why))
        print("  %-7s %-34s %s" % ("ok  " if ok else "MISSING", sname, why))
        if not ok:
            rc = 1

    g = geometry(macro, explicit)
    print("\ngeometry: %(rows)d rows x %(cols)d columns, worst column "
          "%(worst_col)d (chain %(chain)d)" % g)
    print("pins    : addr0[%d:0], dout0[%d:0]"
          % (g["addr_bits"] - 1, g["data_bits"] - 1))
    if rc:
        print("\nSome names differ from what the generators look for. The flow "
              "assumes OpenRAM rom_compiler naming; see the README section "
              "'Using your own ROM'.")
    else:
        print("\nAll good -- this macro can go through the flow.")
    return rc


# ------------------------------------------------------------------- CLI ---
_SH_KEYS = ["macro", "dir", "char", "sp", "lef", "rows", "cols", "worst_col",
            "chain", "best_col", "best_chain",
            "word_size", "words_per_row", "addr_bits", "data_bits",
            "words"]


def main(argv):
    args = list(argv[1:])
    explicit = None
    if "--macros-dir" in args:
        i = args.index("--macros-dir")
        explicit = args[i + 1]
        del args[i:i + 2]

    if "--list" in args:
        found = discover(explicit)
        if not found:
            print("ERROR: no <macro>/<macro>.sp found under %s"
                  % macros_dir(explicit), file=sys.stderr)
            return 1
        print(" ".join(found))
        return 0

    if "--root" in args:
        print(ROOT)
        return 0
    if "--macros-dir-only" in args:
        print(macros_dir(explicit))
        return 0
    if "--lib-dir" in args:
        print(lib_dir())
        return 0
    if "--verilog-dir" in args:
        print(verilog_dir())
        return 0
    if "--check" in args:
        args.remove("--check")
        if not args:
            print("usage: rom_paths.py --check <macro>", file=sys.stderr)
            return 1
        return check(args[0], explicit)

    as_sh = "--sh" in args
    if as_sh:
        args.remove("--sh")
    if not args:
        print(__doc__.strip())
        return 1

    g = geometry(args[0], explicit)
    if as_sh:
        for k in _SH_KEYS:
            print("G_%s='%s'" % (k.upper(), g[k]))
        # the worst column appears in many file names -- ready-made prefix
        print("G_COLTAG='col%d'" % g["worst_col"])
        print("G_BESTTAG='col%d'" % g["best_col"])
        return 0

    print("macro          : %(macro)s" % g)
    print("directory      : %(dir)s" % g)
    print("geometry       : %(rows)d rows x %(cols)d columns" % g)
    print("worst column   : %(worst_col)d  (series NMOS chain %(chain)d; "
          "avg %(chain_avg)s, min %(chain_min)d)" % g)
    print("best column    : %(best_col)d  (series NMOS chain %(best_chain)d "
          "-- the early path)" % g)
    print("capacity       : %(words)d x %(data_bits)d bit, %(addr_bits)d "
          "address bits" % g)
    print("config         : word_size=%(word_size)s words_per_row=%(words_per_row)s"
          % g)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
