# openram-rom-libgen

OpenRAM ile uretilmis **ROM makrolari** icin otomatik **zamanlama ve guc
karakterizasyonu** ve bundan **Liberty (`.lib`) uretimi**.

OpenRAM'in kendi characterizer'i yalnizca SRAM icin `.lib` yazar; ROM
derleyicisi sadece `.sp` / `.v` / `.lef` / `.gds` uretir. Bu depo o boslugu
doldurur: makronun kendi netlistinden testbench'ler uretir, ngspice ile uc
kosede olcer ve sentez/STA'nin okuyabilecegi `.lib` (+ davranissal `.v`)
dosyalarini yazar.

Sayilarin hicbiri elle girilmez; hepsi olcum log'larindan okunur.

---

## Nasil calisir (kisa hikaye)

Makro on-sarjli, NAND-tipi (seri zincirli) bir ROM:

```
clk0 = 0  ->  bitline'lar VDD'ye on-sarj edilir, dout0 tumu 1
clk0 = 1  ->  kod cozucu acilir, secili hucreler bitline'i bosaltir
```

Cikista mandal yoktur; `dout0` yalnizca `clk0`'in yuksek fazinda gecerlidir.
Bu yuzden `.lib`'deki `access` uc terimin toplamidir ve ucu de ayri olculur:

| # | terim | ne | nereden |
|---|---|---|---|
| 1 | on uc | `clk0` -> `precharge` | `char/periph_active_<kose>.log` (`t_clk2pre`) |
| 2 | bitline | on-sarj -> bitline %50 | `char/col<N>_worst_case_parasitic*.log` (`t_dis_50`) |
| 3 | arka uc | bitline -> `dout0` | `char/backend_<kose>_<yuk>.log` (`t_bl2dout`) |

Ayrica olculenler: `t_pre` (on-sarj suresi, `t_pre_99`), cikis egimi
(`t_dout_slew`, uc yuk noktasinda), setup (`t_addr2dec*`), sizinti (`.op`),
kolon enerjisi ve cevre birimi enerjisi (aktif + bosta).

Butun olcumler **gercek Magic parazitik kapasitansi** ile ve her kose kendi
sky130 modeliyle (`tt`/`ss`/`ff`) **ayri ayri** kosulur -- sabit derating
carpani kullanilmaz.

### Olceklenebilirlik numarasi

34 bin hucrelik dizi hicbir zaman butun halinde simule edilmez:

* **kolon dilimi** -- en kotu kolon izole edilip olculur, sonuc kolon
  sayisiyla carpilir (sizinti, enerji);
* **cevre birimi** -- dizi silinir, wordline yuku (hucre kapisi adedi +
  parazitik tel C) lump kapasitans olarak geri konur.

Boylece kosum suresi makro buyudukce patlamaz.

---

## Boyuttan bagimsizlik

ROM yeniden uretildiginde (`word_size`, `words_per_row` veya `.bin`
degisince) **hicbir betigi elle duzenlemeniz gerekmez**. Akisin ihtiyac
duydugu her sey turetilir:

| bilgi | kaynak |
|---|---|
| makro listesi | `<agac>/<makro>/<makro>.sp` dizinleri |
| satir / kolon sayisi | netlist taramasi (`*_rom_base_array` kapsami) |
| en kotu kolon + seri NMOS zinciri | ayni tarama (`one_cell` sayimi) |
| adres / veri genisligi | LEF pinleri (`PIN addr0[..]`, `PIN dout0[..]`) |
| kelime sayisi | `rom_configs/<makro>.bin` boyutu |
| `word_size` / `words_per_row` | `config/<makro>.py` (capraz kontrol) |

Tek dogruluk kaynagi [`scripts/rom_char/rom_paths.py`](scripts/rom_char/rom_paths.py).
Netlist esastir; `config`'teki `word_size*8*words_per_row` netlistteki kolon
sayisiyla uyusmazsa **uyari** verir (sessizce yanlis olcekleme yapmaz), ve
`words_per_row` 2'nin kuvveti degilse adres uzayinin bosluklu olacagini
soyler.

Geometri `<makro>/char/.geometry.json` icinde onbeleklenir ve netlist
degisince kendiliginden tazelenir.

```sh
# ne turetildigini gormek icin
python3 scripts/rom_char/rom_paths.py wrom0
python3 scripts/rom_char/find_worst_column.py      # tum makrolar, tablo halinde
python3 scripts/rom_char/rom_explore.py wrom0      # kolon histogrami
```

---

