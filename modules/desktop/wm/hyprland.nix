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
  hmConfig = config.home-manager.users.${username};
in
  desktop.mkDesktopModule {
    inherit config;

    name = "hyprland";
    autostartPath = ".config/hypr/autostart.sh";
    desktopApps = [
      "alacritty"
      "kitty"
      "_1password"
      "rofi"
      "nh"
      "waybar"
      "gtk"
      "qt"
      "grimblast"
      "vesktop"
      "swaync"
      "thunderbird"
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

      xdg.portal = {
        extraPortals = with pkgs; [xdg-desktop-portal-gtk];
        xdgOpenUsePortal = true;
      };

      home-manager.users.${username} = {
        wayland.windowManager.hyprland = {
          enable = true;
          xwayland.enable = true;

          settings = {
            # Autostart script
            exec-once = [
              autostartScript
            ];
            # Source external file for quick debug
            source = ["$HOME/.config/hypr/debug.conf"];

            # Input settings
            input = {
              kb_layout = config.services.xserver.xkb.layout;
              follow_mouse = 2;
              float_switch_override_focus = 0;
              mouse_refocus = false;
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
              no_focus_fallback = true;
            };

            # Misc settings
            misc = {
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
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
              new_status = "master";
            };

            # Layer rules
            layerrule = [
              "blur, swaync-control-center"
              "blur, swaync-notification-window"
              "ignorezero, swaync-control-center"
              "ignorezero, swaync-notification-window"
              "ignorealpha 0.5, swaync-control-center"
              "ignorealpha 0.5, swaync-notification-window"
            ];

            # Keybinds
            "$mod" = "SUPER";
            bind = [
              "$mod, return, exec, ${getExe hmConfig.programs.kitty.package}"
              "$mod, W, killactive,"
              "$mod, F, togglefloating,"
              "$mod, M, fullscreen, 1"
              "$mod, LEFT, movefocus, l"
              "$mod, RIGHT, movefocus, r"
              "$mod, UP, movefocus, u"
              "$mod, DOWN, movefocus, d"
              "$mod, KP_Subtract, exec, ${getExe scriptPackages.elgato-mic-fix}"
              "SHIFT CTRL, space, exec, ${getExe scriptPackages.rofi-launcher} drun"
              "SHIFT CTRL, R, exec, ${getExe scriptPackages.rofi-launcher} jetbrains"
              "SHIFT CTRL, E, exec, ${getExe pkgs.cinnamon.nemo}"
              "SHIFT CTRL, Q, exec, ${getExe scriptPackages.rofi-powermenu}"
            ];

            bindl = with pkgs; [
              ", XF86AudioRaiseVolume, exec, ${wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
              ", XF86AudioLowerVolume, exec, ${wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
              ", XF86AudioMute, exec, ${wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
              ", XF86AudioMicMute, exec, ${wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
              ", XF86AudioPlay, exec, ${getExe playerctl} play-pause"
              ", XF86AudioNext, exec, ${getExe playerctl} next"
              ", XF86AudioPrev, exec, ${getExe playerctl} previous"
              ", XF86audiostop, exec, ${getExe playerctl} stop"
            ];
            bindm = [
              "$mod, mouse:272, movewindow"
              "$mod, mouse:273, resizewindow"
            ];

            # TODO: Check which of those rules leave and which delete
            /*
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
            */
          };
        };
      };
    };
  }
