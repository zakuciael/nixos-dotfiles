{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.desktop.gnome;
in {
  options.modules.desktop.gnome = {
    enable = mkEnableOption "Enable Gnome desktop";
  };

  config = mkIf (cfg.enable) {
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };
  };
}
