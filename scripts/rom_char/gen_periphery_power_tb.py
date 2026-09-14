#!/usr/bin/env python3
"""ROM makrosunun CEVRE BIRIMI (periphery) cevrim enerjisini olcer.

NEDEN GEREKLI -- `when : "!cs0"` bosluğu:
  wrom*.lib'de clk0 pininde yalnizca `internal_power(){ when : "cs0"; }`
  vardi. Makro secili DEGILKEN (cs0=0) saat geldiginde harcanan enerji
  hic yazilmamisti. OpenSTA eslesen bir blok bulamayinca o duruma sessizce
  0 yazar -- uyari bile vermez. Netlist bunun yanlis oldugunu gosteriyor:

    Xrom_control  clk0 cs0 precharge clk_int ...      (wrom0.sp:116011)
      clk_int = clock_driver(clk0)          -> cs0'dan BAGIMSIZ
      precharge = ~NAND(cs0, clk_int)       -> cs0=0 iken SABIT 0

  yani cs0=0 iken:
    * satir kod cozucu (`wrom0_rom_row_decode`) clk_int ile surulmeye
      devam eder -> adres tamponlari, kod cozucu ic dugumleri ve
      wordline'lar HER CEVRIM anahtarlanir,
    * kolon kod cozucu ve on-sarj dizisi `precharge` ile surulur ->
      SABIT kalir, anahtarlanmaz,
    * bitline'lar VDD'de tutulur, ayak transistoru kapali -> yalnizca
      sizinti (bu zaten `leakage_power` alaninda sayili).

  Sonuc: `!cs0` enerjisi TAMAMEN cevre birimidir. Bu betik onu olcer.

YONTEM -- mevcut akisla AYNI ("dilim x adet", her hucreyi tek tek DEGIL):
  gen_col_power_tb.py nasil TEK kolonu olcup 264 ile carpiyorsa, burada da
  34320 transistorluk hucre dizisi SIMULE EDILMEZ. Cikarilan netlistten
  (<macro>_cap_only.spice, gercek Magic parazitik C) yalnizca cevre birimi
  ornekleri tutulur:

    Xwrom0_rom_control_logic_0   (30 cihaz)
    Xwrom0_rom_row_decode_0      (2630 cihaz -- adres tamponu + kod cozucu
                                  + wordline tamponlari dahil)
                                  toplam ~2660 cihaz, ngspice'te saniyeler

  Silinen hucre dizisinin YUKU kaybolmasin diye, dizinin her portu icin
  o porta GATE'inden bagli cihazlar sayilir ve TEK ornek + `m=<sayi>`
  ile geri konur (SPICE'in kendi carpani -- 264 ayri ornek acmadan ayni
  kapi kapasitansi). Ustune dizinin ICINDEKI parazitik tel kapasitansi
  (o porta degen C elemanlarinin toplami) lump olarak eklenir.
  Boylece wordline'lar gercek yuklerini gorur.

  Ust seviye C elemanlari: iki ucu da yasayan dugumdeyse aynen korunur;
  bir ucu silinen bloga gidiyorsa o uc vssd1'e cevrilir (kuplaj kapasitansini
  toprakli lump olarak saymak -- standart, hafif KARAMSAR yaklasim);
  iki ucu da olmusssa atilir.

NEDEN ENERJI, NEDEN GUC DEGIL:
  Liberty `internal_power` = anahtarlama basina ENERJI (pJ). Frekansi guc
  araci uygular: P = E * f * aktivite. Yuk integrali olcup E = Q*VDD yaziyoruz.

Modlar (--cs):
  0  -> `when : "!cs0"` degeri. Secili degilken bir clk0 cevriminin enerjisi.
  1  -> aktif cevrimin CEVRE BIRIMI payi. Mevcut `--energy-pj` sayisi
        (264 x kolon) buna EKLENMELI; regen_rom_libs.sh'daki
        "cevre birimi dahil degil" notu boylece kapanir.

Kullanim:
  gen_periphery_power_tb.py <macro> <0|1> <out.sp>
      [--corner tt|ss|ff] [--vdd 1.8] [--temp 25] [--tclk 200n] [--addr N]
"""
import argparse, collections, os, re, sys

