{
  lib,
  pkgs,
  inputs,
  username,
  dotfiles,
  scripts,
  ...
}:
with lib.my;
{
  mkHost =
    { name }:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit
          lib
          pkgs
          inputs
          username
          dotfiles
          scripts
          ;
        hostname = name;
      };

      modules = [
        ./../configuration.nix
        ./../hosts/${name}/configuration.nix
        "${inputs.nixpkgs}/nixos/modules/misc/nixpkgs/read-only.nix"

        inputs.home-manager.nixosModules.default
        inputs.sops-nix.nixosModules.default
        inputs.catppuccin.nixosModules.default
        inputs.aagl.nixosModules.default
        inputs.vscode-server.nixosModules.default
        inputs.disko.nixosModules.disko
        inputs._1pass-shell-plugins.nixosModules.default
        inputs.nix-index-database.nixosModules.default
        inputs.steam-presence.nixosModules.steam-presence
      ]
      ++ (utils.recursiveReadDir ./../modules {
        ignoredDirs = [ "apps" ];
        suffixes = [ "nix" ];
      });
    };
}
