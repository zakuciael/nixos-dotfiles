{
  config,
  pkgs,
  ...
}: {
  imports = [./hardware.nix ./networking.nix];

  modules = {
    hardware = {
      grub.enable = true;
    };
    desktop = {
      apps.enable = true;
      gnome.enable = true;
    };
  };
}
