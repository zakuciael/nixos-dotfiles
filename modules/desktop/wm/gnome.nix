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
    services = {
      displayManager.gdm.enable = true;
      xserver = {
        enable = true;
        desktopManager.gnome.enable = true;
      };
    };
  };
}
