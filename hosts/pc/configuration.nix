{
  config,
  pkgs,
  ...
}: {
  imports = [./hardware.nix ./networking.nix];

  # Setup home-manager
  home-manager.users.zakuciael = ./home.nix;

  modules = {
    desktop.apps.enable = true;
    desktop.gnome.enable = true;
    dev.git.enable = true;
  };
}
