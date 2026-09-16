#!/usr/bin/env python3
"""Yol cozumleme + makro GEOMETRISI -- tum akisin tek dogruluk kaynagi.

NEDEN BU DOSYA VAR
------------------
Onceki halde her betikte ayni bilgi ELLE tekrar ediliyordu:

  * makro listesi        ("wrom0 wrom1 wrom2 wrom3")
  * en kotu kolon/zincir ("wrom0:236:82" tablosu, 4 ayri dosyada)
  * kolon sayisi         (`256` sabiti; enerji/sizinti carpani)
  * depo yolu            ("/home/hpw/Desktop/.../asic/macros/<makro>")

ROM yeniden uretildiginde (word_size / words_per_row / .bin degisince) bu
dortlunun hepsi degisir ama betikler bunu ANLAMAZ: kolon sayisi yanlis
kalirsa enerji ve sizinti sessizce yanlis olceklenir, en kotu kolon yanlis
kalirsa .lib iyimser cikar. Bu modul dordunu de netlistten/LEF'ten/config'ten
TUREterek o boslugu kapatir.

NEREDEN TURETILIYOR
-------------------
  rows/cols/worst_col/chain : <makro>.sp  (find_worst_column.analyse --
                              yalnizca `*_rom_base_array` kapsami sayilir)
  word_size/words_per_row   : config/<makro>.py  (varsa; capraz kontrol)
  addr_bits/data_bits       : <makro>.lef  PIN addr0[..] / dout0[..] sayisi
  words                     : rom_configs/<makro>.bin boyutu / (data_bits/8)

cols icin NETLIST esastir (fiziksel gercek), config yalnizca capraz kontrol
icin okunur: word_size*8*words_per_row != netlist kolon sayisi ise uyarilir.

KULLANIM
--------
  Python:  import rom_paths; g = rom_paths.geometry("wrom0")
  Kabuk :  eval "$(python3 rom_paths.py wrom0 --sh)"   # G_COLS, G_WORST_COL...
           python3 rom_paths.py --list                 # makro adlari
           python3 rom_paths.py wrom0                  # insan okunur ozet

MAKRO DIZINI
------------
Varsayilan <depo_koku>/examples. Baska bir agac icin:
  ROM_MACROS_DIR=/yol/asic/macros python3 rom_paths.py --list
Makro dizini <makro>/<makro>.sp iceren herhangi bir dizin olabilir.
"""

from __future__ import annotations

import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))          # depo koku
DEFAULT_MACROS_DIR = os.path.join(ROOT, "examples")

sys.path.insert(0, HERE)
import find_worst_column                                # noqa: E402


# ---------------------------------------------------------------- yollar ---
def macros_dir(explicit=None):
    """Makro agaci: --macros-dir > ROM_MACROS_DIR > <depo>/examples."""
    return os.path.abspath(explicit or os.environ.get("ROM_MACROS_DIR")
                           or DEFAULT_MACROS_DIR)


def macro_dir(macro, explicit=None):
    return os.path.join(macros_dir(explicit), macro)


def char_dir(macro, explicit=None, create=True):
    """Karakterizasyon ciktilarinin yeri: <makro>/char."""
    d = os.path.join(macro_dir(macro, explicit), "char")
    if create:
        os.makedirs(d, exist_ok=True)
    return d


def netlist(macro, explicit=None):
    return os.path.join(macro_dir(macro, explicit), macro + ".sp")


def cap_netlist(macro, explicit=None):
    """Magic'ten cikan sadece-C parazitik netlist (run_cap_extract.sh)."""
    return os.path.join(macro_dir(macro, explicit), macro + "_cap_only.spice")


def lef(macro, explicit=None):
    return os.path.join(macro_dir(macro, explicit), macro + ".lef")


def discover(explicit=None):
    """<makro>/<makro>.sp iceren tum dizinler (alfabetik)."""
    base = macros_dir(explicit)
    if not os.path.isdir(base):
        return []
    out = []
    for name in sorted(os.listdir(base)):
        if os.path.exists(os.path.join(base, name, name + ".sp")):
            out.append(name)
    return out


# ------------------------------------------------------------- geometri ---
def _config_sizes(macro, explicit=None):
    """config/<makro>.py'den (word_size, words_per_row); yoksa (None, None).

    OpenRAM ROM config'inde word_size BAYT cinsindendir (word_size=4 -> 32
    bit); kolon sayisi = word_size*8*words_per_row.
    """
    cfg = os.path.join(macro_dir(macro, explicit), "config", macro + ".py")
    if not os.path.exists(cfg):
        return None, None
    txt = open(cfg).read()

    def grab(key):
        m = re.search(r"^\s*%s\s*=\s*(\d+)" % key, txt, re.M)
        return int(m.group(1)) if m else None

    return grab("word_size"), grab("words_per_row")


