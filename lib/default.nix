# Credits for portions of this code goes here: https://github.com/Wittano/nix-dotfiles/
{
  lib,
  system,
  inputs,
  username,
  ...
}: let
  mapper = import ./mapper.nix {inherit lib pkgs;};
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
  imports = import ./imports.nix {inherit lib;};
  home-manager = inputs.home-manager;
in {
  inherit imports pkgs mapper;

  hosts = import ./hosts.nix {inherit lib system pkgs inputs imports username;};
  apps = import ./apps.nix {inherit lib home-manager pkgs username;};
}
