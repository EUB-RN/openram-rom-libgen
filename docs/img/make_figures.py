#!/usr/bin/env python3
"""Draw the README figures that need no simulator -- only logs already in the
tree.

Four of the README's figures are plots of numbers this flow has already
measured. Nothing here re-runs ngspice and nothing here holds a number of its
own: every value is parsed back out of a `.log` under <macro>/char/, the same
files gen_rom_lib.py reads. Re-run this after a characterisation and the
figures follow the measurements.

    python3 docs/img/make_figures.py            # every macro found
    python3 docs/img/make_figures.py wrom0      # one macro

Writes into docs/img/:
    05-col-discharge.png     bitline discharge and precharge, three corners
    06-front-end.png         clk0 -> internal clock, wordline, precharge
    07-backend-loads.png     dout0 at the three .lib output loads
    08-energy-settling.png   cycle 2 vs cycle 3 charge -- the settling proof
    09-chain-vs-access.png   bitline discharge against series-chain length
    12-gmin-sweep.png        periphery leakage against gmin -- why it is swept
    13-hold-sweep.png        address-hold sweep (needs run_addr_hold.sh first)

The three waveform figures need <macro>/char/wave/*.csv first -- that is what
scripts/rom_char/run_waveform_capture.sh writes, by re-running an
already-measured deck with the waveform kept. Without those files they are
skipped and the other four are still drawn.

Palette: slots 1-4 of the validated categorical reference palette, taken in
fixed order (blue, orange, aqua, yellow) so that the three corners keep the
same colour in every figure.
"""
import os
import re
import sys
import glob
import textwrap

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "scripts", "rom_char"))
import rom_paths  # noqa: E402

# categorical slots 1-4, fixed order, never cycled
C1, C2, C3, C4 = "#2a78d6", "#eb6834", "#1baf7a", "#eda100"
INK, INK2, GRID = "#0b0b0b", "#52514e", "#dddcd8"
CORNER_COLOR = {"tt": C1, "ss": C2, "ff": C3}

# the corner table of scripts/rom_char/common.sh: corner -> (VDD, degC)
CORNERS = {"tt": (1.8, 25), "ss": (1.6, 100), "ff": (1.95, -40)}


def meas(path, name):
    """One `.measure` result out of an ngspice log ('<name> = <value> ...')."""
    if not os.path.exists(path):
        return None
    with open(path, errors="ignore") as fh:
        for line in fh:
            f = line.split()
            if len(f) >= 3 and f[0] == name and f[1] == "=":
                try:
                    return float(f[2])
                except ValueError:
                    return None
    return None


def style(ax, xlabel, ylabel, title, subtitle=None):
    ax.set_title(title, color=INK, fontsize=13, loc="left", pad=18 if subtitle else 8)
    if subtitle:
        wrapped = textwrap.fill(subtitle, 92)
        ax.set_title(title + "\n", color=INK, fontsize=13, loc="left",
                     pad=10 + 13 * wrapped.count("\n"))
        ax.text(0, 1.015, wrapped, transform=ax.transAxes, color=INK2,
                fontsize=9, va="bottom")
    ax.set_xlabel(xlabel, color=INK2, fontsize=10)
    ax.set_ylabel(ylabel, color=INK2, fontsize=10)
    ax.grid(True, color=GRID, linewidth=0.7, zorder=0)
    ax.set_axisbelow(True)
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)
    for s in ("left", "bottom"):
        ax.spines[s].set_color(GRID)
    ax.tick_params(colors=INK2, labelsize=9)


def save(fig, name):
    out = os.path.join(HERE, name)
    fig.savefig(out, dpi=140, bbox_inches="tight", facecolor="#fcfcfb")
    plt.close(fig)
    print("wrote %s" % os.path.relpath(out, ROOT))


