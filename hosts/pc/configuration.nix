{
  config,
  pkgs,
  ...
}: {
  imports = [./hardware.nix ./networking.nix];

  modules = {
    desktop.apps.enable = true;
    desktop.gnome.enable = true;
    dev.git.enable = true;
  };
}
