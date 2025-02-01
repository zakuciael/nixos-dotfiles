{
  self,
  inputs,
  withSystem,
  ...
}:
let
  mkHostConfiguration =
    system: name:
    withSystem system (
      {
        self',
        inputs',
        ...
      }:
      let
        specialArgs = {
          inherit system;
          hostname = name;
          pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system}; # Adds `nixos-unstable` channel to module arguments

          inputs = inputs // {
            inherit self;
          };
          inputs' = inputs' // {
            self = self';
          };
        };
      in
      inputs.nixpkgs.lib.nixosSystem {
        inherit specialArgs;

        modules = [
          # External modules
          inputs.home-manager.nixosModules.home-manager

          # Home-Manager boilerplate configuration
          {
            home-manager = {
              extraSpecialArgs = specialArgs;
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }

          # Specific configuration
          ./../../hosts/${name}/configuration.nix

          # Base configuration
          ./../../hosts/base/configuration.nix
        ];
      }
    );
in
{
  flake.nixosConfigurations = {
    pc = mkHostConfiguration "x86_64-linux" "pc";
    laptop = mkHostConfiguration "x86_64-linux" "laptop";
  };
}
