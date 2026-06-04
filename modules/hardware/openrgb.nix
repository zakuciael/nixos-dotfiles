{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption;

  cfg = config.modules.hardware.openrgb;
in
{
  options.modules.hardware.openrgb = {
    enable = mkEnableOption "OpenRGB server, for RGB lighting control.";
  };

  config = {
    services.hardware.openrgb = {
      inherit (cfg) enable;
      package = pkgs.openrgb-with-all-plugins;
    };
  };
}
