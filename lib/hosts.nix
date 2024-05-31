{
  lib,
  pkgs,
  unstable,
  inputs,
  username,
  dotfiles,
  scripts,
  ...
}:
with lib.my; {
  mkHost = {name}:
    inputs.nixpkgs.lib.nixosSystem {
      inherit (pkgs) system;

      specialArgs = {
        inherit lib pkgs unstable inputs username dotfiles scripts;
        hostname = name;
      };

      modules =
        [
          ./../configuration.nix
          ./../hosts/${name}/configuration.nix

          inputs.home-manager.nixosModules.default
          inputs.sops-nix.nixosModules.default
          inputs.stylix.nixosModules.default
          inputs.catppuccin.nixosModules.default
        ]
        ++ (utils.recursiveReadDir ./../modules {
          ignoredDirs = ["apps"];
          suffixes = ["nix"];
        });
    };
}
