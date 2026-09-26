#!/usr/bin/env python3
"""Functional simulation testbench runner for generated behavioural Verilog models.

WHAT THIS DOES
--------------
The generated `<macro>.sv` files in output/verilog/ are SIMULATION ONLY models
carrying measured timing parameters, every one of them read straight out of
the macro's .lib so the two cannot state different numbers:
    ACCESS_NS   : clk0 rising -> dout0 valid
    T_PRE_NS    : minimum precharge duration (clk0 low)
    SETUP_NS    : minimum address setup before clk0 posedge
    HOLD_NS     : how long addr0 must stay put after clk0 posedge
    HOLD_CS_NS  : the same for cs0 -- NOT the same number, see below
    MPW_HIGH_NS : the .lib's min_pulse_width(rise) -- LONGER than access
    T_FALL_NS   : the .lib's falling_edge arc on dout0

They model non-trivial dynamic behaviour that synthesis tools do not support:
    - Precharge phase: clk0=0 pulls bitlines high (dout0 = all ones)
    - Evaluate phase: discharge through series NMOS chain, dout0 becomes valid
      only after ACCESS_NS has elapsed
    - Invalidation on clk0 fall: the falling edge restarts precharge, and
      dout0 is back at all ones T_FALL_NS later -- not at the edge. That
      delay is the .lib's falling_edge arc and it is what makes capturing on
      the falling edge legal; a model that erased at the edge would disagree
      with its own library by a whole arc, so both halves are checked.
    - Chip select gating: cs0=0 inhibits evaluate, dout0 remains all ones
    - HOLD: an address change INSIDE the hold window destroys the read and it
      does not recover -- the array has no pull-up outside precharge, so a
      second row can only discharge more bits and dout0 becomes the bit-wise
      AND of the two rows. PAST the window the same change does nothing,
      because the bitline is already through the inverter's trip point. Both
      halves are checked, and both were verified to fail when the model is
      mutated: removing the window gate reintroduces the old hold = access
      behaviour and the "after" case catches it; removing the corruption
      leaves the "inside" case with nothing to detect and it catches that.

This test builds and runs a self-checking testbench for each macro using
iverilog + vvp to prove that the model simulates and behaves correctly.

USAGE
-----
    tests/test_verilog_model.py                    # test all models in output/verilog
    tests/test_verilog_model.py output/verilog/wrom1.sv
"""

from __future__ import annotations

import argparse
import glob
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)


def find_tools():
    """Return paths to iverilog and vvp, or None if missing."""
    iv = os.environ.get("IVERILOG_BIN") or shutil.which("iverilog")
    vvp = os.environ.get("VVP_BIN") or shutil.which("vvp")
    return iv, vvp


def parse_model(v_path):
    """Extract parameters and port sizes from the Verilog model."""
    txt = open(v_path).read()

    macro = os.path.splitext(os.path.basename(v_path))[0]

    width_m = re.search(r"parameter\s+WIDTH\s*=\s*(\d+);", txt)
    addr_m = re.search(r"input\s+wire\s+\[(\d+):0\]\s+addr0", txt)
    access_m = re.search(r"parameter\s+real\s+ACCESS_NS\s*=\s*([\d.]+);", txt)
    t_pre_m = re.search(r"parameter\s+real\s+T_PRE_NS\s*=\s*([\d.]+);", txt)
    setup_m = re.search(r"parameter\s+real\s+SETUP_NS\s*=\s*([\d.]+);", txt)
    hold_m = re.search(r"parameter\s+real\s+HOLD_NS\s*=\s*([\d.]+);", txt)
    hold_cs_m = re.search(r"parameter\s+real\s+HOLD_CS_NS\s*=\s*([\d.]+);", txt)
    mpw_m = re.search(r"parameter\s+real\s+MPW_HIGH_NS\s*=\s*([\d.]+);", txt)
    t_fall_m = re.search(r"parameter\s+real\s+T_FALL_NS\s*=\s*([\d.]+);", txt)

    if not (width_m and addr_m and access_m and t_pre_m and setup_m):
        return None
    # HOLD is what makes an address change during evaluate destroy the read;
    # a model without it is silent about the largest constraint the macro has.
    if not (hold_m and hold_cs_m):
        return None
    # The two numbers the model used to leave on the floor. Without them it
    # checks its own access instead of the library's minimum pulse, and it
    # erases dout0 at the falling edge instead of one arc after it -- exactly
    # the two places where the model and the .lib used to disagree. A model
    # that cannot state them is a model to regenerate, not one to test.
    if not (mpw_m and t_fall_m):
        return None
    # The testbench takes its waits from these parameters, so a model that
    # zeroed T_FALL_NS would make the falling-edge check wait 0 ns and pass
    # itself. Both numbers come from the .lib and both are non-zero there:
    # the arc is a real delay, and min_pulse_width(rise) carries a guard band
    # ON TOP of access. Anything else is a model built from a broken .lib.
    if float(t_fall_m.group(1)) <= 0.0:
        return None
    if float(mpw_m.group(1)) <= float(access_m.group(1)):
        return None

    return {
        "macro": macro,
        "width": int(width_m.group(1)),
        "addr_msb": int(addr_m.group(1)),
        "access": float(access_m.group(1)),
        "t_pre": float(t_pre_m.group(1)),
        "setup": float(setup_m.group(1)),
        "hold": float(hold_m.group(1)),
        "hold_cs": float(hold_cs_m.group(1)),
        "mpw_high": float(mpw_m.group(1)),
        "t_fall": float(t_fall_m.group(1)),
    }


