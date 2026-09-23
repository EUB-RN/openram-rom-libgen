# Kullanıcı ROM Klasörü (`user/`)

Kendi OpenRAM ROM makrolarınızı bu klasörün altına yerleştirerek `.lib` (Liberty) ve `.v` (davranışsal Verilog) modellerini otomatik olarak üretebilirsiniz.

---

## 📁 Klasör Yapısı

Her ROM için kendi adıyla bir alt klasör oluşturun:

```text
user/
└── <macro_adı>/
    ├── <macro_adı>.sp           (ZORUNLU: SPICE netlist - geometri ve kritik yol buradan çıkarılır)
    ├── <macro_adı>.lef          (ZORUNLU: LEF dosyası - pin listesi, yönler ve alan bilgisi)
    ├── <macro_adı>.gds          (İSTEĞE BAĞLI: Gerçek parazitik C çıkarımı yapılacaksa gereklidir)
    ├── config/<macro_adı>.py    (İSTEĞE BAĞLI: word_size ve words_per_row çapraz doğrulaması)
    └── rom_configs/
        └── <macro_adı>.bin      (İSTEĞE BAĞLI: ROM içerik dosyası, Verilog model kelime sayısı)
```

> **Örnek:** Eğer makro adınız `rom_1024x32` ise:
> `user/rom_1024x32/rom_1024x32.sp` ve `user/rom_1024x32/rom_1024x32.lef` dosyalarının bulunması yeterlidir.

---

## 🚀 Çalıştırma

### Yöntem A: İzole Nix Ortamı ile (Önerilen)
```bash
# 1. İzole kabuğa girin
nix-shell

# 2. Akışı başlatın
./flow.py <macro_adı>
```

### Yöntem B: Yerel Python ile
```bash
./flow.py <macro_adı>
# veya doğrudan dizin vererek:
./flow.py user/<macro_adı>
```

---

## 📤 Çıktılar (`output/`)

İşlem tamamlandığında çıktılar otomatik olarak `output/` dizinine yazılır:
- **`output/lib/<macro_adı>_TT_1p8V_25C.lib`**: Tipik (TT) köşe Liberty dosyası
- **`output/lib/<macro_adı>_SS_1p6V_100C.lib`**: Yavaş (SS) köşe Liberty dosyası
- **`output/lib/<macro_adı>_FF_1p95V_n40C.lib`**: Hızlı (FF) köşe Liberty dosyası
- **`output/verilog/<macro_adı>.v`**: Ölçülen gerçek gecikmeleri içeren davranışsal Verilog modeli

