{
  lib,
  pkgs,
  unstable,
  inputs,
  username,
  system,
  ...
}: let
  utils = import ./utils.nix {inherit lib;};
  mapper = import ./mapper.nix {inherit lib pkgs;};
  defs = import ./defs.nix {inherit lib;};

  dotfiles = mapper.mapDirToAttrs ./../dotfiles;
  scripts = import ./scripts.nix {inherit lib pkgs unstable inputs username dotfiles;};
in {
  inherit utils mapper defs;

  hosts = import ./hosts.nix {inherit lib pkgs unstable inputs username dotfiles scripts;};
  desktop = import ./desktop.nix {inherit lib pkgs unstable inputs username dotfiles scripts;};
  overlays = import ./overlays.nix {inherit lib pkgs unstable inputs system;};
}