ap = argparse.ArgumentParser()
ap.add_argument("macro")
ap.add_argument("cs", type=int, choices=[0, 1],
                help="0 = bosta (!cs0), 1 = secili (cs0)")
ap.add_argument("out")
ap.add_argument("--corner", default="tt", choices=["tt", "ss", "ff"])
ap.add_argument("--vdd", default="1.8")
ap.add_argument("--temp", default="25")
ap.add_argument("--tclk", default="200n",
                help="cevrim periyodu; ENERJI buna BAGIMSIZ olmali "
                     "-- iki farkli deger ile kosup dogrulanabilir")
ap.add_argument("--addr-alt", type=int, default=None,
                help="verilirse adres, olculen clk kenarindan onceki ON-SARJ "
                     "fazinda --addr'den buna gecirilir ve addr0 -> kod cozucu "
                     "gecikmesi (SETUP) olculur. Kod cozucu ON-SARJLI oldugu "
                     "icin adres, evaluate BASLARKEN oturmus olmali: yanlis "
                     "wordline duserse bitline gibi o da geri donmez.")
ap.add_argument("--addr", type=int, default=0,
                help="sabit tutulacak adres (kod cozucu bu satiri secer)")
ap.add_argument("--gate-cap-ff", type=float, default=None,
                help="hucre basina ESDEGER kapi kapasitansi (fF) -- "
                     "gen_cell_gate_tb.py ile olculur. Verilirse wordline "
                     "yuku ciplak cihaz yerine DOGRUSAL C ile modellenir "
                     "(enerji ayni, yakinsama cok daha saglam).")
ap.add_argument("--steps", type=int, default=200,
                help="cevrim basina zaman adimi sayisi")
ap.add_argument("--cycles", type=int, default=8,
                help="kosulacak cevrim sayisi (en az 4). Son iki tam cevrim "
                     "olculur; ikisinin esit cikmasi oturmayi kanitlar.")
ap.add_argument("--repo", default="/home/hpw/Desktop/2026_teknofest_Silicore")
args = ap.parse_args()

M = args.macro
SP = f"{args.repo}/asic/macros/{M}/{M}_cap_only.spice"
if not os.path.exists(SP):
    sys.exit(f"HATA: {SP} yok -- once run_cap_extract.sh calistirin")

# --- birim duzeltmesi: gen_col_tb_parasitic.py ile AYNI (dogrulanmis) ------
SUFFIX = {"f": 1e-15, "p": 1e-12, "n": 1e-9, "u": 1e-6, "m": 1e-3, "k": 1e3}
def to_float(tok):
    m = re.match(r"^([0-9.eE+-]+)([a-zA-Z]?)$", tok)
    if not m:
        raise ValueError(tok)
    return float(m.group(1)) * SUFFIX.get(m.group(2), 1.0)

def fix_units(line):
    line = re.sub(r"\b(w|l|pd|ps)=([0-9.eE+-]+[a-zA-Z]?)\b",
                  lambda m: f"{m.group(1)}={to_float(m.group(2))*1e6:.6g}", line)
    line = re.sub(r"\b(ad|as)=([0-9.eE+-]+[a-zA-Z]?)\b",
                  lambda m: f"{m.group(1)}={to_float(m.group(2))*1e12:.6g}u", line)
    return line

# --- netlisti mantiksal satirlara ayir (devam satirlari birlestirilmis) ----
def blocks(path):
    """subckt adi -> mantiksal satir listesi (ilk eleman .subckt basligi)."""
    out, cur, name = collections.OrderedDict(), None, None
    def flush():
        nonlocal cur
        if cur is not None and name is not None:
            out[name].append(cur)
        cur = None
    for raw in open(path):
        s = raw.rstrip("\n")
        if not s or s.startswith("*"):
            continue
        if s.startswith("+"):
            if cur is not None:
                cur += " " + s[1:].strip()
            continue
        flush()
        low = s.lower()
        if low.startswith(".subckt"):
            name = s.split()[1]
            out.setdefault(name, [])
            cur = s
        elif low.startswith(".ends"):
            flush(); name = None
        else:
            cur = s
    flush()
    return out

