# Generates "packages" flake output using configuration found in the pkgs/ directory.
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        nixos-blur-plymouth = pkgs.callPackage ./../../pkgs/nixos-blur-plymouth { };
        controlvault2-nfc-enable = pkgs.callPackage ./../../pkgs/controlvault2-nfc-enable { };
        httpie-desktop = pkgs.callPackage ./../../pkgs/httpie-desktop { };
      };
    };
}
