{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.services.upower;
in
{
  options.modules.services.upower = {
    enable = mkEnableOption "Upower service configuration";
  };

  config = mkIf cfg.enable {
    services.upower = {
      enable = true;
      usePercentageForPolicy = true;
      percentageLow = 20; # Battery getting low
      percentageCritical = 5; # Consider charging the battery
      percentageAction = 2; # If you dont plug it in, it will die
    };
  };
}
