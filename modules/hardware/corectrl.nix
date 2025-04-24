{
  config,
  lib,
  username,
  ...
}:
let
  inherit (lib) mkIf optionalAttrs mkEnableOption;
  cfg = config.modules.hardware.corectrl;
in
{
  options.modules.hardware.corectrl = {
    enable = mkEnableOption "CoreCtrl tool";
    overclock = mkEnableOption "overclocking";
  };

  config = mkIf (cfg.enable) {
    users.users.${username}.extraGroups = [ "corectrl" ];

    programs.corectrl = {
      enable = true;
      gpuOverclock = optionalAttrs (cfg.overclock) {
        enable = true;
        # ppfeaturemask = "";
      };
    };
  };
}
