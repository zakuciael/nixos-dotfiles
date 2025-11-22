{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.my;
let
  cfg = config.modules.hardware.peripherals;
in
{
  options.modules.hardware.peripherals = {
    enable = mkEnableOption "Keychron peripherals configuration";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ qmk ];

    hardware.keyboard.qmk = {
      enable = true;
      keychronSupport = true;
    };
  };
}
