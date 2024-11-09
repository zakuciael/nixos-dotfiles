{
  lib,
  self,
  inputs,
  withSystem,
  ...
}: let
  inherit (lib) mkMerge optionalAttrs hasAttr;

  mkHost = name:
    withSystem "x86_64-linux" ({
      self',
      inputs',
      system,
      ...
    }:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inputs = inputs';
          custom = self'.packages;
          hostname = name;
        };

        modules = mkMerge [
          (optionalAttrs (hasAttr "default" self.overlays) {nixpkgs.overlays = [self.overlays.default];})

          ./../../hosts/${name}/configuration.nix
        ];
      });
in {
  flake.nixosConfigurations = {
    pc = mkHost "pc";
    laptop = mkHost "laptop";
  };
}
