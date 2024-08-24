{
  config,
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
  };
}
