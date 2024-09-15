{
  config,
  hostname,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.nfc;
in {
  options.modules.hardware.nfc = {
    enable = mkEnableOption "NFC support";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username}.home.packages = with pkgs; [pcsc-tools];

    services.pcscd.enable = true;

    systemd.services = mkIf (hostname == "laptop") {
      "controlvault2-nfc-enable" = {
        description = "Run controlvault2-nfc-enable script on startup";
        wantedBy = ["sleep.target" "default.target"];
        after = ["sleep.target"];
        script = "${getExe pkgs.controlvault2-nfc-enable} on";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
    };
  };
}
