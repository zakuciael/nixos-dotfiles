{
  config,
  lib,
  username,
  ...
}:
with lib;
with lib.my;
let
  cfg = config.modules.services.wallpaper;
in
{
  options.modules.services.wallpaper = {
    enable = mkEnableOption "wallpaper config";
    settings = mkOption {
      description = "Per-monitor wallpaper settings";
      default = [ ];
      example = [
        {
          monitor = {
            xorg = "DisplayPort-0";
            wayland = "DP-1";
          };
          wallpaper = "$HOME/Pictures/Wallpapers/anime_cat_girl.png";
        }
      ];
      type =
        with types;
        listOf (submodule {
          options = {
            inherit (defs) monitor;
            wallpaper = mkOption {
              description = "Path to the wallpaper.";
              example = "$HOME/Pictures/Wallpapers/tropical_storm_dante.png";
              type = path;
            };
          };
        });
    };
  };

  config = mkIf (cfg.enable && config.programs.hyprland.enable) {
    home-manager.users.${username} = {
      services.hyprpaper = {
        enable = true;
        settings = {
          ipc = false;
          splash = false;
          preload = builtins.map (x: ''${x.wallpaper}'') cfg.settings;
          wallpaper = builtins.map (x: ''${x.monitor.wayland},${x.wallpaper}'') cfg.settings;
        };
        importantPrefixes = [ "$" ];
      };
    };
  };
}
