{
  pkgs,
  lib,
  config,
  inputs,
  system,
  username,
  scripts,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.desktop.hyprland;
  desktopApps = apps.desktopApps config cfg;
  launcherScript = import scripts."rofi-launcher.nix".source {inherit pkgs inputs;};
  powermenuScript = import scripts."rofi-powermenu.nix".source {inherit pkgs inputs;};
  mkSortByPriority = {priority, ...} @ a: {priority, ...} @ b: a.priority < b.priority;
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
in {
  options.modules.desktop.hyprland = {
    enable = mkEnableOption "Enable hyprland desktop";
    autostart.programs = mkOption {
      type = with types;
        listOf (coercedTo str (cmd: {inherit cmd;}) (submodule {
          options = {
            cmd = mkOption {
              type = str;
              description = "A command to execute to start the program";
            };
            once = mkOption {
              type = bool;
              default = true;
              description = "If the program should only be executed on launch";
            };
            priority = mkOption {
              type = int;
              default = 99;
              description = "The priority in which the program should be started";
            };
          };
        }));
      description = "A list of programs to autostart when Hyprland loads";
      default = [];
      example = [
        "${pkgs.discord}/bin/discord"
        {
          cmd = "${pkgs.nitrogen}/bin/nitrogen --restore";
          once = false;
        }
      ];
    };
  };

  config = mkIf (cfg.enable) (mkMerge (with desktopApps; [
    alacritty
    _1password
    rofi
    nh
    waybar
    gtk
    {
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${system}.hyprland;
        xwayland.enable = true;
      };

      home-manager.users.${username} = {
        home.packages = with pkgs; [playerctl];

        imports = [inputs.hyprland.homeManagerModules.default];

        wayland.windowManager.hyprland = {
          enable = true;

          plugins = [
            inputs.hyprsplit.packages.${system}.hyprsplit
          ];

          settings = {
            # Plugins
            plugin = {
              hyprsplit.num_workspaces = workspaceCount;
            };

            # Input settings
            input = {
              kb_layout = config.services.xserver.layout;
            };

            # Autostart programs
            # TODO: Replace by an generated bash script to actually support priority
            "exec-once" = builtins.map (program: program.cmd) (lists.sort mkSortByPriority (builtins.filter (program: program.once) cfg.autostart.programs));
            exec = builtins.map (program: program.cmd) (lists.sort mkSortByPriority (builtins.filter (program: !program.once) cfg.autostart.programs));

            # Keybinds
            "$mod" = "SUPER";
            bind = with pkgs;
              [
                "$mod, return, exec, alacritty"
                "$mod, W, killactive,"
                "$mod, F, togglefloating,"
                "$mod, M, fullscreen, 1"
                "$mod, LEFT, movefocus, l"
                "$mod, RIGHT, movefocus, r"
                "$mod, UP, movefocus, u"
                "$mod, DOWN, movefocus, d"
                ", XF86AudioRaiseVolume, exec, ${wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
                ", XF86AudioLowerVolume, exec, ${wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
                ", XF86AudioMute, exec, ${wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
                ", XF86AudioMicMute, exec, ${wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
                ", XF86AudioPlay, exec, ${playerctl}/bin/playerctl play-pause"
                ", XF86AudioNext, exec, ${playerctl}/bin/playerctl next"
                ", XF86AudioPrev, exec, ${playerctl}/bin/playerctl previous"
                ", XF86audiostop, exec, ${playerctl}/bin/playerctl stop"
                "SHIFT CTRL, space, exec, ${launcherScript}/bin/rofi-launcher drun"
                "SHIFT CTRL, Q, exec, ${powermenuScript}/bin/rofi-powermenu"
              ]
              ++ workspaceBinds;
            bindm = [
              "$mod, mouse:272, movewindow"
              "$mod, mouse:273, resizewindow"
            ];
          };
        };
      };
    }
  ]));
}