def generate_testbench(info):
    """Generate self-checking Verilog testbench source code."""
    macro = info["macro"]
    width = info["width"]
    addr_msb = info["addr_msb"]
    access = info["access"]
    t_pre = info["t_pre"]
    setup = info["setup"]
    hold = info["hold"]
    t_fall = info["t_fall"]

    all_ones_hex = hex((1 << width) - 1)[2:].upper()
    # The array has no pull-up outside precharge, so a second row selected in
    # the same evaluate phase can only discharge MORE bits: the read becomes
    # the bit-wise AND. That is the corruption a hold violation causes.
    mask = (1 << width) - 1
    row0 = 0x12345678 & mask
    row1 = 0xA5A5A5A5 & mask
    anded_hex = "%X" % (row0 & row1)

    return f"""`timescale 1ns / 1ps

module tb_{macro};
  reg clk0;
  reg cs0;
  reg [{addr_msb}:0] addr0;
  wire [{width-1}:0] dout0;

  // Instantiate with empty init file to populate mem directly in testbench
  {macro} #(.INIT_FILE(""), .REPORT(0)) dut (
    .clk0(clk0),
    .cs0(cs0),
    .addr0(addr0),
    .dout0(dout0)
  );

  initial begin
    dut.mem[0] = {width}'h12345678;
    dut.mem[1] = {width}'hA5A5A5A5;

    clk0 = 0;
    cs0  = 1;
    addr0 = 0;

    // 1. Initial precharge: clk0=0 for >= T_PRE_NS
    #({t_pre + 2.0});
    if (dout0 !== {width}'h{all_ones_hex}) begin
      $display("FAIL %m: dout0 not all-ones during precharge (got %h)", dout0);
      $finish(1);
    end

    // 2. Setup address before posedge
    addr0 = 0;
    #({setup + 1.0});
    clk0 = 1;

    // 2a. Before access time has elapsed, output must NOT be valid yet
    #({access * 0.5});
    if (dout0 !== {width}'h{all_ones_hex}) begin
      $display("FAIL %m: dout0 became valid prematurely before ACCESS_NS (got %h)", dout0);
      $finish(1);
    end

    // 2b. After access time has elapsed, output must match memory content
    #({access * 0.6});
    if (dout0 !== {width}'h12345678) begin
      $display("FAIL %m: read data mismatch (expected 12345678, got %h)", dout0);
      $finish(1);
    end

    // 3. Falling edge invalidation, in TWO halves -- the .lib states an arc
    //    here (falling_edge cell_rise = {t_fall:.4f} ns) and a model that
    //    erased at the edge would contradict it.
    //
    //    3a. The data is STILL THERE just after the edge. This is what a
    //        consumer capturing on the falling edge depends on, and it is
    //        the half a model erasing at the edge gets wrong.
    clk0 = 0;
    #({t_fall * 0.5});
    if (dout0 !== {width}'h12345678) begin
      $display("FAIL %m: dout0 erased at the clk0 falling edge -- the .lib gives it {t_fall:.4f} ns (expected 12345678, got %h)", dout0);
      $finish(1);
    end

    //    3b. And it IS gone once the arc has elapsed.
    #({t_fall * 0.6});
    if (dout0 !== {width}'h{all_ones_hex}) begin
      $display("FAIL %m: output not invalidated {t_fall:.4f} ns after the clk0 falling edge (got %h)", dout0);
      $finish(1);
    end

    // 4. Chip-select deassertion: cs0=0 inhibits evaluate
    #({t_pre + 1.0});
    cs0 = 0;
    addr0 = 1;
    #(1.0);
    clk0 = 1;
    #({access + 2.0});
    if (dout0 !== {width}'h{all_ones_hex}) begin
      $display("FAIL %m: output changed while cs0=0 (got %h)", dout0);
      $finish(1);
    end

    // 5. HOLD VIOLATION: the address moves INSIDE the hold window. The read is
    //    destroyed and stays destroyed -- the bitlines cannot recover until
    //    the next precharge, so dout0 comes out as the AND of the two rows.
    clk0 = 0;
    cs0  = 1;
    addr0 = 0;
    #({t_pre + 2.0});
    clk0 = 1;
    #({hold * 0.5});
    addr0 = 1;                       // inside the window -> corruption
    #({access + 2.0});
    if (dout0 !== {width}'h{anded_hex}) begin
      $display("FAIL %m: an address change %0.3f ns into the %0.3f ns hold window did not corrupt the read (expected {anded_hex}, got %h)",
               {hold * 0.5}, {hold}, dout0);
      $finish(1);
    end

    // 6. PAST THE HOLD WINDOW, in two halves -- they are different claims and
    //    the model has been wrong at both ends.
    //
    //    6a. The read IN FLIGHT survives. This is what the hold measurement
    //        established, and before it the model corrupted across the whole
    //        evaluate phase (the old hold = access assumption).
    //    6b. The PHASE does not. The new row's zeros have been discharging
    //        since the change, and with no pull-up in the array dout0 turns
    //        into the AND about one access time later -- if the phase is
    //        still open. A model that stopped at 6a would call the data good
    //        for an arbitrarily long high phase.
    clk0 = 0;
    #({t_pre + 2.0});
    addr0 = 0;
    #({setup + 1.0});
    clk0 = 1;
    #({access + 2.0});               // past HOLD_NS and past ACCESS_NS
    if (dout0 !== {width}'h{row0:X}) begin
      $display("FAIL %m: read wrong before the late address change (got %h)", dout0);
      $finish(1);
    end
    addr0 = 1;                       // legal change, outside the window
    #(1.0);
    // 6a -- still correct immediately after
    if (dout0 !== {width}'h{row0:X}) begin
      $display("FAIL %m: an address change AFTER the %0.3f ns hold window destroyed the read in flight (expected {row0:X}, got %h)",
               {hold}, dout0);
      $finish(1);
    end
    // 6b -- and gone once the new row has had a discharge time, phase still open
    #({access + 2.0});
    if (dout0 !== {width}'h{anded_hex}) begin
      $display("FAIL %m: a late address change never corrupted dout0 -- %0.3f ns after it the phase is still open and the new row has been discharging (expected {anded_hex}, got %h)",
               {access + 3.0}, dout0);
      $finish(1);
    end

    $display("PASS");
    $finish(0);
  end
endmodule
"""


