{
  config,
  lib,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.yubikey;
  hmConfig = config.home-manager.users.${username};
  configDirectory = hmConfig.xdg.configHome;
in {
  options.modules.hardware.yubikey = {
    enable = mkEnableOption "YubiKey support";
    interactive = mkEnableOption "interactive prompt";
  };

  config = mkIf (cfg.enable) {
    sops.secrets = {
      "users/${username}/u2f_keys" = {
        mode = "0644";
        owner = username;
        path = "${configDirectory}/Yubico/u2f_keys";
      };
    };

    security.pam = {
      u2f = {
        enable = true;
        cue = true;
        interactive = cfg.interactive;
        control = "sufficient";
      };

      services = {
        login.u2fAuth = false;
        sudo.u2fAuth = true;
      };
    };
  };
}
