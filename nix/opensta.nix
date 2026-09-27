# OpenSTA is not packaged as a standalone executable in the pinned nixpkgs.
# Keep it here so local development and CI use the same parser and version.
{
  lib,
  stdenv,
  fetchFromGitHub,
  swig,
  pkg-config,
  cmake,
  gnumake,
  flex,
  bison,
  tcl,
  tclreadline,
  cudd,
  zlib,
  eigen,
  ninja,
}:

stdenv.mkDerivation (finalAttrs: {
  name = "opensta";

  # This revision reports OpenSTA 2.7.0. The source hash makes updates an
  # explicit review rather than following an upstream branch implicitly.
  src = fetchFromGitHub {
    owner = "The-OpenROAD-Project";
    repo = "OpenSTA";
    rev = "857316ff001b2a8dbbdc5996944d08a6d38c87ab";
    hash = "sha256-4lxyNQeBTx+bIEM4RVZzG4UU/ilv9sjFFUcB5S4Evgw=";
  };

  patches = [
    ./patches/opensta/fix_cell_delays.patch
  ];

  postPatch = ''
    # The upstream BUILD file is for Bazel and interferes with this CMake
    # build; OpenSTA's own Nix consumers remove it for the same reason.
    rm -f BUILD
  '';

  cmakeFlags = [
    "-DBUILD_TESTS=OFF"
    "-DTCL_LIBRARY=${tcl}/lib/libtcl${stdenv.hostPlatform.extensions.sharedLibrary}"
    "-DTCL_HEADER=${tcl}/include/tcl.h"
  ];

  nativeBuildInputs = [
    swig
    pkg-config
    cmake
    gnumake
    flex
    bison
    ninja
  ];

  buildInputs = [
    cudd
    tclreadline
    eigen
    tcl
    zlib
  ];

  meta = {
    description = "Gate-level static timing verifier";
    homepage = "https://github.com/The-OpenROAD-Project/OpenSTA";
    mainProgram = "sta";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
