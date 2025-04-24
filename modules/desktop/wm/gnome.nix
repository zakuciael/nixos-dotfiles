{
  config,
  lib,
  ...
}:
with lib;
with lib.my;
  desktop.mkDesktopModule {
    inherit config;

    name = "gnome";
    desktopApps = [
      "_1password"
      "alacritty"
      "rofi"
    ];

    extraConfig = {
      services.xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };
    };
  }
