# Toolchain Requirements & Environment Setup

Complete guide to required EDA tools, Nix environment provisioning, local environment variables, and pre-flight validation for `openram-rom-libgen`.

[<- back to the README](../README.md)

---

## Contents

1. [Required Tools & Versions](#1-required-tools--versions)
   - [Toolchain Table](#toolchain-table)
   - [ngspice with KLU Solver Requirement](#ngspice-with-klu-solver-requirement)
   - [Magic Extraction Prerequisite](#magic-extraction-prerequisite)
2. [Setting Up the Environment](#2-setting-up-the-environment)
   - [Option A: Nix Environment (Recommended)](#option-a-nix-environment-recommended)
   - [Option B: Manual / Host Installation](#option-b-manual--host-installation)
   - [Environment Variables Reference](#environment-variables-reference)
3. [Cleaning Up Nix Storage & Caches](#3-cleaning-up-nix-storage--caches)
4. [Pre-Flight Verification](#4-pre-flight-verification)

---

## 1. Required Tools & Versions

There are **no Python packages to install**: every script uses the Python standard library only, so there is no `requirements.txt` and nothing to install via `pip`. What the characterization flow and validation testsuite require are five external EDA tools and the Sky130 PDK:

### Toolchain Table

| Tool | Version / Requirement | Role in Flow | Without It |
|---|---|---|---|
| `python3` | 3.10+ (modern type hinting) | Generates testbenches, runs flow CLI, parses logs, builds `.lib` and `.sv` | Nothing runs |
| `ngspice` | Compiled with **KLU** | Every SPICE simulation and transient measurement | KLU-less builds or legacy SPARSE fallback results are rejected; no `.lib` can be produced |
| `magic` | 8.3.450+ | Step 1 parasitic capacitance extraction (`run_cap_extract.sh`) | No `<macro>_cap_only.spice`, preventing column deck generation (can be skipped if pre-extracted) |
| `iverilog` / `vvp` | Modern release | Behavioural simulation of generated `.sv` models in testsuite | Verilog validation layer skips in testsuite |
| `OpenSTA` (`sta`) | Modern release | Reads and verifies every generated Liberty file with an industry-standard consumer parser | Liberty validation layer skips in testsuite unless strict mode (`ROM_TESTS_STRICT=1`) is set |
| `sky130 PDK` | SkyWater 130nm PDK | BSIM4 transistor model cards for ngspice at TT, SS, FF corners | Simulation decks cannot evaluate transistor behavior |
| `OpenRAM Technology` | OpenRAM tech repo | Layer definitions and extraction rules for Magic | `run_cap_extract.sh` fails when extracting layout from scratch |

### ngspice with KLU Solver Requirement

Circuit netlists containing long series chains (such as a 134-transistor ROM bitline) create highly sparse, non-symmetric matrices. Standard SPICE sparse matrix solvers (legacy SPARSE) suffer from severe numerical instability, convergence failures, and dramatic slowdowns on these topologies.

The flow strictly requires ngspice compiled with the **SuiteSparse KLU direct linear solver**:
* Verify your local build:
  ```bash
  ngspice --version | grep -i klu
  # Must report: "Compiled with KLU Direct Linear Solver"
  ```
* Every generated SPICE deck includes `.options klu`.
* The testbench runner inspects simulation logs and verifies the presence of `"Using KLU as Direct Linear Solver"`. Any fallback to legacy SPARSE causes an immediate exit with an error.
* The included Nix shell automatically compiles and validates ngspice with KLU enabled.

### Magic Extraction Prerequisite

Full-macro resistance extraction in Magic causes segmentation faults on large cell arrays due to shorted `zero_cell` straps. Consequently, Magic is configured for distributed capacitance extraction only:
```tcl
ext2spice rthresh infinite
ext2spice extresist off
```
Per-cell wire resistance is modeled analytically and injected into critical path decks separately (see [docs/limitations.md](limitations.md)).

---

## 2. Setting Up the Environment

### Option A: Nix Environment (Recommended)

If you have Nix installed, the repository provides fully reproducible environments where `python3`, `ngspice` (with KLU), `magic`, `iverilog`, and `OpenSTA` are pinned and configured automatically.

Enter the shell from the repository root:

```bash
# Using modern Nix Flakes (recommended, requires no channels):
nix develop

# Using classic Nix:
nix-shell
```

**What the Nix shell does for you:**
1. Provisions all required binaries on your `$PATH`.
2. Automatically scans standard paths for an existing SkyWater 130nm PDK and exports `PDK_ROOT`. If not found, it warns you to export `PDK_ROOT` manually.
3. Automatically sets `ROM_MACROS_DIR=$(pwd)/user` and `ROM_OUT_DIR=$(pwd)/output`.
4. Wraps `ngspice` to enforce KLU verification.

> [!NOTE]
> **First-run compilation of OpenSTA:**
> Most tools are downloaded instantly from `cache.nixos.org`. However, OpenSTA is compiled from source during the first launch. This takes several minutes initially; once compiled, it remains permanently cached in `/nix/store` and re-entering the shell takes only 2–3 seconds.

---

### Option B: Manual / Host Installation

If you prefer using tools installed directly on your operating system:

1. Ensure `python3` (>=3.10), `ngspice` (with KLU), `magic`, `iverilog`, and `sta` are in your `$PATH`.
2. Export the required paths in your terminal:
   ```bash
   export PDK_ROOT=$HOME/OpenLane/pdks                # Directory containing sky130A/
   export OPENRAM_TECH=$HOME/OpenRAM/technology      # Needed only if extracting layout with Magic
   export ROM_MACROS_DIR=$(pwd)/user                 # Directory where target macros reside
   export ROM_OUT_DIR=$(pwd)/output                  # Output directory for .lib and .sv
   ```

### Environment Variables Reference

| Variable | Default Value | Description |
|---|---|---|
| `PDK_ROOT` | `~/OpenLane/pdks` | Path containing the `sky130A` PDK folder |
| `OPENRAM_TECH` | *None* | Path to OpenRAM technology directory (required for layout extraction) |
| `ROM_MACROS_DIR` | `<repo>/user` (or `<repo>/examples`) | Directory holding macro folders |
| `ROM_OUT_DIR` | `<repo>/output` | Destination directory for `.lib` and `.sv` files |
| `NGSPICE_BIN` | `ngspice` | Path/name of ngspice binary (must have KLU) |
| `MAGIC_BIN` | `magic` | Path/name of Magic VLSI binary |
| `IVERILOG_BIN` | `iverilog` | Path/name of Icarus Verilog compiler |
| `VVP_BIN` | `vvp` | Path/name of Icarus Verilog runtime |
| `STA_BIN` | `sta` | Path/name of OpenSTA binary |
| `JOBS` | `4` in `flow.py` | Maximum parallel ngspice simulations |
| `ROM_JOB_MEM_GB` | `3` | Memory allocation budget per simulation job |
| `ROM_TESTS_STRICT` | `0` | Set to `1` to fail testsuite if OpenSTA or iverilog are missing |

---

## 3. Cleaning Up Nix Storage & Caches

Nix caches downloaded dependencies and build artifacts inside `/nix/store` and `~/.cache/nix`. If you want to reclaim disk space or clean old build profiles:

```bash
# 1. Delete old shell generations and garbage-collect unreferenced packages:
nix-collect-garbage -d

# 2. Hard-link identical store files to optimize disk usage:
nix-store --optimise

# 3. Clear local evaluation cache (optional):
rm -rf ~/.cache/nix

# 4. Remove stale direnv environments (if direnv was used):
rm -rf .direnv
```

`nix-collect-garbage -d` deletes old generations without touching active profiles. Running `nix develop` or `nix-shell` later will restore any needed packages without issue.

---

## 4. Pre-Flight Verification

Before launching a long characterization run, verify that your environment and macro directory are properly configured:

```bash
./flow.py <macro> --check-only
```

This inspects both the machine environment and the macro files:

```text
  tool       status   what it is for
  ✓ python3    the generators
  ✓ ngspice    every measurement
  ✓ sky130     the transistor models
  ✓ magic      parasitic extraction (--with-extract)
  ✓ iverilog   simulates the generated .sv in the testsuite
```

* `✓`: Tool or dependency is ready.
* `⚠`: Tool is missing, but optional for partial runs (e.g. Magic is skipped if `<macro>_cap_only.spice` is already present).
* `✗`: Critical dependency missing; the flow will abort and report what needs to be installed or exported.
