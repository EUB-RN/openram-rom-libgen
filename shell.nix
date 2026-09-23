{ pkgs ? import <nixpkgs> {} }:

let
  # Standart Sky130 PDK arama yolları
  findPdkScript = ''
    if [ -z "$PDK_ROOT" ]; then
      if [ -d "$HOME/.volare/volare/sky130/versions" ]; then
        LATEST_VOLARE=$(ls -td "$HOME/.volare/volare/sky130/versions"/* 2>/dev/null | head -n1)
        if [ -n "$LATEST_VOLARE" ] && [ -d "$LATEST_VOLARE/sky130A" ]; then
          export PDK_ROOT="$LATEST_VOLARE"
        fi
      elif [ -d "$HOME/OpenLane/pdks/sky130A" ]; then
        export PDK_ROOT="$HOME/OpenLane/pdks"
      elif [ -d "/usr/local/share/pdk/sky130A" ]; then
        export PDK_ROOT="/usr/local/share/pdk"
      fi
    fi

    if [ -n "$PDK_ROOT" ] && [ -z "$SKY130_LIB" ]; then
      if [ -f "$PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice" ]; then
        export SKY130_LIB="$PDK_ROOT/sky130A/libs.tech/ngspice/sky130.lib.spice"
      fi
    fi
  '';

in pkgs.mkShell {
  name = "openram-rom-libgen-env";

  buildInputs = with pkgs; [
    python3
    ngspice
    iverilog
  ];

  shellHook = ''
    ${findPdkScript}

    # user/ dizininde en az bir makro varsa varsayılan olarak user/ dizinini seç
    if [ -d "./user" ] && [ -n "$(find ./user -mindepth 1 -maxdepth 1 -type d 2>/dev/null)" ]; then
      export ROM_MACROS_DIR="$(pwd)/user"
    else
      export ROM_MACROS_DIR="$(pwd)/user"
    fi
    export ROM_OUT_DIR="$(pwd)/output"
    export NGSPICE_BIN="${pkgs.ngspice}/bin/ngspice"

    echo "=================================================================="
    echo "  openram-rom-libgen İzole Nix Ortamı Hazır!"
    echo "=================================================================="
    echo "  * Girdi Dizini (ROM): $ROM_MACROS_DIR"
    echo "  * Çıktı Dizini      : $ROM_OUT_DIR"
    if [ -n "$SKY130_LIB" ]; then
      echo "  * Sky130 PDK Modeli : $SKY130_LIB"
    else
      echo "  ! UYARI: Sky130 PDK otomatik bulunamadı. Lütfen PDK_ROOT tanımlayın."
    fi
    echo ""
    echo "  Kullanım:"
    echo "    1. Kendi ROM dosyalarınızı './user/<rom_adı>/' altına koyun."
    echo "    2. Tek komutla çalıştırın:"
    echo "       ./flow.py <rom_adı>"
    echo "       veya doğrudan: ./flow.py (user altındaki ilk ROM'u işler)"
    echo "    3. Çıktılar './output/lib/' ve './output/verilog/' altına yazılır."
    echo "=================================================================="
  '';
}

