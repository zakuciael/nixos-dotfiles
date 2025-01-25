# Generates NixOS systems using configuration found in the hosts/ directory.
{
  self,
  lib,
  inputs,
  withSystem,
  ...
}:
let
  mkHost =
    system: hostname:
    withSystem system (
      {
        self',
        inputs',
        ...
      }:
      lib.nixosSystem {
        specialArgs = {
          inherit system;
          inherit hostname;

          inputs' = inputs' // {
            self = self';
          };
          inputs = inputs // {
            inherit self;
          };
          pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system}; # Adds `nixos-unstable` channel to module arguments
        };

        modules = [
          # External modules
          # TODO: Add external modules

          # Host specific configuration
          ./../../hosts/${hostname}/configuration.nix

          # Base configuration
          ./../../hosts/base/configuration.nix
          ./../../hosts/base/networking.nix
        ];
      }
    );
in
{
  flake.nixosConfigurations = {
    pc = mkHost "x86_64-linux" "pc";
    laptop = mkHost "x86_64-linux" "laptop";
  };
}
