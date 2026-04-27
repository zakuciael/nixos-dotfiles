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
        inputs.nixpkgs.nixosModules.readOnlyPkgs

        inputs.home-manager.nixosModules.default
        inputs.sops-nix.nixosModules.default
        inputs.catppuccin.nixosModules.default

        {
          # Importing a full module results in errors due to read-only `nixpkgs.overlays` option.
          inherit (inputs.aagl.nixosModules.default) imports;
        }
        inputs.vscode-server.nixosModules.default
        inputs.disko.nixosModules.disko
        inputs._1pass-shell-plugins.nixosModules.default
        inputs.nix-index-database.nixosModules.default
        inputs.steam-presence.nixosModules.steam-presence
        inputs.determinate.nixosModules.default
      ]
      ++ (utils.recursiveReadDir ./../modules {
        ignoredDirs = [ "apps" ];
        suffixes = [ "nix" ];
      });
    };
}
