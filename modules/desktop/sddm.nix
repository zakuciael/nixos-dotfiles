{
  pkgs,
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
    services.xserver = {
      enable = true;
      displayManager.sddm = {
        enable = true;
        autoNumlock = true;
      };
    };
  };
}