B = blocks(SP)
TOP = M
ARRAY = f"{M}_rom_base_array"
for need in (TOP, ARRAY):
    if need not in B:
        sys.exit(f"HATA: {SP} icinde .subckt {need} yok")

top_lines = B[TOP]
top_ports = top_lines[0].split()[2:]
top_insts = [l for l in top_lines if l.startswith("X")]
top_caps  = [l for l in top_lines if l.startswith("C")]

# --- tutulacak / silinecek ornekler ---------------------------------------
KEEP_SUB = {f"{M}_rom_control_logic", f"{M}_rom_row_decode"}
keep = [l for l in top_insts if l.split()[-1] in KEEP_SUB]
drop = [l for l in top_insts if l.split()[-1] not in KEEP_SUB]
if len(keep) != 2:
    sys.exit(f"HATA: cevre birimi ornekleri bulunamadi (bulunan: "
             f"{[l.split()[-1] for l in top_insts]})")

SUPPLY_HI, SUPPLY_LO = "vccd1", "vssd1"
alive = set([SUPPLY_HI, SUPPLY_LO, "0"])
for l in keep:
    alive.update(l.split()[1:-1])
alive.update(p for p in top_ports if re.match(r"^(clk0|cs0|addr0\[)", p))

# --- silinen hucre dizisinin yukunu geri koy ------------------------------
arr = B[ARRAY]
arr_ports = arr[0].split()[2:]
arr_inst = [l for l in drop if l.split()[-1] == ARRAY]
if not arr_inst:
    sys.exit(f"HATA: ust seviyede {ARRAY} ornegi yok")
p2n = dict(zip(arr_ports, arr_inst[0].split()[1:-1]))

# Dizinin ICINDEKI yuku topla. IC ICE gecmis alt-devrelere de INILIR
# (orn. on-sarj PMOS'lari base_array > precharge_array > precharge_cell
# zincirinde duruyor); yalnizca ust kademeye bakmak on-sarj agini
# yuksuz birakirdi.
def gate_index(sub):
    ports = B[sub][0].split()[2:]
    return ports.index("G") if "G" in ports else None

gate_cnt = collections.Counter()      # (subckt, arr_port) -> adet
wire_c   = collections.Counter()      # arr_port -> toplam parazitik C (F)

def collect(sub, xlate, mult=1, depth=0):
    """xlate: alt-devrenin yerel dugum adi -> dizi portu (yalnizca ilgilenilenler)"""
    if depth > 8:
        return
    for l in B[sub][1:]:
        t = l.split()
        if l.startswith("X"):
            child, nets = t[-1], t[1:-1]
            if child not in B:
                continue
            gi = gate_index(child)
            if gi is not None:
                g = xlate.get(nets[gi])
                if g:
                    gate_cnt[(child, g)] += mult
                continue
            cports = B[child][0].split()[2:]
            sub_x = {cp: xlate[n] for cp, n in zip(cports, nets) if n in xlate}
            if sub_x:
                collect(child, sub_x, mult, depth + 1)
        elif l.startswith("C") and len(t) >= 4:
            try:
                v = to_float(t[3])
            except ValueError:
                continue
            for n in (t[1], t[2]):
                if n in xlate:
                    wire_c[xlate[n]] += v * mult

collect(ARRAY, {p: p for p in p2n})

# Hucrenin GATE tarafindaki yuku: cihazin kendisi (m=<adet>) + hucre ici
# gate parazitikleri (lump). ALT-DEVRE cagrisi + m=<adet> KULLANILMAZ:
# ngspice X satirindaki m'yi alt-devreyi ACARAK uyguluyor -- 128x264 ornek
# aciliyor ve kosum tum diziyi simule etmekle ayni maliyete cikiyor
# (2026-09-06'da olculdu: tek cevrim 2 dk'da bitmedi). Ciplak cihaz + m ise
# SPICE seviyesinde TEK cihazdir.
def cell_gate_model(sub):
    """(cihaz satiri, alt-devre portlari, gate'e dusen hucre ici C [F])"""
    dev, cg = None, 0.0
    for l in B[sub][1:]:
        t = l.split()
        if l.startswith("X"):
            dev = l
        elif l.startswith("C") and len(t) >= 4 and "G" in (t[1], t[2]):
            try:
                cg += to_float(t[3])
            except ValueError:
                pass
    return dev, B[sub][0].split()[2:], cg

