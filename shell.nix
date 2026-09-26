# nix/nixpkgs.nix uses the <nixpkgs> channel when one exists and falls back to
# the revision pinned in flake.lock when it does not -- so `nix-shell` works on
# a flakes-first install with no channels configured, which is where
# `import <nixpkgs>` used to fail with "file 'nixpkgs' was not found in the Nix
# search path". flake.nix passes `pkgs` in explicitly and never reaches this.
{ pkgs ? import (import ./nix/nixpkgs.nix) {} }:

let
  # The usual places a sky130 PDK lands, in the order they are tried.
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
    # Step 1 of the flow (run_cap_extract.sh) is a Magic extraction, and
    # docs/flow.md lists Magic 8.3+ as a requirement. Without it this shell
    # cannot run the flow it advertises -- every later deck needs the
    # <macro>_cap_only.spice that step writes.
    #
    # The attribute is magic-vlsi, NOT magic. nixpkgs has no `magic` at all
    # (only magic-enum, magicrescue and friends), so `magic` here was an
    # undefined variable and BOTH entry points died on it:
    #
    #     error: undefined variable 'magic' at shell.nix:42:5
    #
    # and they died at evaluation time, i.e. after fetching nixpkgs and before
    # building anything -- which is why it looked like a download problem.
    magic-vlsi
  ];

  shellHook = ''
    ${findPdkScript}

    # This shell is for running YOUR OWN ROM, so the macro tree is user/ --
    # see user/README.md. The examples in examples/ are study material and are
    # not what someone entering this shell means to characterise; point
    # ROM_MACROS_DIR at them by hand to work on those instead.
    export ROM_MACROS_DIR="$(pwd)/user"
    export ROM_OUT_DIR="$(pwd)/output"
    export NGSPICE_BIN="${pkgs.ngspice}/bin/ngspice"

    echo "=================================================================="
    echo "  openram-rom-libgen isolated Nix environment ready"
    echo "=================================================================="
    echo "  * macro tree (ROM): $ROM_MACROS_DIR"
    echo "  * output root     : $ROM_OUT_DIR"
    if [ -n "$SKY130_LIB" ]; then
      echo "  * sky130 models   : $SKY130_LIB"
    else
      echo "  ! WARNING: no sky130 PDK found. Set PDK_ROOT before running."
    fi
    echo ""
    echo "  Usage:"
    echo "    1. Put your own ROM under './user/<macro>/'."
    echo "    2. Run it in one command:"
    echo "       ./flow.py <macro>"
    echo "       or ./flow.py on its own, which processes EVERY macro"
    echo "       found under user/."
    echo "    3. Deliverables land in './output/lib/' and './output/verilog/'."
    echo "=================================================================="
  '';
}