## Gereksinimler

* Python 3.8+
* **ngspice** (olcum kosumlari icin) -- `NGSPICE_BIN` ile yol verilebilir
* **Magic** 8.3+ (parazitik cikarim icin) -- `MAGIC_BIN`
* sky130 PDK ngspice modelleri -- `PDK_ROOT` veya dogrudan `SKY130_LIB`
* OpenRAM teknoloji agaci (yalnizca cikarim adiminda) -- `OPENRAM_TECH`

Ortam degiskenleri:

| degisken | varsayilan | ne ise yarar |
|---|---|---|
| `ROM_MACROS_DIR` | `<depo>/examples` | makro agaci |
| `NGSPICE_BIN` | `ngspice` | ngspice yolu |
| `MAGIC_BIN` | `magic` | magic yolu |
| `PDK_ROOT` | `~/OpenLane/pdks` | sky130A'nin bulundugu yer |
| `SKY130_LIB` | `$PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice` | model dosyasi |
| `JOBS` | `4` | paralel ngspice kosumu |
| `LOADS` | `1.7225 6.89 27.56` | `.lib` CELL_TABLE cikis yuku noktalari (fF) |
| `ROM_CORNERS` | `tt:1.8:25:38.2 ss:1.6:100:19.1 ff:1.95:-40:60.7` | kose:VDD:sicaklik:fmax(MHz) |

Bir makro dizini soyle gorunmelidir (OpenRAM ciktisi):

```
<makro>/
  <makro>.sp            netlist          (zorunlu -- geometri buradan)
  <makro>.lef           pinler + alan    (zorunlu -- .lib pin listesi)
  <makro>.gds           layout           (parazitik cikarim icin)
  config/<makro>.py     word_size, words_per_row  (istege bagli, capraz kontrol)
  rom_configs/<makro>.bin                (istege bagli, kelime sayisi icin)
  char/                 uretilen deck'ler ve log'lar
```

---

## Akis

```sh
# 0) makrolari gor
python3 scripts/rom_char/rom_paths.py --list

# 1) gercek parazitik C cikarimi (Magic, makro basina bir kez, yavas)
export OPENRAM_TECH=$HOME/OpenRAM/technology
./scripts/rom_char/run_cap_extract.sh wrom0        #  -> wrom0_cap_only.spice

# 2) kolon zamanlamasi: bitline bosalma + on-sarj, uc kose
./scripts/rom_char/run_col_timing.sh               #  -> col<N>_worst_case_parasitic*.log

# 3) arka uc gecikmesi + cikis egimi, uc kose x uc yuk
./scripts/rom_char/run_backend_delay.sh            #  -> backend_<kose>_<yuk>.log

# 4) cevre birimi enerjisi (aktif/bosta) + hucre kapi kapasitansi
JOBS=4 ./scripts/rom_char/run_periphery_power.sh   #  -> periph_{active,idle}_<kose>.log

# 5) adres setup olcumu (4. adimdan sonra -- cellgate log'una ihtiyaci var)
./scripts/rom_char/run_addr_setup.sh               #  -> periph_setup_<kose>.log

# 6) kolon sizintisi ve kolon enerjisi
./scripts/rom_char/run_col_power.sh                #  -> col<N>_leak_<kose>.log
./scripts/rom_char/run_col_energy.sh               #  -> col<N>_energy_<kose>.log

# 7) .lib uret (butun log'lari okur, hicbir sayi elle girilmez)
./scripts/rom_char/regen_rom_libs.sh               #  -> <makro>_<KOSE>.lib  (makro basina 3)

# 8) davranissal Verilog (setup/t_pre ihlallerini simulasyonda bagirir)
python3 scripts/rom_char/gen_macro_behavioral_v.py #  -> <makro>.v
```

Her betik arguman olarak makro adi alir; verilmezse **agactaki tum makrolar**
islenir:

```sh
./scripts/rom_char/run_backend_delay.sh wrom1 wrom2
ROM_MACROS_DIR=/yol/asic/macros ./scripts/rom_char/regen_rom_libs.sh
```

