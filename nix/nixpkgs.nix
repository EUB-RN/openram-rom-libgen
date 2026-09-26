# Where nixpkgs comes from, for people who do NOT have a channel.
#
# shell.nix used to open with `{ pkgs ? import <nixpkgs> {} }`, and `<nixpkgs>`
# is resolved through NIX_PATH -- i.e. through a CHANNEL. A flakes-first Nix
# install (the default for a while now) configures no channels at all, so on a
# fresh machine `nix-shell` died before doing anything:
#
#     error: file 'nixpkgs' was not found in the Nix search path
#
# which reads like a missing dependency and is not one. So: use the channel
# when there is one, and otherwise fall back to the revision flake.nix already
# pins in flake.lock -- the same nixpkgs `nix develop` builds from, so the two
# entry points cannot drift apart.
let
  channel = builtins.tryEval <nixpkgs>;
  locked = (builtins.fromJSON (builtins.readFile ../flake.lock)).nodes.nixpkgs.locked;
in
if channel.success then channel.value
else builtins.fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/${locked.rev}.tar.gz";
  sha256 = locked.narHash;
}