# yalnizca ust seviyede HALA YASAYAN dugumlere yuk koy
load_lines, load_report = [], []
for i, (port, net) in enumerate(sorted(p2n.items())):
    if net not in alive or net in (SUPPLY_HI, SUPPLY_LO, "0"):
        continue
    subs = [(sb, c) for (sb, pp), c in gate_cnt.items() if pp == port]
    cw = max(wire_c.get(port, 0.0), 0.0)   # dizi ici tel parazitigi
    ncell = 0
    for sb, c in sorted(subs):
        dev, _, cg = cell_gate_model(sb)
        if dev is None:
            continue
        cw += cg * c
        ncell += c
        if args.gate_cap_ff is not None:
            # Kapi yuku DOGRUSAL C olarak modellenir. Enerji icin dogru
            # kucultme budur: bir dugumu VDD'ye cikarmanin VDD'den cektigi
            # yuk Q(VDD)'dir, dolayisiyla C_esd = Q(VDD)/VDD kullanmak
            # ENERJIYI birebir korur. Cihazi m=<adet> ile koymak ayni
            # enerjiyi verir ama 264 kat genis, siddetli DOGRUSAL OLMAYAN
            # bir kapasitans yaratip ngspice'i yakinsatmiyordu
            # (2026-09-06: "Timestep too small", uc ayri denemede).
            cw += args.gate_cap_ff * 1e-15 * c
            continue
        t = dev.split()
        # Cihaz dugumleri alt-devre port adlariyla yazili. G -> olculen ag;
        # kalanlar kendi besleme kutbune baglanir (PMOS'un govde/kaynagini
        # toprakla baglamak kapi kapasitansini YANLIS cikarir), bitline
        # tarafi ise toprakta -- bu kosumda bitline'lar statik.
        nets = [net if n == "G"
                else (SUPPLY_HI if n.startswith("vdd") else SUPPLY_LO)
                for n in t[1:5]]
        load_lines.append(fix_units(
            "X_wl%d_%d " % (i, len(load_lines)) + " ".join(nets) + " "
            + " ".join(t[5:]) + " m=%d" % c))
    if cw > 0:
        load_lines.append(f"C_wl{i} {net} {SUPPLY_LO} {cw*1e15:.5f}f")
    if ncell or cw > 0:
        load_report.append((port, ncell, cw))

# --- ust seviye C elemanlari: yasayan/olu kurali --------------------------
kept_c, retarget = [], collections.Counter()
n_drop = 0
for l in top_caps:
    t = l.split()
    if len(t) < 4:
        continue
    a, b = t[1], t[2]
    try:
        v = to_float(t[3])
    except ValueError:
        continue
    ao, bo = a in alive, b in alive
    if ao and bo:
        kept_c.append(l)
    elif ao:
        retarget[a] += v
    elif bo:
        retarget[b] += v
    else:
        n_drop += 1
clamped = 0
for i_rt, (n, v) in enumerate(sorted(retarget.items())):
    if v <= 0:
        clamped += 1
        continue
    kept_c.append(f"C_rt{i_rt} {n} {SUPPLY_LO} {v*1e15:.5f}f")

# --- NEGATIF NET KAPASITANS DUZELTMESI -----------------------------------
# Magic ext2spice (cthresh 0) alt-taban duzeltmesi olarak NEGATIF degerli C
# yaziyor; bunlar ancak kupleyen bloklarin POZITIF terimleriyle birlikte
# anlamli. Hucre dizisini silince o pozitif terimler de gitti ve 1185 dugumun
# NET kapasitansi negatife dondu -- cozucu icin bu bir bomba: her denemede
# t~1e-13..1e-10'da "Timestep too small" ile patliyordu (2026-09-06, alti
# ayri secenek/uyaran kombinasyonu).
# Duzeltme en az mudahale ile: yalnizca NET TOPLAMI negatif olan dugume,
# toplami sifira getiren bir C eklenir. Kaynakla surulen dugumlere (besleme,
# clk0, cs0, addr) dokunulmaz -- onlarin gerilimini kapasitans belirlemiyor.
driven = {SUPPLY_HI, SUPPLY_LO, "0"} | {
    p for p in top_ports if re.match(r"^(clk0|cs0|addr0\[)", p)}
