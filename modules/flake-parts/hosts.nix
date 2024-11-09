{
  withSystem,
  inputs,
  ...
}: let
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

        modules = [
          ./../../hosts/${name}/configuration.nix
        ];
      });
in {
  flake.nixosConfigurations = {
    pc = mkHost "pc";
    laptop = mkHost "laptop";
  };
}
