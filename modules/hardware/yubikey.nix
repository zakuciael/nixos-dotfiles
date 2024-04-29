{
  config,
  lib,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.yubikey;
in {
  options.modules.hardware.yubikey = {
    enable = mkEnableOption "Enable authentication via YubiKeys";
  };

  config = mkIf (cfg.enable) {
    # TODO: Add ~/.config/Yubico/u2f_keys to repo when secret managment is in place

    security.pam = {
      u2f = {
        enable = true;
        cue = true;
        control = "sufficient";
      };

      services = {
        login.u2fAuth = false;
        sudo.u2fAuth = true;
      };
    };
  };
}