node_c = collections.Counter()
for l in kept_c + [x for x in load_lines if x.startswith("C")]:
    t = l.split()
    try:
        v = to_float(t[3])
    except (ValueError, IndexError):
        continue
    node_c[t[1]] += v
    node_c[t[2]] += v
n_fix, c_fix_tot = 0, 0.0
for i_fx, (n, v) in enumerate(sorted(node_c.items())):
    if v >= 0 or n in driven:
        continue
    kept_c.append(f"C_fx{i_fx} {n} {SUPPLY_LO} {-v*1e15:.5f}f")
    n_fix += 1
    c_fix_tot += -v

# --- alt-devre tanimlari: yalnizca GERCEKTEN kullanilanlar ---------------
# Kullanilmayan tanimlari da yazmak ngspice'i gereksiz mesgul ediyor
# (kolon kod cozucu / mux / bitline evirici blogu ~10k satir).
need, seen = set(l.split()[-1] for l in keep), set()
while need - seen:
    n = (need - seen).pop()
    seen.add(n)
    for l in B.get(n, [])[1:]:
        if l.startswith("X"):
            sub = l.split()[-1]
            if sub in B:
                need.add(sub)
defs = []
for name in seen:
    if name in (TOP, ARRAY):
        continue
    ls = B[name]
    defs.append("\n".join(fix_units(l) if l.startswith("X") else l for l in ls))
    defs.append(".ends")
defs = "\n".join(defs)

keep_fixed = "\n".join(fix_units(l) for l in keep)

# --- on-sarjli KOD COZUCU zincir dugumleri: baslangic sarti --------------
# Satir kod cozucu de NAND-zinciri yapisinda; zincir ici dugumlerin toprakla
# DC yolu yok. uic ile hepsi 0'dan baslayinca ngspice zaman adimini
# kucultup pes ediyordu ("Timestep too small ... rom_base_one_cell_53/s",
# 2026-09-06). clk_int dusukken dogru fiziksel durum ON-SARJLI olmak;
# kolon olcumundeki `.ic v(bl)={VDD}` ile ayni cozum.
ic_nodes = [n for n in
            (l.split()[1:-1] for l in keep if l.split()[-1].endswith("row_decode"))
            for n in n
            if re.search(r"rom_base_(one|zero)_cell_\d+/[SD]$", n)
            or re.search(r"/bl_\d+_\d+$", n)]
ic_txt = "\n".join(f".ic v({n})={{VDD}}" for n in sorted(set(ic_nodes)))

# --- ON UC GECIKMESI: clk0 -> precharge / wordline -----------------------
# .lib'deki `access` clk0 yukselen kenarindan dout0 gecerli olana kadardir.
# Kolon olcumu (t_dis_50) ise TRIG'i ic `precharge` agindan aliyor, yani
# clk0'dan precharge/wordline'a kadar olan kisim HIC sayilmamisti.
# Burada olculur; toplam:  access = max(t_clk2pre, t_clk2wl) + t_dis_50
#                                   + t_bl2dout (gen_backend_delay_tb.py)
ctl = set(next(l for l in keep if l.split()[-1].endswith("control_logic"))
          .split()[1:-1])
rowd = set(next(l for l in keep if l.split()[-1].endswith("row_decode"))
           .split()[1:-1])
arrn = set(arr_inst[0].split()[1:-1])
supplies = {SUPPLY_HI, SUPPLY_LO, "0", "clk0", "cs0"}
clk_int = sorted(ctl & rowd - supplies)
pre_net = sorted(ctl & arrn - supplies)
wl_meas = [n for k in range(8)
           for n in rowd if re.search(r"/wl_%d$" % k, n)]
