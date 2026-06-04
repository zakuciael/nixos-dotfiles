{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modules.hardware.coolercontrol;
in
{
  options.modules.hardware.coolercontrol = {
    enable = mkEnableOption "an app for monitoring and controling your cooling devices";
  };

  config = mkIf cfg.enable {
    programs.coolercontrol.enable = true;
  };
}