def _lef_widths(macro, explicit=None):
    """LEF pin sayimindan (addr_bits, data_bits)."""
    path = lef(macro, explicit)
    if not os.path.exists(path):
        return 0, 0
    txt = open(path).read()
    return (len(re.findall(r"^\s*PIN\s+addr0\[", txt, re.M)),
            len(re.findall(r"^\s*PIN\s+dout0\[", txt, re.M)))


def _cache_path(macro, explicit=None):
    return os.path.join(char_dir(macro, explicit), ".geometry.json")


def geometry(macro, explicit=None, use_cache=True, quiet=False):
    """Makronun tum boyut bilgisini dondurur (dict).

    Anahtarlar: macro, dir, char, sp, lef, rows, cols, worst_col, chain,
                chain_avg, chain_min, word_size, words_per_row, addr_bits,
                data_bits, words.
    Netlist taramasi ~3 MB okur; sonuc <makro>/char/.geometry.json'a
    onbeleklenir ve netlist degisince (mtime+boyut) kendiliginden tazelenir.
    """
    sp = netlist(macro, explicit)
    if not os.path.exists(sp):
        raise SystemExit("HATA: netlist yok: %s\n"
                         "      (ROM_MACROS_DIR dogru mu?)" % sp)
    st = os.stat(sp)
    stamp = "%d:%d" % (st.st_mtime_ns, st.st_size)

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
        raise SystemExit("HATA: %s icinde Xbit_r*_c* ornegi yok -- netlist "
                         "OpenRAM ROM formatinda mi?" % sp)
    rows, cols, worst_col, chain, avg, mn = r

    word_size, wpr = _config_sizes(macro, explicit)
    addr_bits, data_bits = _lef_widths(macro, explicit)

    # config ile netlist capraz kontrolu -- sessiz yanlis olcekleme yerine
    # gurultulu uyari. Netlist esas alinir.
    if word_size and wpr and not quiet:
        expect = word_size * 8 * wpr
        if expect != cols:
            print("UYARI %s: config word_size=%d x 8 x words_per_row=%d = %d "
                  "kolon bekliyor, netlistte %d kolon var -- netlist "
                  "kullanilacak." % (macro, word_size, wpr, expect, cols),
                  file=sys.stderr)
    if wpr and wpr & (wpr - 1) and not quiet:
        print("UYARI %s: words_per_row=%d 2'nin kuvveti degil -- adres uzayi "
              "bosluklu olur (kelime indeksi != adres)." % (macro, wpr),
              file=sys.stderr)

    words = 0
    binf = os.path.join(macro_dir(macro, explicit), "rom_configs", macro + ".bin")
    if data_bits and os.path.exists(binf):
        words = os.path.getsize(binf) // (data_bits // 8)

    data = {
        "_stamp": stamp,
        "macro": macro,
        "dir": macro_dir(macro, explicit),
        "char": char_dir(macro, explicit),
        "sp": sp,
        "lef": lef(macro, explicit),
        "rows": rows,
        "cols": cols,
        "worst_col": worst_col,
        "chain": chain,
        "chain_avg": round(avg, 2),
        "chain_min": mn,
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


# ------------------------------------------------------------ pdk modeli ---
DEFAULT_SKY130_LIB = os.path.join(
    os.environ.get("PDK_ROOT", os.path.expanduser("~/OpenLane/pdks")),
    "sky130A", "libs.tech", "ngspice", "sky130.lib.spice")


def sky130_lib():
    """ngspice model dosyasi: SKY130_LIB > PDK_ROOT/... > ~/OpenLane/pdks/...

    Eskiden bu yol uretilen her .sp deck'ine SABIT gomuluydu
    (/home/hpw/OpenLane/...), yani baska makinede hicbir kosum calismiyordu.
    """
    return os.environ.get("SKY130_LIB") or DEFAULT_SKY130_LIB


# ------------------------------------------------------------------ CLI ---
_SH_KEYS = ["macro", "dir", "char", "sp", "lef", "rows", "cols", "worst_col",
            "chain", "word_size", "words_per_row", "addr_bits", "data_bits",
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
            print("HATA: %s altinda <makro>/<makro>.sp bulunamadi"
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
        # en kotu kolon dosya adlarinda cok gectigi icin hazir on ek
        print("G_COLTAG='col%d'" % g["worst_col"])
        return 0

    print("makro          : %(macro)s" % g)
    print("dizin          : %(dir)s" % g)
    print("geometri       : %(rows)d satir x %(cols)d kolon" % g)
    print("en kotu kolon  : %(worst_col)d  (seri NMOS zinciri %(chain)d; "
          "ort %(chain_avg)s, min %(chain_min)d)" % g)
    print("kelime         : %(words)d x %(data_bits)d bit, adres %(addr_bits)d bit"
          % g)
    print("config         : word_size=%(word_size)s words_per_row=%(words_per_row)s"
          % g)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
