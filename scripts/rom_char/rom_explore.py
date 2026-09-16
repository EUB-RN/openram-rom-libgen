#!/usr/bin/env python3
"""ROM makrosunun ic yapisini GORUNUR kilar -- ogrenme/inceleme araci.

NEDEN BU DOSYA VAR
------------------
`find_worst_column.py` tek bir sayi uretiyor (en kotu kolon) ama o sayinin
NEREDEN geldigi gorunmuyor. Bu betik ayni netlisti okur ve arada ne oldugunu
gosterir: hangi alt devrede kac hucre var, kolon basina seri NMOS dagilimi
nasil, secilen kolonun 107 satiri tek tek neye benziyor.

UC KOMUT
--------
    python3 rom_explore.py wrom0                # yapi ozeti + histogram + en kotu 10
    python3 rom_explore.py wrom0 --col 54       # o kolonun satir satir haritasi
    python3 rom_explore.py wrom0 --compare      # base_array vs decoder sayimi

TEMEL FIKIR (bunu anlarsan gerisi detay)
----------------------------------------
NAND-tipi ROM'da bir bitline = o kolondaki 107 hucrenin SERI baglanmasi.

    rom_base_one_cell  : bl_h --[NMOS gate=wl]-- bl_l   -> zincirde DIRENC
    rom_base_zero_cell : bl   --[  kisa devre ]-- bl    -> sadece TEL

Yani zincirdeki gercek transistor sayisi = o kolondaki one_cell sayisi.
Bosalma suresi bu sayiyla ~KARELI buyur (dagitik RC). En cok one_cell'i olan
kolon en yavas kolondur; karakterizasyon onun uzerinden yapilir.

DIKKAT: `Xbit_r*_c*` isimleri netlistte BENZERSIZ DEGIL -- ayni isim veri
dizisinde, satir kod cozucusunde ve kolon kod cozucusunde tekrar ediyor.
Sayim mutlaka `.SUBCKT <makro>_rom_base_array` icine sinirlanmali; aksi halde
kod cozucu hucreleri veri kolonlarina ekleniyor (bkz. --compare).
"""

import argparse
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rom_paths
MACROS_DIR = rom_paths.macros_dir()
INST_RE = re.compile(r"^Xbit_r(\d+)_c(\d+)\s*$")


def parse(sp_path):
    """{alt_devre: {(satir, kolon): 'one'|'zero'}} dondurur."""
    cells = collections.defaultdict(dict)
    lines = open(sp_path).read().split("\n")
    sub = None
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith(".SUBCKT"):
            sub = line.split()[1]
        m = INST_RE.match(line)
        if not m:
            i += 1
            continue
        j, buf = i + 1, []
        while j < len(lines) and lines[j].startswith("+"):
            buf.append(lines[j][1:])
            j += 1
        name = " ".join(buf).split()[-1] if buf else ""
        if name.endswith("one_cell") or name.endswith("zero_cell"):
            cells[sub][(int(m.group(1)), int(m.group(2)))] = (
                "one" if name.endswith("one_cell") else "zero")
        i = j
    return cells


def base_array(cells, macro):
    key = macro + "_rom_base_array"
    if key in cells:
        return cells[key]
    if not cells:
        sys.exit("hucre bulunamadi -- netlist formati farkli?")
    return cells[max(cells, key=lambda k: len(cells[k]))]


def chains(grid):
    """kolon -> seri NMOS (one_cell) sayisi."""
    c = collections.Counter()
    for (_, col), kind in grid.items():
        if kind == "one":
            c[col] += 1
    return c