# RISE=N kullanilamaz: ngspice her sinyalin gecislerini t=0'dan AYRI
# sayiyor, ic dugumler baslangicta glitch atinca clk0'in 2. yukselisiyle
# hedefin 2. yukselisi ayni cevrime denk gelmiyordu (negatif gecikme
# cikiyordu, 2026-09-06). Bunun yerine ZAMAN PENCERESI (TD) ile 2. clk
# kenarindan hemen once basliyoruz; hem trig hem targ o kenarin ilk
# gecisini yakalar. 2. cevrim secildi: devre 1. cevrimde oturuyor.
_tclk = to_float(args.tclk)
_edge = (args.cycles - 2) * _tclk        # olculecek clk0 yukselen kenari
_td_trig = _edge - _tclk / 20.0
# TARG penceresi TAM kenardan basliyor: kod cozucu on-sarjli oldugu icin
# wordline'lar clk0'in DUSEN kenarinda da yukseliyor (on-sarj fazi). TARG
# icin TD'yi kenardan once verince olcum o dusus-kenari yukselisini
# yakalayip NEGATIF gecikme uretiyordu (2026-09-06: t_clk2wl = -99 ns).
_td_targ = _edge
fe = []
def _m(name, node):
    pad = " " * len(name)
    return [f".measure tran {name} TRIG v(clk0) VAL='VDD/2' RISE=1 "
            f"TD={_td_trig:.6e}",
            f"+                {pad}TARG v({node}) VAL='VDD/2' RISE=1 "
            f"TD={_td_targ:.6e}"]
if clk_int:
    fe += _m("t_clk2int", clk_int[0])
# Hangi wordline'in secildigi adres kodlamasina bagli ve Magic'in urettigi
# isimlerden okunamiyor; ilk sekiz wordline olculur, clk0'in YUKSELEN
# kenarindan sonra yukselen HANGISIYSE secilen odur (digerleri icin olcum
# "failed" doner, bu beklenen ve bilgi verici bir sonuctur).
# Kod cozucunun POLARITESI dogrudan olculur: on-sarj fazinda (clk0 dusuk)
# butun wordline'lar yukseliyorsa, degerlendirme fazinda SECILMEYEN satirlar
# duser ve secilen zaten yuksek kalir. Bu durumda clk0 yukselen kenarindan
# sonra wordline'da YUKSELEN kenar HIC olmaz -- ve kolon olcumunun
# "wordline'lar DC yuksek" varsayimi DOGRU demektir; on uc terimi yalnizca
# clk0 -> precharge olur. Hem yukselis hem dusus olculuyor ki bu cikarim
# varsayim degil KANIT olsun.
for k, n in enumerate(wl_meas):
    fe += _m(f"t_clk2wl{k}", n)
    pad = " " * len(f"t_wlfall{k}")
    fe += [f".measure tran t_wlfall{k} TRIG v(clk0) VAL='VDD/2' RISE=1 "
           f"TD={_td_trig:.6e}",
           f"+                {pad}TARG v({n}) VAL='VDD/2' FALL=1 "
           f"TD={_td_targ:.6e}"]
if pre_net and args.cs:
    # cs0=0 iken precharge hic yukselmez -- olcum yalnizca cs0=1'de anlamli
    fe += _m("t_clk2pre", pre_net[0])

# --- adres bitleri ve gecis ani (hem olcum hem uyaran kullanir) -----------
# 13 sabiti kaldirildi: makro word_size=4 ile 11 bit adresle uretiliyor,
# pin sayisi LEF'ten gelen top_ports'tan turetiliyor.
_abits = sorted(int(mm.group(1))
                for p_ in top_ports
                for mm in [re.match(r"addr0\[(\d+)\]$", p_)] if mm)
# Olculen clk0 yukselen kenari _edge + TCLK/2'de; ondan onceki ON-SARJ fazi
# [_edge, _edge+TCLK/2]. Adres o fazin ortasinda gecirilir -> kenardan
# TCLK/4 once, kod cozucunun oturmasi icin bol zaman.
_t_sw = _edge + _tclk / 4.0

