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

      modules =
        [
          ./../configuration.nix
          ./../hosts/${name}/configuration.nix
          "${inputs.nixpkgs}/nixos/modules/misc/nixpkgs/read-only.nix"

          inputs.home-manager.nixosModules.default
          inputs.sops-nix.nixosModules.default
          inputs.catppuccin.nixosModules.default
          inputs.aagl.nixosModules.default
          inputs.vscode-server.nixosModules.default
        ]
        ++ (utils.recursiveReadDir ./../modules {
          ignoredDirs = [ "apps" ];
          suffixes = [ "nix" ];
        });
    };
}
