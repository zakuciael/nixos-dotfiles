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

          # TODO: Replace this dirty trick when nixos 24.05 releases
          "${unstable.path}/nixos/modules/programs/nh.nix"

          inputs.home-manager.nixosModules.home-manager
        ]
        ++ (imports.importModulesPath ./../modules);
    };
}
