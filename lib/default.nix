{
  lib,
  system,
  inputs,
  ...
}: let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
  imports = import ./imports.nix {inherit lib;};
  home-manager = inputs.home-manager;
in {
  inherit imports pkgs;

  hosts = import ./hosts.nix {inherit lib system pkgs inputs imports;};
  apps = import ./apps.nix {inherit lib home-manager pkgs;};
}
