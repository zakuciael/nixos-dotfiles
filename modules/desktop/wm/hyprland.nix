{
  config,
  lib,
  pkgs,
  inputs,
  username,
  scripts,
  ...
}:
with lib;
with lib.my; let
  launcherScript = import scripts."rofi-launcher.nix".source {inherit pkgs inputs;};
  powermenuScript = import scripts."rofi-powermenu.nix".source {inherit pkgs inputs;};
  workspaceCount = 9;
  workspaceBinds = lib.flatten (builtins.genList (i: let
      x = i + 1;
      ws = "${toString x}";
    in [
      # Default
      "$mod, ${ws}, split:workspace, ${ws}"
      "$mod SHIFT, ${ws}, split:movetoworkspace, ${ws}"
      # Numpad
      "$mod, ${mapper.mapKeyToNumpad x}, split:workspace, ${ws}"
      "$mod SHIFT, ${mapper.mapKeyToNumpad x}, split:movetoworkspace, ${ws}"
    ])
    workspaceCount);
in
  desktop.mkDesktopModule {
    inherit config;

    name = "hyprland";
    autostartPath = ".config/hypr/autostart.sh";
    desktopApps = [
      "alacritty"
      "_1password"
      "rofi"
      "nh"
      "waybar"
      "gtk"
    ];

    extraOptions = with lib; {
      monitorBinds = mkOption {
        type = with types;
          listOf (submodule {
            options = {
              monitor = mkOption {
                type = str;
                description = "A name of the monitor output";
                example = "DP-1";
              };
              key = mkOption {
                type = str;
                description = "A key used for the monitor keybind";
                example = "KP_End";
              };
            };
          });
        default = [];
        example = [
          {
            monitor = "DP-1";
            key = "KP_End";
          }
        ];
      };
    };

    extraConfig = {
      cfg,
      autostartScript,
      colorScheme,
      ...
    }: let
      monitorBinds = lib.flatten (builtins.map (config: [
          # Focus monitor
          "$mod ALT, ${config.key}, focusmonitor, ${config.monitor}"
          # Move to monitor
          "$mod ALT SHIFT, ${config.key}, movewindow, mon:${config.monitor}"
        ])
        cfg.monitorBinds);
    in {
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.hyprland;
        xwayland.enable = true;
      };

      home-manager.users.${username} = {
        home.packages = with pkgs; [playerctl];

        wayland.windowManager.hyprland = {
          enable = true;

          plugins = [inputs.hyprsplit.default];

          settings = {
            # Autostart script
            exec-once = autostartScript;

            # Plugins
            plugin = {
              hyprsplit.num_workspaces = workspaceCount;
            };

            # Input settings
            input = {
              kb_layout = config.services.xserver.layout;
              follow_mouse = 2;
            };

            # General settings
            general = with colorScheme.palette; {
              gaps_in = 6;
              gaps_out = 8;
              border_size = 3;
              "col.active_border" = "rgba(${base0C}ff) rgba(${base0D}ff) rgba(${base0B}ff) rgba(${base0E}ff) 45deg";
              "col.inactive_border" = "rgba(${base00}cc) rgba(${base01}cc) 45deg";
              layout = "dwindle";
              resize_on_border = true;
            };

            # Decoration settings
            decoration = {
              rounding = 10;
              drop_shadow = false;
              blur = {
                enabled = true;
                size = 5;
                passes = 3;
                new_optimizations = true;
                ignore_opacity = true;
              };
            };

            # Animation settings
            animations = {
              enabled = true;
              bezier = [
                "wind, 0.05, 0.9, 0.1, 1.05"
                "winIn, 0.1, 1.1, 0.1, 1.1"
                "winOut, 0.3, -0.3, 0, 1"
                "liner, 1, 1, 1, 1"
              ];
              animation = [
                "windows, 1, 6, wind, slide"
                "windowsIn, 1, 6, winIn, slide"
                "windowsOut, 1, 5, winOut, slide"
                "windowsMove, 1, 5, wind, slide"
                "border, 1, 1, liner"
                "borderangle, 1, 80, liner, loop"
                "fade, 1, 10, default"
                "workspaces, 1, 5, wind"
              ];
            };

            # Layout settings
            dwindle = {
              pseudotile = true;
              preserve_split = true;
            };

            master = {
              new_is_master = true;
            };

            # Keybinds
            "$mod" = "SUPER";
            bind =
              [
                "$mod, return, exec, alacritty"
                "$mod, W, killactive,"
                "$mod, F, togglefloating,"
                "$mod, M, fullscreen, 1"
                "$mod, LEFT, movefocus, l"
                "$mod, RIGHT, movefocus, r"
                "$mod, UP, movefocus, u"
                "$mod, DOWN, movefocus, d"
                "SHIFT CTRL, space, exec, ${launcherScript}/bin/rofi-launcher drun"
                "SHIFT CTRL, Q, exec, ${powermenuScript}/bin/rofi-powermenu"
              ]
              ++ workspaceBinds
              ++ monitorBinds;

            bindl = with pkgs; [
              ", XF86AudioRaiseVolume, exec, ${wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
              ", XF86AudioLowerVolume, exec, ${wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
              ", XF86AudioMute, exec, ${wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
              ", XF86AudioMicMute, exec, ${wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
              ", XF86AudioPlay, exec, ${playerctl}/bin/playerctl play-pause"
              ", XF86AudioNext, exec, ${playerctl}/bin/playerctl next"
              ", XF86AudioPrev, exec, ${playerctl}/bin/playerctl previous"
              ", XF86audiostop, exec, ${playerctl}/bin/playerctl stop"
            ];
            bindm = [
              "$mod, mouse:272, movewindow"
              "$mod, mouse:273, resizewindow"
            ];
          };
        };
      };
    };
  }
