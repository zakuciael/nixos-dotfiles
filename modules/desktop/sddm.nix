{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;

  cfg = config.modules.desktop.sddm;
in
{
  options.modules.desktop.sddm = {
    enable = mkEnableOption "SDDM as a display manager";
    compositor = mkOption {
      description = "Wayland compositor to use";
      type = types.enum [
        "kwin"
        "weston"
      ];
      default = "weston";
    };
  };

  config = mkIf cfg.enable {
    services.displayManager = {
      sddm = {
        enable = true;
        wayland = {
          enable = true;
          inherit (cfg) compositor;
        };
        autoNumlock = true;
      };
    };
  };
}