def show_summary(macro, cells):
    grid = base_array(cells, macro)
    rows = 1 + max(r for r, _ in grid)
    cols = 1 + max(c for _, c in grid)
    ch = chains(grid)
    vals = [ch.get(c, 0) for c in range(cols)]
    worst = max(range(cols), key=lambda c: ch.get(c, 0))

    print("== %s -- veri dizisi (%s_rom_base_array)" % (macro, macro))
    print("   %d satir x %d kolon = %d hucre" % (rows, cols, rows * cols))
    print("   bir bitline = %d hucrelik SERI zincir" % rows)
    print()
    print("   kolon basina seri NMOS (one_cell):")
    print("     en kotu : kolon %-4d -> %d   <-- karakterizasyon bunu kullanmali"
          % (worst, ch[worst]))
    print("     ortalama:              %.1f" % (sum(vals) / len(vals)))
    print("     en iyi  : kolon %-4d -> %d"
          % (min(range(cols), key=lambda c: ch.get(c, 0)), min(vals)))
    print()

    lo, hi = min(vals), max(vals)
    nb = 20
    width = max(1, (hi - lo + 1) / nb)
    hist = collections.Counter(int((v - lo) / width) for v in vals)
    peak = max(hist.values())
    print("   dagilim (%d kolon):" % cols)
    for b in range(nb):
        n = hist.get(b, 0)
        if not n:
            continue
        print("     %3d-%3d | %-40s %d"
              % (lo + b * width, lo + (b + 1) * width - 1,
                 "#" * int(40 * n / peak), n))
    print()
    print("   en yavas 10 kolon:")
    for col, n in sorted(ch.items(), key=lambda kv: -kv[1])[:10]:
        print("     kolon %-4d %3d seri NMOS   (%s --col %d ile bak)"
              % (col, n, macro, col))
    print()
    print("   sonraki adim: python3 gen_col_tb_parasitic.py %s %d"
          % (macro, worst))


def show_column(macro, cells, col):
    grid = base_array(cells, macro)
    rows = 1 + max(r for r, _ in grid)
    seq = [grid.get((r, col)) for r in range(rows)]
    n_one = sum(1 for s in seq if s == "one")
    print("== %s kolon %d -- bitline zinciri (yukaridan asagiya %d satir)"
          % (macro, col, rows))
    print("   1 = one_cell  (seri NMOS, gate=wl)   -> zincirde direnc")
    print("   0 = zero_cell (kaynak=drain kisa)    -> sadece tel")
    print()
    for r0 in range(0, rows, 40):
        chunk = seq[r0:r0 + 40]
        print("   r%-4d %s" % (r0, "".join(
            "1" if s == "one" else "0" if s == "zero" else "." for s in chunk)))
    print()
    print("   seri NMOS sayisi = %d  (bosalma yolundaki gercek transistor)" % n_one)
    print("   zincir uzunlugu ~ t_access ile KARELI: L=267->94.1ns, 150->31.7ns,"
          " 75->9.2ns olculdu")


def show_compare(macro, cells):
    print("== %s -- `Xbit_r*_c*` isimleri hangi alt devrelerde geciyor" % macro)
    for sub, g in sorted(cells.items(), key=lambda kv: -len(kv[1])):
        print("   %-40s %6d hucre" % (sub, len(g)))
    print()
    only = chains(base_array(cells, macro))
    allc = collections.Counter()
    for g in cells.values():
        allc.update(chains(g))
    w1, c1 = max(only.items(), key=lambda kv: kv[1])
    w2, c2 = max(allc.items(), key=lambda kv: kv[1])
    print("   sadece veri dizisi : en kotu kolon %-4d zincir %d   <-- DOGRU" % (w1, c1))
    print("   hepsi karisik      : en kotu kolon %-4d zincir %d" % (w2, c2))
    if (w1, c1) != (w2, c2):
        print("   -> kod cozucu hucreleri sayima karisirsa sonuc degisiyor.")


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("macro", help="makro adi (wrom0) veya .sp yolu")
    ap.add_argument("--col", type=int, help="bu kolonun satir haritasini goster")
    ap.add_argument("--compare", action="store_true",
                    help="veri dizisi vs kod cozucu sayimini karsilastir")
    a = ap.parse_args()

    if a.macro.endswith(".sp"):
        path, macro = a.macro, os.path.basename(a.macro)[:-3]
    else:
        macro = a.macro
        path = os.path.join(MACROS_DIR, macro, macro + ".sp")
    if not os.path.exists(path):
        sys.exit("netlist yok: " + path)

    cells = parse(path)
    if a.compare:
        show_compare(macro, cells)
    elif a.col is not None:
        show_column(macro, cells, a.col)
    else:
        show_summary(macro, cells)


if __name__ == "__main__":
    main()
