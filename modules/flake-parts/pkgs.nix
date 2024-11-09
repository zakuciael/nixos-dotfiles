# Generates "packages" flake output using configuration found in the pkgs/ directory.
{
  perSystem = {pkgs, ...}: let
    pathToPackage = path: attrs: pkgs.callPackage (./../../pkgs + builtins.toPath "/${path}") attrs;
  in {
    packages.nixos-blur-plymouth = pathToPackage "nixos-blur-plymouth" {};
    packages.controlvault2-nfc-enable = pathToPackage "controlvault2-nfc-enable" {};
  };
}
