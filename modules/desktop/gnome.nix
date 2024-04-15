{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.desktop.gnome;
  desktopApps = apps.desktopApps config cfg;
in {
  options.modules.desktop.gnome = {
    enable = mkEnableOption "Enable Gnome desktop";
  };

  config = mkIf (cfg.enable) (mkMerge (with desktopApps; [
    _1password
    alacritty
    rofi
    {
      services.xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };
    }
  ]));
}
