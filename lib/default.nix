# Credits for portions of this code goes here: https://github.com/Wittano/nix-dotfiles/
{
  lib,
  system,
  inputs,
  username,
  pkgs,
  unstable,
  ...
}: let
  mapper = import ./mapper.nix {inherit lib pkgs;};
  imports = import ./imports.nix {inherit lib;};

  dotfiles = mapper.mapDirToAttrs ./../dotfiles;
  scripts = mapper.mapDirToAttrs ./../scripts;
in {
  inherit imports pkgs unstable mapper scripts;

  hosts = import ./hosts.nix {inherit lib system pkgs unstable inputs imports username dotfiles scripts;};
  apps = import ./apps.nix {inherit lib pkgs unstable username dotfiles scripts;};
}
