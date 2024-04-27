{
  lib,
  system,
  pkgs,
  unstable,
  dotfiles,
  scripts,
  inputs,
  imports,
  username,
  mapper,
  ...
}: {
  mkHost = {name}:
    inputs.nixpkgs.lib.nixosSystem rec {
      inherit system;

      specialArgs = {
        inherit pkgs unstable lib dotfiles scripts inputs username system mapper;
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
