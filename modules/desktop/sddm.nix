{
  config,
  lib,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.desktop.sddm;
in {
  options.modules.desktop.sddm = {
    enable = mkEnableOption "SDDM as a display manager";
  };

  config = mkIf (cfg.enable) {
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