# --- SETUP: addr0 -> kod cozucu -------------------------------------------
# Kod cozucu ON-SARJLI: on-sarj fazinda butun wordline'lar yukselir,
# evaluate'te SECILMEYENLER duser. Dolayisiyla adres, clk0 yukselirken kod
# cozucunun GIRISLERINDE oturmus olmali. Olculen sey tam olarak bu yol:
#     addr0 -> inv_array_mod (adres tamponu) -> pbuf_dec (on-kod cozucu)
# Bu, .lib'deki setup_rising'in fiziksel karsiligidir. Olculmeden once
# BASE'deki 0.15 ns analitik tahmini kullaniliyordu (bkz. gen_rom_lib.py).
if args.addr_alt is not None:
    _sw_bits = [i for i in _abits
                if ((args.addr >> i) & 1) != ((args.addr_alt >> i) & 1)]
    if _sw_bits:
        _trig_pin = f"addr0[{_sw_bits[0]}]"
        _td = _t_sw - _tclk / 40.0        # gecisten hemen once basla

        def _ms(name, node):
            pad = " " * len(name)
            return [f".measure tran {name} TRIG v({_trig_pin}) VAL='VDD/2' "
                    f"CROSS=1 TD={_td:.6e}",
                    f"+                {pad}TARG v({node}) VAL='VDD/2' "
                    f"CROSS=1 TD={_td:.6e}"]

        # HEDEF: kod cozucu NAND'inin A girisi. Netlist yapisi:
        #     X..._nand2_dec_N  gnd vdd  <A>  clk  <Z>  <ic>
        # yani adres, tampondan DOGRUDAN saatli NAND'a giriyor; arada ayri
        # bir on-kod cozucu kati yok. Adresin kararli olmasi gereken son
        # nokta bu A netidir -- setup'in fiziksel karsiligi.
        #
        # wordline tamponu girisleri (pbuf_dec) HEDEF DEGIL: kod cozucu
        # on-sarjli oldugu icin on-sarj fazinda tum wordline'lar yuksek ve
        # adres degisince hic kipirdamiyorlar (olcum "failed" doner).
        # rom_address_control_buf'in yapisi (netlistten):
        #     addr0 -> inv_array_mod/Z -> nand2_dec(A=inv/Z, clk) -> A_out
        # yani inv_array_mod'un Z'si ZATEN kod cozucu NAND'inin A girisidir.
        # Adres bit basina bir tampon var; HEPSI olculur ve en kotusu alinir.
        _samp = sorted(n for n in rowd if re.search(r"inv_array_mod_\d+/Z$", n))
        for _k, _n in enumerate(_samp):
            fe += _ms(f"t_addr2dec{_k}", _n)
fe_txt = "\n".join(fe)
caps_txt = "\n".join(kept_c)
loads_txt = "\n".join(load_lines)

# --- uyaran ---------------------------------------------------------------
if args.addr_alt is None:
    addr_src = "\n".join(
        f"Vaddr{i} addr0[{i}] 0 DC {{{'VDD' if (args.addr >> i) & 1 else '0'}}}"
        for i in _abits)
else:
    # Gecis 100 ps -- uyaranin kendisi olculen gecikmeye girmesin.
    _lines = []
    for i in _abits:
        a = (args.addr >> i) & 1
        b = (args.addr_alt >> i) & 1
        if a == b:
            _lines.append(f"Vaddr{i} addr0[{i}] 0 DC {{{'VDD' if a else '0'}}}")
        else:
            v0 = "{VDD}" if a else "0"
            v1 = "{VDD}" if b else "0"
            _lines.append(
                f"Vaddr{i} addr0[{i}] 0 PWL(0 {v0} {_t_sw:.6e} {v0} "
                f"{_t_sw + 100e-12:.6e} {v1})")
    addr_src = "\n".join(_lines)
cs_val = "{VDD}" if args.cs else "0"
mode = "AKTIF (cs0=1)" if args.cs else "BOSTA (cs0=0)  -->  when : \"!cs0\""
wl_n = sum(1 for p, c, w in load_report if re.match(r"^wl_", p))
cells = sum(c for p, c, w in load_report if re.match(r"^wl_", p))

