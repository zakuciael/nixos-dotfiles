{
  config,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.modules.hardware.graphic-tablet;
in
{
  options.modules.hardware.graphic-tablet = {
    enable = mkEnableOption "Graphic Tablet drivers";
  };

  config = mkIf cfg.enable {
    hardware = {
      opentabletdriver = {
        enable = true;
        daemon.enable = true;
      };
      uinput.enable = true;
    };
  };
}
