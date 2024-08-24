{
  config,
  lib,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.docker;
in {
  options.modules.hardware.docker = {
    enable = mkEnableOption "NFC support";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username}.home.packages = with pkgs; [pcsc-tools];

    services.pcscd.enable = true;
  };
}
