#!/usr/bin/env python3
"""En kotu kolonu ve seri zincir uzunlugunu OpenRAM ROM netlistinden bulur.

NEDEN BU DOSYA VAR
------------------
Karakterizasyon akisinin butun zamanlama olcumu tek bir kolona dayanir:
`gen_col_tb_parasitic.py <makro> <kolon>` o kolonun bitline'ini kurar ve
`regen_rom_libs.sh`'in tablosundaki access/t_pre degerleri oradan gelir.
Ama o kolon numarasi (eski makrolarda 155/67/83/116) DISARIDAN veriliyordu
ve nasil bulundugu hicbir yerde yaziliydi -- makro her yeniden uretildiginde
elle bulunmasi gereken bir bosluktu. Bu betik o boslugu kapatir.

NE SAYIYOR
----------
NAND tipi (seri zincirli) ROM'da bir bitline, satir sayisi kadar hucrenin
seri baglanmasidir. Iki hucre tipi var (bkz. `<makro>.sp`):

    rom_base_one_cell   -> gercek NMOS, kapisi wordline'da   (ZINCIRDE DIRENC)
    rom_base_zero_cell  -> kaynak/drain kisa devre           (sadece tel)

Bitline'i bosaltma suresini belirleyen sey, o kolondaki `one_cell` SAYISIDIR
-- yani seri baglanmis gercek transistor adedi. En cok `one_cell` iceren
kolon en yavas kolondur ve karakterizasyon onun uzerinden yapilmalidir.

Netlistteki hucre ornekleri `Xbit_r<satir>_c<kolon>` diye adlandirilmis;
alt devre adi devam (`+`) satirlarinin sonunda duruyor.

NEDEN ZINCIR UZUNLUGU AYRICA ONEMLI
-----------------------------------
`t_access` zincir uzunluguyla ~KARELI olcekleniyor (dagitik RC). Bkz.
docs/guides/rom_lib_uretimi.md Bolum 5 -- olculen uc nokta (zincir 267 ->
94.1 ns, 150 -> 31.7 ns, 75 -> 9.2 ns) t/L^2 icin 1.32/1.41/1.64e-3 veriyor.
Yani zincir uzunlugu, makro yeniden uretildiginde access'in ne olacagini
OLCUM YAPMADAN kestirmeye yarar; `words_per_row` degistirmenin etkisi de
dogrudan burada gorunur.

Kullanim:
    python3 find_worst_column.py                 # agactaki tum makrolar
    python3 find_worst_column.py wrom0 wrom2     # secili makrolar
    python3 find_worst_column.py --sp yol/x.sp   # dogrudan bir netlist
"""

import argparse
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

INST_RE = re.compile(r"^Xbit_r(\d+)_c(\d+)\s*$")


def analyse(sp_path):
    """(satir, kolon, en_kotu_kolon, zincir, ortalama, min) dondurur."""
    with open(sp_path) as fh:
        lines = fh.read().split("\n")

    one = collections.Counter()
    rows, cols = set(), set()
    # DIKKAT: `Xbit_r<r>_c<c>` adi UC ayri alt devrede geciyor -- ana dizi,
    # satir kod cozucu dizisi ve kolon kod cozucu dizisi. Kapsam yapilmazsa
    # kod cozucu hucreleri de sayilir; kirlenme yalnizca dusuk kolon
    # numaralarina dustugu icin hem zincir uzunlugu hem de EN KOTU KOLON
    # SECIMI yanlis cikar (2026-09-08'de wrom1/wrom2'de dogrulandi: secilen
    # kolon gercek en kotu degildi, .lib bu yuzden iyimserdi).
    # Bu yuzden yalnizca `*_rom_base_array` alt devresi sayilir.
    cur_subckt = None
    i = 0
    while i < len(lines):
        if lines[i].startswith(".SUBCKT "):
            cur_subckt = lines[i].split()[1]
        m = INST_RE.match(lines[i])
        if not m or not (cur_subckt or "").endswith("_rom_base_array"):
            i += 1
            continue
        rows.add(int(m.group(1)))
        col = int(m.group(2))
        cols.add(col)
        # ornek govdesi devam satirlarinda; alt devre adi en sondaki token
        j = i + 1
        buf = []
        while j < len(lines) and lines[j].startswith("+"):
            buf.append(lines[j][1:])
            j += 1
        if buf:
            subckt = " ".join(buf).split()[-1]
            if subckt.endswith("one_cell"):
                one[col] += 1
        i = j

    if not one:
        return None
    worst_col, chain = one.most_common(1)[0]
    return (len(rows), len(cols), worst_col, chain,
            sum(one.values()) / len(one), min(one.values()))


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("macros", nargs="*", default=None,
                    help="makro adlari (varsayilan: agactaki tum makrolar)")
    ap.add_argument("--macros-dir", default=None,
                    help="makro agaci (varsayilan: ROM_MACROS_DIR / <depo>/examples)")
    ap.add_argument("--sp", help="dogrudan bir .sp yolu (makro adi yerine)")
    args = ap.parse_args()

    targets = []
    if args.sp:
        targets.append((os.path.basename(args.sp).replace(".sp", ""), args.sp))
    else:
        # rom_paths gec import edilir: bu modulu ITHAL EDER, dongusel
        # import olmasin diye modul seviyesinde degil.
        sys.path.insert(0, HERE)
        import rom_paths
        names = args.macros or rom_paths.discover(args.macros_dir)
        if not names:
            sys.exit("makro bulunamadi: %s" % rom_paths.macros_dir(args.macros_dir))
        for n in names:
            targets.append((n, rom_paths.netlist(n, args.macros_dir)))

    print("%-8s %6s %6s %14s %11s %8s %6s"
          % ("makro", "satir", "kolon", "en_kotu_kolon", "seri_NMOS", "ort", "min"))
    rows_out = []
    for name, path in targets:
        if not os.path.exists(path):
            print("%-8s  netlist yok: %s" % (name, path), file=sys.stderr)
            continue
        r = analyse(path)
        if r is None:
            print("%-8s  Xbit_r*_c* ornegi bulunamadi -- netlist formati farkli?"
                  % name, file=sys.stderr)
            continue
        nrows, ncols, wcol, chain, avg, mn = r
        print("%-8s %6d %6d %14d %11d %8.1f %6d"
              % (name, nrows, ncols, wcol, chain, avg, mn))
        rows_out.append((name, wcol, chain))

    if rows_out:
        # NOT: bu degerleri artik ELLE kopyalamaya gerek YOK -- rom_paths.py
        # ayni analizi yapip run_*.sh ve regen_rom_libs.sh'a otomatik verir.
        # Bu ciktisi denetim/gozlem icindir.
        print("\nSonraki adim (kolon argumani istege bagli, verilmezse buradan gelir):")
        for name, _wcol, _ in rows_out:
            print("  python3 gen_col_tb_parasitic.py %s" % name)

if __name__ == "__main__":
    main()
