{
  lib,
  config,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.keyring;
in {
  options.modules.hardware.keyring = {
    enable = mkEnableOption "Enable GNOME keyring";
  };

  config = mkIf (cfg.enable) {
    security.pam.services.login.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;
  };
}
