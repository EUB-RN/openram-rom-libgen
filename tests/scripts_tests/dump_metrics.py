import glob, os, re, sys
sys.path.append("tests/lib_tests")
from libparse import parse_file
from test_rom_lib import bus_pin, arcs, rows

by_macro = {}
for f in sorted(glob.glob("output/lib/*.lib")):
    base = os.path.basename(f)
    m = re.match(r"(.+?)_(TT|SS|FF)_", base)
    if not m: continue
    macro, corner = m.group(1), m.group(2)
    lib = parse_file(f)
    cell = lib.find("cell")[0]
    pin = bus_pin(cell, "dout0")
    a = arcs(pin)
    acc = max(v for r in rows(a["rising_edge"][0].first("cell_rise")) for v in r)
    t_fall = max(v for r in rows(a["falling_edge"][0].first("cell_rise")) for v in r)
    ret = min(v for r in rows(a["rising_edge"][0].first("retain_rise")) for v in r)
    
    clk = [p for p in cell.find("pin") if p.args and p.args[0] == "clk0"][0]
    e_act = float(rows(clk.find("internal_power")[0].first("rise_power"))[0][0])
    leak = float(cell.attr("cell_leakage_power")) * 1e3
    
    if macro not in by_macro: by_macro[macro] = {}
    by_macro[macro][corner] = dict(access=acc, t_fall=t_fall, retain=ret, energy=e_act, leak=leak)

fmt = "{:<12} | {:<6} | {:>10} | {:>7} | {:>10} | {:>10} | {:>10} | {:>9}"
print(fmt.format("Macro", "Corner", "Access(ns)", "Ratio", "t_fall(ns)", "Retain(ns)", "Energy(pJ)", "Leak(uW)"))
print("-" * 92)
for macro in sorted(by_macro):
    d = by_macro[macro]
    tt_acc = d["TT"]["access"]
    for c in ["FF", "TT", "SS"]:
        cur = d[c]
        ratio = cur["access"] / tt_acc
        r_str = f"{ratio:.2f}x"
        acc_s = f"{cur['access']:.4f}"
        fall_s = f"{cur['t_fall']:.4f}"
        ret_s = f"{cur['retain']:.4f}"
        ene_s = f"{cur['energy']:.2f}"
        leak_s = f"{cur['leak']:.3f}"
        print(fmt.format(macro, c, acc_s, r_str, fall_s, ret_s, ene_s, leak_s))
    print("-" * 92)