def wrdata(path, nvars):
    """Read an ngspice `wrdata` file.

    wrdata writes plain whitespace columns. When every variable shares one
    scale it emits `time v1 v2 ...`; when it cannot, it emits a (time, value)
    pair per variable. Both shapes are handled so that a deck with a mixed
    scale does not silently plot nonsense.
    """
    rows = []
    with open(path, errors="ignore") as fh:
        for line in fh:
            f = line.split()
            if not f:
                continue
            try:
                rows.append([float(x) for x in f])
            except ValueError:
                continue
    if not rows:
        return None, []
    n = len(rows[0])
    if n == nvars + 1:
        t = [r[0] for r in rows]
        return t, [[r[i + 1] for r in rows] for i in range(nvars)]
    if n == 2 * nvars:
        t = [r[0] for r in rows]
        return t, [[r[2 * i + 1] for r in rows] for i in range(nvars)]
    return None, []


# --------------------------------------------------------------------------
# 08 -- the settling proof: charge drawn in cycle 2 vs cycle 3
#
# Both energy decks integrate i(Vvdd) over two consecutive cycles. Equal
# values are the statement that the circuit has settled; a gap means the
# answer still depends on where the window was put.
# --------------------------------------------------------------------------
def fig_energy_settling(macros):
    m = macros[0]
    char = rom_paths.char_dir(m)
    col = "col%d" % rom_paths.geometry(m)["worst_col"]
    decks = [("periphery", "periph_active_%s.log"), ("column array", col + "_energy_%s.log")]

    fig, axes = plt.subplots(1, 2, figsize=(10, 3.8))
    drew = False
    for ax, (label, pat) in zip(axes, decks):
        xs, c2, c3 = [], [], []
        for c in ("tt", "ss", "ff"):
            vdd = CORNERS[c][0]
            q2, q3 = meas(os.path.join(char, pat % c), "q_c2"), meas(os.path.join(char, pat % c), "q_c3")
            if q2 is None or q3 is None:
                continue
            xs.append(c.upper())
            c2.append(abs(q2) * vdd * 1e12)
            c3.append(abs(q3) * vdd * 1e12)
        if not xs:
            ax.set_visible(False)
            continue
        drew = True
        pos = range(len(xs))
        ax.bar([p - 0.19 for p in pos], c2, 0.34, label="cycle 2", color=C1, zorder=3)
        ax.bar([p + 0.19 for p in pos], c3, 0.34, label="cycle 3", color=C3, zorder=3)
        for p, a, b in zip(pos, c2, c3):
            d = abs(b - a) / b * 100 if b else 0.0
            ax.text(p, max(a, b) * 1.04, "%.2f%%" % d, ha="center", color=INK2, fontsize=8)
        ax.set_xticks(list(pos))
        ax.set_xticklabels(xs)
        ax.set_ylim(0, max(c2 + c3) * 1.25)
        style(ax, "", "charge per cycle  (pJ)", label)
        if ax is axes[0]:                       # one legend serves both panels
            ax.legend(frameon=False, fontsize=9, labelcolor=INK2)
    if not drew:
        plt.close(fig)
        return
    fig.suptitle("%s -- energy is measured only once it stops moving" % m,
                 color=INK, fontsize=14, x=0.005, ha="left")
    fig.text(0.005, -0.02, "the label is the gap between the two windows; "
             "gen_rom_lib.py reads cycle 3", color=INK2, fontsize=9)
    fig.tight_layout()
    save(fig, "08-energy-settling.png")