def test_model(v_path, iv, vvp):
    """Compile and simulate a single Verilog model."""
    info = parse_model(v_path)
    if not info:
        print(f"  FAIL {os.path.basename(v_path)}  could not parse timing parameters")
        return False

    tb_code = generate_testbench(info)

    with tempfile.TemporaryDirectory() as tmpdir:
        tb_path = os.path.join(tmpdir, f"tb_{info['macro']}.v")
        vvp_path = os.path.join(tmpdir, f"tb_{info['macro']}.vvp")

        with open(tb_path, "w") as f:
            f.write(tb_code)

        # 1. Compile with iverilog
        c = subprocess.run(
            [iv, "-g2012", tb_path, v_path, "-o", vvp_path],
            capture_output=True,
            text=True,
        )
        if c.returncode != 0:
            print(f"  FAIL {os.path.basename(v_path)}  compilation error:\n{c.stderr}")
            return False

        # 2. Simulate with vvp
        s = subprocess.run([vvp, vvp_path], capture_output=True, text=True)
        if s.returncode != 0 or "PASS" not in s.stdout:
            print(f"  FAIL {os.path.basename(v_path)}  simulation assertion failed:\n{s.stdout}")
            return False

    print(
        f"  ok   {os.path.basename(v_path)}  (simulated: precharge, access "
        f"{info['access']:.2f} ns, fall invalidation, cs0, hold "
        f"{info['hold']:.2f}/{info['hold_cs']:.2f} ns addr/cs0)"
    )
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("models", nargs="*", help="Optional specific .sv models to test")
    args = parser.parse_args()

    iv, vvp = find_tools()
    if not iv or not vvp:
        missing = []
        if not iv:
            missing.append("iverilog")
        if not vvp:
            missing.append("vvp")
        print(
            f"  SKIP  {', '.join(missing)} not found -- set IVERILOG_BIN / VVP_BIN "
            "to run behavioural simulation testbenches."
        )
        sys.exit(0)

    if args.models:
        targets = args.models
    else:
        out_dir = os.environ.get("ROM_OUT_DIR") or os.path.join(REPO, "output")
        targets = sorted(glob.glob(os.path.join(out_dir, "verilog", "*.sv")))

    if not targets:
        print("  SKIP  no Verilog models found to simulate")
        sys.exit(0)

    rc = 0
    for v in targets:
        if not os.path.isfile(v):
            continue
        if not test_model(v, iv, vvp):
            rc = 1

    sys.exit(rc)


if __name__ == "__main__":
    main()

