{
  config,
  lib,
  pkgs,
  username,
  scripts,
  ...
}:
with lib;
with lib.my; let
  scriptPackages = scripts.mkScriptPackages config;
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
      "qt"
      "grimblast"
      "steam"
      "btop"
      "bat"
    ];

    extraConfig = {
      cfg,
      autostartScript,
      colorScheme,
      ...
    }: {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };

      # Make chrome and electron apps run native on wayland
      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      xdg.portal.extraPortals = with pkgs; [xdg-desktop-portal-gtk];

      home-manager.users.${username} = {
        # TODO: Move this and media controls to an app config for a player script
        home.packages = with pkgs; [playerctl];

        wayland.windowManager.hyprland = {
          enable = true;
          xwayland.enable = true;

          settings = {
            # Autostart script
            exec-once = [autostartScript];

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
            bind = [
              "$mod, return, exec, alacritty"
              "$mod, W, killactive,"
              "$mod, F, togglefloating,"
              "$mod, M, fullscreen, 1"
              "$mod, LEFT, movefocus, l"
              "$mod, RIGHT, movefocus, r"
              "$mod, UP, movefocus, u"
              "$mod, DOWN, movefocus, d"
              "SHIFT CTRL, space, exec, ${scriptPackages.rofi-launcher}/bin/rofi-launcher drun"
              "SHIFT CTRL, R, exec, ${scriptPackages.rofi-launcher}/bin/rofi-launcher jetbrains"
              "SHIFT CTRL, Q, exec, ${scriptPackages.rofi-powermenu}/bin/rofi-powermenu"
            ];

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

            windowrulev2 = [
              # -- Fix odd behaviors in IntelliJ IDEs --
              #! Fix focus issues when dialogs are opened or closed
              "windowdance,class:^(jetbrains-.*)$,floating:1"
              #! Fix splash screen showing in weird places and prevent annoying focus takeovers
              "center,class:^(jetbrains-.*)$,title:^(splash)$,floating:1"
              "nofocus,class:^(jetbrains-.*)$,title:^(splash)$,floating:1"
              "noborder,class:^(jetbrains-.*)$,title:^(splash)$,floating:1"

              #! Center popups/find windows
              "center,class:^(jetbrains-.*)$,title:^( )$,floating:1"
              "stayfocused,class:^(jetbrains-.*)$,title:^( )$,floating:1"
              "noborder,class:^(jetbrains-.*)$,title:^( )$,floating:1"
              #! Disable window flicker when autocomplete or tooltips appear
              "nofocus,class:^(jetbrains-.*)$,title:^(win.*)$,floating:1"
            ];
          };
        };
      };
    };
  }