# --------------------------------------------------------------------------
# 09 -- the bitline term against the number of series transistors
#
# Careful with this one. All four example macros are the SAME 134x256 array;
# what differs between them is the stored pattern, so what varies here is how
# many of the 134 cells in the worst column are real transistors (one_cells)
# rather than straps. The bitline wire, its capacitance and the number of
# cells it runs past are IDENTICAL in all four.
#
# So this figure measures one thing only: what a series transistor costs on
# top of a line that is already there. It cannot show the quadratic growth --
# that is the ARRAY HEIGHT law (more rows lengthens the line and adds series
# devices at the same time, so R and C both grow), and it needs macros of
# different row counts to be seen. Over the 77..91 span here the measured
# dependence is close to linear with a large fixed term, which is exactly
# what a fixed line plus a few more resistors in it should look like.
# --------------------------------------------------------------------------
def fig_chain_vs_access(macros):
    fig, ax = plt.subplots(figsize=(8.5, 4.6))
    drew = False
    rows = set()
    for c in ("ss", "tt", "ff"):
        pts = []
        for m in macros:
            g = rom_paths.geometry(m)
            char = rom_paths.char_dir(m)
            tag = "col%d_worst_case_parasitic" % g["worst_col"]
            log = os.path.join(char, tag + (".log" if c == "tt" else "_%s.log" % c))
            t = meas(log, "t_dis_50")
            if t is not None:
                pts.append((g["chain"], t * 1e9, m))
                rows.add((g["rows"], g["cols"]))
        if len(pts) < 2:
            continue
        drew = True
        pts.sort()
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        n = len(xs)
        sx, sy = sum(xs), sum(ys)
        slope = ((n * sum(x * y for x, y in zip(xs, ys)) - sx * sy) /
                 (n * sum(x * x for x in xs) - sx * sx))
        icpt = (sy - slope * sx) / n
        span = [min(xs) - 4, max(xs) + 4]
        ax.plot(span, [icpt + slope * x for x in span], color=CORNER_COLOR[c],
                linewidth=2, alpha=0.4, zorder=2)
        ax.plot(xs, ys, "o", markersize=9, color=CORNER_COLOR[c], zorder=4,
                markeredgecolor="#fcfcfb", markeredgewidth=2,
                label="%s  -- %.0f ps per series device" % (c.upper(), slope * 1000))
        if c == "tt":
            for x, y, m in pts:
                ax.annotate(m, (x, y), textcoords="offset points", xytext=(0, 11),
                            ha="center", color=INK2, fontsize=8)
    if not drew:
        plt.close(fig)
        return
    shape = "x".join(str(v) for v in sorted(rows)[0]) if len(rows) == 1 else "mixed"
    style(ax, "series NMOS in the discharge path  (one_cells in the worst column)",
          "precharge → bitline 50%  (ns)",
          "What one more series transistor costs, at a fixed array height",
          "measured t_dis_50; all %d macros are %s arrays, so only the stored "
          "pattern differs. This is NOT the quadratic height law -- that needs "
          "macros of different row counts." % (len(macros), shape))
    ax.legend(frameon=False, fontsize=9, labelcolor=INK2, ncol=3,
              loc="upper center", bbox_to_anchor=(0.5, -0.16))
    fig.tight_layout()
    save(fig, "09-chain-vs-access.png")


