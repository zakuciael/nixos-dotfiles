{
  config,
  lib,
  ...
}:
with lib;
with lib.my;
let
  cfg = config.modules.desktop.sddm;
in
{
  options.modules.desktop.sddm = {
    enable = mkEnableOption "SDDM as a display manager";
  };

  config = mkIf cfg.enable {
    services.xserver.enable = true;
    services.displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
        autoNumlock = true;
      };
    };
  };
}
