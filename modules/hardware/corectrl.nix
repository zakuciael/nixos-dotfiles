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

  config = mkIf cfg.enable {
    users.users.${username}.extraGroups = [ "corectrl" ];

    hardware.amdgpu.overdrive = optionalAttrs cfg.overclock {
      enable = true;
      # ppfeaturemask = "";
    };

    programs.corectrl.enable = true;
  };
}
