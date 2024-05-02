{
  config,
  lib,
  inputs,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.services.wallpaper;
  home = config.home-manager.users.${username};
in {
  options.modules.services.wallpaper = {
    enable = mkEnableOption "wallpaper config";
    settings = mkOption {
      description = "Per-monitor wallpaper settings";
      example = [
        {
          monitor = {
            xorg = "DisplayPort-0";
            wayland = "DP-1";
          };
          wallpaper = "$HOME/Pictures/Wallpapers/anime_cat_girl.png";
        }
      ];
      type = with types;
        listOf (submodule {
          options = {
            monitor = defs.monitor;
            wallpaper = mkOption {
              description = "Path to the wallpaper.";
              example = "$HOME/Pictures/Wallpapers/tropical_storm_dante.png";
              type = path;
            };
          };
        });
    };
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = mkMerge [
      # Enable this config only if Hyprland is enabled
      # TODO: Update this configuration when nix-community/home-manager#5344 is merged and lands in a stable release
      (optionalAttrs config.programs.hyprland.enable {
        xdg.configFile."hypr/hyprpaper.conf" = {
          text = mapper.toHyprconf {
            attrs = {
              ipc = "off";
              preload = builtins.map (x: ''${x.wallpaper}'') cfg.settings;
              wallpaper = builtins.map (x: ''${x.monitor.wayland},${x.wallpaper}'') cfg.settings;
            };
            importantPrefixes = ["$"];
          };
        };

        systemd.user.services."hyprpaper" = {
          Unit = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
            Description = "hyprpaper";
            After = ["graphical-session-pre.target"];
            PartOf = ["graphical-session.target"];
            X-Restart-Triggers = ["${home.xdg.configFile."hypr/hyprpaper.conf".source}"];
          };
          Service = {
            ExecStart = "${getExe inputs.hyprpaper.default}";
            Restart = "always";
            RestartSec = "10";
          };
          Install = {
            WantedBy = ["graphical-session.target"];
          };
        };
      })
    ];
  };
}