# --------------------------------------------------------------------------
# 12 -- why gmin is swept instead of chosen
#
# gmin is an artificial conductance ngspice puts across every junction to keep
# the matrix solvable. On a leakage measurement it IS part of the answer: a
# slice whose current tracks gmin is reporting the simulator, not the circuit.
# A slice is believable only where it has gone flat.
# --------------------------------------------------------------------------
def fig_gmin_sweep(macros):
    m = macros[0]
    char = rom_paths.char_dir(m)
    runs = {}
    for f in sorted(glob.glob(os.path.join(char, "periph_leak_cs0_tt_g*.log"))):
        g = re.search(r"_g([0-9.e+-]+)\.log$", f)
        if not g:
            continue
        gm = float(g.group(1))
        with open(f, errors="ignore") as fh:
            for line in fh:
                fd = line.split()
                if len(fd) == 2 and fd[0].endswith("#branch"):
                    try:
                        runs.setdefault(fd[0][1:-7], {})[gm] = abs(float(fd[1])) * 1e9
                    except ValueError:
                        pass
    if not runs:
        return
    gmins = sorted({g for s in runs.values() for g in s})
    live = [s for s in runs if max(runs[s].values()) > 0]

    # Two selections, because the figure has to make two points: the slices
    # that DOMINATE the total, and the slices that MOVE the most across the
    # axis. The second pair is the reason the sweep exists at all -- they are
    # the ones whose 1e-12 value is mostly gmin.
    def drift(s):
        v = [runs[s][g] for g in gmins if g in runs[s]]
        return max(v) / min(v) if v and min(v) > 0 else 0.0

    big = sorted(live, key=lambda s: -max(runs[s].values()))[:2]
    moved = [s for s in sorted(live, key=drift, reverse=True) if s not in big][:2]
    top = big + moved
    rest = [s for s in live if s not in top]

    fig, ax = plt.subplots(figsize=(8.5, 4.6))
    for s, col in zip(top, (C1, C2, C3, C4)):
        ys = [runs[s].get(g) for g in gmins]
        ax.plot(gmins, ys, "-o", color=col, linewidth=2, markersize=7,
                markeredgecolor="#fcfcfb", markeredgewidth=1.5, zorder=4,
                label="%s%s" % (s, "  (x%.0f across the axis)" % drift(s)
                                if s in moved else ""))
    if rest:
        for s in rest:
            ax.plot(gmins, [runs[s].get(g) for g in gmins], "-", color="#b9b8b2",
                    linewidth=1.2, zorder=2)
        ax.plot([], [], "-", color="#b9b8b2", linewidth=1.2,
                label="%d further slices" % len(rest))
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.invert_xaxis()
    style(ax, "gmin  (S)  -- swept downwards; the answer is the right-hand end",
          "slice leakage current  (nA)",
          "%s: leakage is only believable where it stops following gmin" % m,
          "one .op per gmin, cs0=0 at TT. Coloured: the two largest slices and "
          "the two that move most -- a flat line has converged, a sloped one is "
          "reporting the simulator")
    ax.legend(frameon=False, fontsize=9, labelcolor=INK2, ncol=5,
              loc="upper center", bbox_to_anchor=(0.5, -0.16))
    fig.tight_layout()
    save(fig, "12-gmin-sweep.png")


# --------------------------------------------------------------------------
# 13 -- the address-hold sweep
#
# Each point cuts the chain at the cell nearest the bitline -- the worst place
# -- at a different time after the evaluate edge, and asks whether the read
# still lands. bl_b is the bitline inverter's output, i.e. the value read.
# The smallest cut time the read survives IS the hold requirement.
# --------------------------------------------------------------------------
def fig_hold_sweep(macros):
    for m in macros:
        hold = os.path.join(rom_paths.char_dir(m), "hold")
        pts = []
        for f in glob.glob(os.path.join(hold, "cut*_tt.log")):
            t = re.search(r"cut([0-9p]+)_tt\.log$", os.path.basename(f))
            v = meas(f, "bl_b_end")
            if t and v is not None:
                pts.append((float(t.group(1).replace("p", ".")), v))
        if len(pts) < 3:
            continue
        pts.sort()
        vdd = CORNERS["tt"][0]
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        passing = [x for x, y in pts if y > vdd / 2]
        t_dis = meas(os.path.join(rom_paths.char_dir(m),
                                  "col%d_worst_case_parasitic.log"
                                  % rom_paths.geometry(m)["worst_col"]), "t_dis_50")

        fig, ax = plt.subplots(figsize=(8.5, 4.6))
        ax.axhspan(0, vdd / 2, color="#fbeeea", zorder=1)
        ax.axhline(vdd / 2, color=INK2, linewidth=1, linestyle=(0, (4, 3)), zorder=3)
        ax.text(xs[0], vdd / 2 + 0.03, "VDD/2 -- below this the read never lands",
                color=INK2, fontsize=9, va="bottom")
        ax.text(xs[0], vdd / 2 - 0.06, "VIOLATION: reads 1 where a 0 is stored",
                color="#b0442f", fontsize=9, va="top")
        if t_dis:
            ax.axvline(t_dis * 1e9, color=C3, linewidth=2, alpha=0.5, zorder=2)
            ax.annotate("t_dis_50 = %.2f ns\n(the bitline's own 50%% crossing)" % (t_dis * 1e9),
                        (t_dis * 1e9, vdd * 0.72), textcoords="offset points",
                        xytext=(-10, 0), ha="right", color=INK2, fontsize=9)
        ax.plot(xs, ys, "-o", color=C1, linewidth=2, markersize=8,
                markeredgecolor="#fcfcfb", markeredgewidth=2, zorder=5)
        if passing:
            ax.annotate("hold ≈ %.1f ns -- the smallest cut\nthe read survives"
                        % min(passing), (min(passing), vdd),
                        textcoords="offset points", xytext=(14, -46),
                        color=INK, fontsize=10)
        ax.set_ylim(-0.12, vdd * 1.18)
        ax.set_xlim(xs[0] - 1.5, xs[-1] + 5)
        style(ax, "when the address moves, ns after the evaluate edge",
              "v(bl_b) at the end of the cycle  (V)",
              "%s: how late may the address move and the read still land?" % m,
              "chain cut at the cell nearest the bitline -- the worst place to cut")
        fig.tight_layout()
        save(fig, "13-hold-sweep.png")
        return



