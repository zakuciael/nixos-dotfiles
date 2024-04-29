# Credits for portions of this code goes here: https://github.com/Wittano/nix-dotfiles/
{
  lib,
  pkgs,
  unstable,
  inputs,
  username,
  ...
}: let
  imports = import ./imports.nix {inherit lib;};
  mapper = import ./mapper.nix {inherit lib pkgs;};

  dotfiles = mapper.mapDirToAttrs ./../dotfiles;
  scripts = mapper.mapDirToAttrs ./../scripts;
in {
  inherit imports mapper;

  hosts = import ./hosts.nix {inherit lib pkgs unstable inputs username dotfiles scripts;};
  apps = import ./apps.nix {inherit lib pkgs unstable inputs username dotfiles scripts;};
}
