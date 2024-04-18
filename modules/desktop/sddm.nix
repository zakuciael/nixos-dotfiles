{
  lib,
  config,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.desktop.sddm;
in {
  options.modules.desktop.sddm = {
    enable = mkEnableOption "Enable SDDM as display manager";
  };

  config = mkIf (cfg.enable) {
    security.pam.services.sddm.enableGnomeKeyring = config.services.gnome.gnome-keyring.enable;

    services.xserver = {
      enable = true;
      # TODO: Update this configuration when nixos 24.05 releases
      displayManager.sddm = {
        enable = true;
        autoNumlock = true;
      };
    };
  };
}