2-6 arasi adimlar birbirinden bagimsizdir (5, 4'e bagli); 7 hepsini ister.
Bir olcum eksikse `regen_rom_libs.sh` o koseyi **atlar ve hangi terimin
eksik oldugunu soyler** -- sessizce tahmin uretmez. Tek istisna setup: log
yoksa `3 x t_clk2pre` kotumser sinirina duser ve bunu ekrana yazar.

---

## Dosyalar

| dosya | is |
|---|---|
| `rom_paths.py` | yol cozumleme + geometri (tek dogruluk kaynagi), CLI |
| `common.sh` | `run_*.sh`'larin ortak tabani: yollar, koseler, `macro_list`, `load_geom`, `meas` |
| `find_worst_column.py` | en kotu kolonu ve seri NMOS zincirini netlistten bulur |
| `rom_explore.py` | dizi yapisi ozeti, kolon histogrami, satir haritasi |
| `run_cap_extract.sh` | Magic ile sadece-C parazitik cikarim |
| `gen_col_tb_parasitic.py` | en kotu kolonun izole testbench'i (graf yuruyusu, isim-bagimsiz) |
| `make_corner_variant.py` | TT deck'inden SS/FF varyanti (devre birebir ayni) |
| `run_col_timing.sh` | yukaridaki ikisini baglar: uc kosede kolon zamanlamasi |
| `gen_backend_delay_tb.py` / `run_backend_delay.sh` | bitline -> `dout0` + cikis egimi, yuke gore |
| `gen_cell_gate_tb.py` | hucre esdeger kapi kapasitansi (`C = Q(VDD)/VDD`) |
| `gen_periphery_power_tb.py` / `run_periphery_power.sh` | cevre birimi enerjisi (cs0=0/1) |
| `run_addr_setup.sh` | `addr0` -> kod cozucu NAND girisi setup olcumu |
| `gen_col_power_tb.py` / `run_col_power.sh` / `run_col_energy.sh` | kolon sizintisi (`.op`) ve kolon enerjisi |
| `gen_rom_lib.py` | LEF + olculen degerler -> Liberty |
| `gen_macro_behavioral_v.py` | zamanlama ihlallerini raporlayan davranissal `.v` |
| `regen_rom_libs.sh` | butun akisi baglayan ust betik |

---

## Yontem notlari (nicin boyle)

* **Enerji, guc degil.** Liberty `internal_power` anahtarlama basina
  ENERJI'dir (pJ); frekansi guc araci uygular. Frekans bagimsizligi deneysel
  olarak dogrulandi (TCLK 200n -> 400n: %3.3 fark).
* **Sizinti `.op` ile olculur**, transient ile degil. `uic`li transient'te
  dugumler sifirdan doluyor ve sarj akimi sizinti sanilip ~100x yuksek
  cikiyordu.
* **`t_pre_99`**, `t_pre_90` degil: %90 geri sarj ~0.5 ns cikarip
  `min_pulse_width(fall)`'i 20x kucuk yaziyordu.
* **Kolon secimi isim eslestirmesiyle degil graf yuruyusuyle.** Magic'in
  cikardigi dugunler otomatik isim tasir (`..._one_cell_17122/D`), sematikteki
  okunabilir isimler degil.
* **En kotu kolon sayimi `*_rom_base_array` kapsamiyla sinirlidir.** Aksi
  halde satir/kolon kod cozucu hucreleri de sayilir; bu, zincir uzunlugunu de
  kolon secimini de yanlis cikarir (2026-09-08'de wrom1/wrom2'de dogrulandi).
* **Wordline yuku m=<adet> ile ciplak cihaz olarak degil, dogrusal C olarak**
  konur: enerji birebir korunur, ngspice de yakinsar.
* **`extresist` kapali** (yalnizca kapasitans): Magic 8.3.629 tum makroyu tek
  seferde direnc cikarirken segfault veriyor.
* **`when : "!cs0"` blogu zorunlu**: `cs0` yalnizca on-sarj yolunu kapatir;
  saat agaci, adres tamponlari ve kod cozucu `cs0`'dan bagimsiz calisir.
  Blok yazilmazsa OpenSTA bosta gucu sessizce 0 sayar.
* **`--measured`**: degerler zaten koseye ait oldugundan `gen_rom_lib.py`
  icindeki derating carpanlari UYGULANMAZ (cift sayim olurdu).

---

## `examples/`

`wrom0`..`wrom3`: sky130 uzerinde uretilmis dort ROM makrosu (1064 kelime x
32 bit, 134 satir x 256 kolon), tum karakterizasyon log'lari ve uretilmis
`.lib` / `.v` dosyalariyla birlikte. Akisi ngspice'siz incelemek ya da bir
degisiklikten sonra `.lib`'leri yeniden uretip ciktiyi karsilastirmak icin
referans olarak kullanilabilir:

```sh
./scripts/rom_char/regen_rom_libs.sh && git diff --stat examples/
```
