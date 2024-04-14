{
  config,
  pkgs,
  ...
}: {
  imports = [./hardware.nix ./networking.nix];

  modules = {
    desktop = {
      apps.enable = true;
      gnome.enable = true;
    };
    dev.git.enable = true;
  };
}
