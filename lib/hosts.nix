{
  lib,
  system,
  pkgs,
  inputs,
  imports,
  ...
}: {
  mkHost = {name}:
    inputs.nixpkgs.lib.nixosSystem rec {
      inherit system;

      specialArgs = {
        inherit pkgs lib inputs;
        hostname = name;
      };

      modules =
        [
          ./../configuration.nix
          ./../hosts/${name}/configuration.nix

          inputs.home-manager.nixosModules.home-manager
        ]
        ++ (imports.importModulesPath ./../modules);
    };
}
