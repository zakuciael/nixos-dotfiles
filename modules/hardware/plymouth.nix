{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    ;

  cfg = config.modules.hardware.plymouth;
in
{
  options.modules.hardware.plymouth = {
    enable = mkEnableOption "plymouth splash";
    themePackages = mkOption {
      description = "A list of plymouth themes";
      example = [ pkgs.nixos-blur-plymouth ];
      type = types.listOf types.package;
      default = [ pkgs.nixos-blur-plymouth ];
    };
    theme = mkOption {
      description = "Set plymouth theme";
      example = "nixos-blur";
      type = types.str;
      default = "nixos-blur";
    };
  };

  config = mkIf cfg.enable {
    boot = {
      plymouth = {
        enable = true;
        inherit (cfg) theme themePackages;
      };

      initrd = {
        verbose = false;
        systemd.enable = true;
      };

      consoleLogLevel = 3;
      kernelParams = [
        "quiet"
        "udev.log_level=3"
        "systemd.show_status=auto"
        "rd.udev.log_level=3"
        "vt.global_cursor_default=0"
      ];
    };
  };
}