# --------------------------------------------------------------------------
# 05/06/07 -- the waveform figures
#
# These need <macro>/char/wave/*.csv, which scripts/rom_char/run_waveform_
# capture.sh writes by re-running an already-measured deck with the waveform
# kept. Without those files the three functions below do nothing.
# --------------------------------------------------------------------------
def _wave_dir(m):
    return os.path.join(rom_paths.char_dir(m), "wave")


def fig_col_discharge(macros):
    m = macros[0]
    fig, ax = plt.subplots(figsize=(9, 4.8))
    drew = False
    for c in ("ss", "tt", "ff"):
        f = os.path.join(_wave_dir(m), "col_%s.csv" % c)
        if not os.path.exists(f):
            continue
        t, v = wrdata(f, 2)
        if not t:
            continue
        drew = True
        pre, bl = v
        # t=0 is the LAST evaluate edge, because that is the cycle the
        # .measure statements look at (TD='2.5*TCLK'): the first cycle starts
        # from the deck's initial condition and is not what was measured.
        vdd = CORNERS[c][0]
        edge = t[0]
        for i in range(1, len(t)):
            if pre[i] > vdd / 2 >= pre[i - 1]:
                edge = t[i]
        ts = [(x - edge) * 1e9 for x in t]
        ax.plot(ts, bl, color=CORNER_COLOR[c], linewidth=2, zorder=4,
                label="%s bitline  (%g V, %d °C)" % (c.upper(), vdd, CORNERS[c][1]))
        log = os.path.join(rom_paths.char_dir(m), "col%d_worst_case_parasitic%s.log"
                           % (rom_paths.geometry(m)["worst_col"],
                              "" if c == "tt" else "_" + c))
        td = meas(log, "t_dis_50")
        if td:
            ax.plot([td * 1e9], [vdd / 2], "o", markersize=9,
                    color=CORNER_COLOR[c], markeredgecolor="#fcfcfb",
                    markeredgewidth=2, zorder=6)
            ax.annotate("%.1f ns" % (td * 1e9), (td * 1e9, vdd / 2),
                        textcoords="offset points", xytext=(6, 8),
                        color=INK2, fontsize=9)
        if c == "tt":
            ax.plot(ts, pre, color=INK2, linewidth=1.2, linestyle=(0, (5, 3)),
                    zorder=3, label="precharge (TT) -- high = evaluate")
    if not drew:
        plt.close(fig)
        return
    ax.axhline(CORNERS["tt"][0] / 2, color=GRID, linewidth=1, zorder=2)
    ax.set_xlim(-8, 70)
    style(ax, "ns after the evaluate edge", "V",
          "%s: the bitline discharge IS most of the access time" % m,
          "the marked point is t_dis_50, the number gen_rom_lib.py puts in the "
          ".lib; the same column, the same deck, three corners")
    ax.legend(frameon=False, fontsize=9, labelcolor=INK2, ncol=4,
              loc="upper center", bbox_to_anchor=(0.5, -0.16))
    fig.tight_layout()
    save(fig, "05-col-discharge.png")


