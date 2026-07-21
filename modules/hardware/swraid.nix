{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    getExe
    ;

  cfg = config.modules.hardware.swraid;
in
{
  options.modules.hardware.swraid = {
    enable = mkEnableOption "support for Linux MD RAID arrays.";
    notify-package = mkOption {
      type = types.package;
      description = "Program to use to send notification about the RAID array status";
      default = pkgs.mdadm-notify;
      example = "pkgs.mdadm-notify";
    };
  };

  config = mkIf cfg.enable {
    boot.swraid = {
      enable = true;
      mdadmConf = ''
        PROGRAM ${getExe cfg.notify-package}
      '';
    };
  };
}