tb = f"""* {M} -- CEVRE BIRIMI cevrim enerjisi -- {mode}
* Tutulan: rom_control_logic (saat surucu + control_nand + prechg surucu)
*          rom_row_decode    (adres tamponu + kod cozucu + wl tamponlari)
* Silinen: hucre dizisi / kolon mux / kolon kod cozucu / bitline+cikis
*          eviricileri. Dizinin YUKU geri konuldu:
*            {wl_n} wordline, toplam {cells} hucre kapisi (tek ornek + m=<adet>)
*            + dizi ici parazitik tel C (lump)
* Ust seviye C: {len(kept_c)} korundu/toplandi, {n_drop} atildi (iki ucu da olu),
*               {clamped} negatif toplam sifirlandi (Magic alt-taban duzeltmesi)
* Negatif NET kapasitans duzeltmesi: {n_fix} dugum, toplam {c_fix_tot*1e15:.1f} fF
* cs0={args.cs}: {'precharge anahtarlanir' if args.cs else 'precharge SABIT 0 -- yalnizca clk_int agaci calisir'}
* Enerji FREKANSTAN BAGIMSIZ olmali; --tclk degistirip dogrulayin.

.lib /home/hpw/OpenLane/pdks/sky130A/libs.tech/ngspice/sky130.lib.spice {args.corner}
.temp {args.temp}
.param VDD={args.vdd}
.param TCLK={args.tclk}

* Besleme SABIT. Rampa denendi ve KALDIRILDI: asagidaki .ic zincir
* dugumlerini VDD'de baslatiyor; besleme ayni anda 0'dan tirmaninca
* baslangic durumu KENDI ICINDE TUTARSIZ oluyor (dugum 1.8 V, kaynak 0 V)
* ve cozucu t~1e-11'de patliyordu (2026-09-06, dort ayri secenek setinde).
Vvdd {SUPPLY_HI} 0 DC {{VDD}}
Vgnd {SUPPLY_LO} 0 DC 0
Vcs cs0 0 DC {cs_val}
* Kenar 500 ps: 100 ps'lik basamak bu buyuklukteki agda yakinsamayi
* zorluyordu. Yarim periyot 100 ns oldugu icin AKTARILAN YUK (= enerji)
* kenar suresinden etkilenmez.
Vclk clk0 0 PULSE(0 {{VDD}} {{TCLK/2}} 500p 500p {{TCLK/2-500p}} {{TCLK}})
{addr_src}

* --- cevre birimi ornekleri (parazitikli, cikarilan netlistten aynen) ---
{keep_fixed}

* --- kod cozucu zincir dugumleri on-sarjli baslar ({len(set(ic_nodes))} dugum) ---
{ic_txt}

* --- silinen hucre dizisinin yuku (dilim x adet) ---
{loads_txt}

* --- ust seviye parazitik C ---
{caps_txt}

* --- alt-devre tanimlari ---
{defs}

* abstol: sizinti olcumundeki 1e-15 BURADA GEREKMEZ (olculen akimlar uA
* mertebesinde) ve yakinsamayi zorlastiriyor.
.options gmin=1e-12 abstol=1e-12 reltol=1e-3 itl1=500 itl4=100
* uic SART: on-sarjli kod cozucunun ic dugumlerinin DC yolu yok; .op
* yakinsamiyor (2026-09-06'da denendi -- 10 dk sonra hala calisma
* noktasindaydi). Kolon olcumunde de ayni sebeple uic kullaniliyor.
.tran '{args.tclk}/{args.steps}' '{args.cycles}*TCLK' uic
* SON IKI cevrim ayri olculur: esit cikmalari devrenin OTURDUGUNU gosterir
* (uic ile tum dugumler 0'dan basliyor). cs0=1'de on-sarj agi cok agir
* yuklu oldugu icin 4 cevrim YETMIYORDU -- 2026-09-06'da c2/c3 farki
* %30'a kadar cikti; bu yuzden olcum penceresi --cycles ile birlikte
* kayiyor ve varsayilan cevrim sayisi buyutuldu.
.measure tran q_c2 integ i(Vvdd) from='{args.cycles - 3}*TCLK' to='{args.cycles - 2}*TCLK'
.measure tran q_c3 integ i(Vvdd) from='{args.cycles - 2}*TCLK' to='{args.cycles - 1}*TCLK'
.measure tran e_periph_pj param='abs(q_c3)*VDD*1e12'

* --- on uc gecikmesi (access'in ilk terimi) ---
{fe_txt}
.end
"""
open(args.out, "w").write(tb)
print(f"yazildi: {args.out}  ({M}, cs0={args.cs}, kose={args.corner}, "
      f"{wl_n} wordline / {cells} hucre kapisi, {len(kept_c)} C)")