def fig_front_end(macros):
    m = macros[0]
    f = os.path.join(_wave_dir(m), "front_tt.csv")
    if not os.path.exists(f):
        return
    t, v = wrdata(f, 4)
    if not t:
        return
    clk, clk_int, pre, wl = v
    vdd = CORNERS["tt"][0]
    edge = next((x for x, y in zip(t, clk) if y > vdd / 2), t[0])
    ts = [(x - edge) * 1e9 for x in t]

    fig, ax = plt.subplots(figsize=(9, 4.8))
    for y, col, lab in ((clk, INK2, "clk0"), (clk_int, C1, "internal clock"),
                        (pre, C4, "precharge net"), (wl, C2, "wordline 0")):
        ax.plot(ts, y, color=col, linewidth=2, zorder=4, label=lab)
    tcp = meas(os.path.join(rom_paths.char_dir(m), "periph_active_tt.log"), "t_clk2pre")
    if tcp:
        ax.annotate("t_clk2pre = %.3f ns" % (tcp * 1e9), (tcp * 1e9, vdd / 2),
                    textcoords="offset points", xytext=(10, -22), color=INK,
                    fontsize=10, arrowprops=dict(arrowstyle="->", color=INK2, lw=1))
    ax.set_xlim(-1, 6)
    style(ax, "ns after clk0 rises", "V",
          "%s: the selected wordline FALLS during evaluate" % m,
          "this is why the column deck holds every other wordline at VDD -- the "
          "decoder polarity is measured, not assumed")
    ax.legend(frameon=False, fontsize=9, labelcolor=INK2, ncol=4,
              loc="upper center", bbox_to_anchor=(0.5, -0.16))
    fig.tight_layout()
    save(fig, "06-front-end.png")


def fig_backend_loads(macros):
    m = macros[0]
    loads = [("1.7225", "17225"), ("6.89", "689"), ("27.56", "2756")]
    fig, ax = plt.subplots(figsize=(9, 4.8))
    drew = False
    for (ff, tag), col in zip(loads, (C1, C3, C2)):
        f = os.path.join(_wave_dir(m), "backend_%s.csv" % tag)
        if not os.path.exists(f):
            continue
        t, v = wrdata(f, 2)
        if not t:
            continue
        drew = True
        bl, dout = v
        vdd = CORNERS["tt"][0]
        edge = next((x for x, y in zip(t, bl) if y < vdd / 2), t[0])
        ts = [(x - edge) * 1e9 for x in t]
        d = meas(os.path.join(rom_paths.char_dir(m), "backend_tt_%s.log" % tag),
                 "t_bl2dout")
        lab = "dout0 @ %s fF" % ff + ("  --  %.3f ns" % (d * 1e9) if d else "")
        ax.plot(ts, dout, color=col, linewidth=2, zorder=4, label=lab)
        if tag == "689":
            ax.plot(ts, bl, color=INK2, linewidth=1.2, linestyle=(0, (5, 3)),
                    zorder=3, label="the driving bitline edge")
    if not drew:
        plt.close(fig)
        return
    ax.axhline(CORNERS["tt"][0] / 2, color=GRID, linewidth=1, zorder=2)
    ax.set_xlim(-0.6, 3.5)
    style(ax, "ns after the bitline crosses VDD/2", "V",
          "%s: the .lib's load axis is three measurements, not one number" % m,
          "bitline inverter + 256:32 column mux + output buffer, at the three "
          "index_2 points of the CELL_TABLE")
    ax.legend(frameon=False, fontsize=9, labelcolor=INK2, ncol=2,
              loc="upper center", bbox_to_anchor=(0.5, -0.16))
    fig.tight_layout()
    save(fig, "07-backend-loads.png")


def main():
    want = [a for a in sys.argv[1:] if not a.startswith("-")]
    macros = want or rom_paths.discover()
    if not macros:
        sys.exit("no macros found -- set ROM_MACROS_DIR")
    for fn in (fig_col_discharge, fig_front_end, fig_backend_loads,
               fig_energy_settling, fig_chain_vs_access, fig_gmin_sweep,
               fig_hold_sweep):
        try:
            fn(macros)
        except Exception as e:                       # a missing run is not fatal
            print("skipped %s: %s" % (fn.__name__, e))


if __name__ == "__main__":
    main()
