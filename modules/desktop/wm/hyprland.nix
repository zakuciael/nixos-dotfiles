{
  config,
  lib,
  pkgs,
  username,
  scripts,
  ...
}:
with lib;
with lib.my;
let
  scriptPackages = scripts.mkScriptPackages config;
in
desktop.mkDesktopModule {
  inherit config;

  name = "hyprland";
  autostartPath = ".config/hypr/autostart.sh";
  autostart = [
    # Enable proxy for system tray icons inside wine
    "${getBin pkgs.kdePackages.plasma-workspace}/bin/xembedsniproxy"
  ];

  desktopApps = [
    # Terminal apps (uncomment the preffered one)
    # "alacritty"
    # "kitty"
    "ghostty"

    # Other apps
    "_1password"
    "rofi"
    "nh"
    "waybar"
    "gtk"
    "qt"
    "grimblast"
    "discord"
    "swaync"
    "thunderbird"
    "obs"
  ];

  extraOptions = {
    hdr.enable = mkEnableOption "experimental HDR support";
  };

  extraConfig =
    {
      cfg,
      autostartScript,
      colorScheme,
      ...
    }:
    {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
        withUWSM = true;
      };

      # Make chrome and electron apps run native on wayland
      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      # Set default session to non-systemd hyprland
      services.displayManager.defaultSession = "hyprland-uwsm";

      home-manager.users.${username} = {
        home.packages = with pkgs; [ wl-clipboard ];

        xdg.portal = {
          enable = true;
          extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
          xdgOpenUsePortal = false;
        };

        wayland.windowManager.hyprland = {
          enable = true;
          xwayland.enable = true;

          settings = {
            # Autostart script
            exec-once = [
              autostartScript
            ];
            # Source external file for quick debug
            source = [ "$HOME/.config/hypr/debug.conf" ];

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
              "col.active_border" =
                "rgba(${base0C}ff) rgba(${base0D}ff) rgba(${base0B}ff) rgba(${base0E}ff) 45deg";
              "col.inactive_border" = "rgba(${base00}cc) rgba(${base01}cc) 45deg";
              layout = "dwindle";
              resize_on_border = true;
              no_focus_fallback = true;
            };

            # Misc settings
            misc = {
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              enable_anr_dialog = false;
            };

            # Render settings
            render = optionalAttrs cfg.hdr.enable {
              cm_fs_passthrough = 2;
              cm_auto_hdr = 1;
            };

            # Experimental settings
            experimental = {
              xx_color_management_v4 = cfg.hdr.enable;
            };

            # Decoration settings
            decoration = {
              rounding = 10;
              blur = {
                enabled = true;
                size = 5;
                passes = 3;
                new_optimizations = true;
                ignore_opacity = true;
              };
              shadow = {
                enabled = true;
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
              "$mod, return, exec, ${getExe cfg.terminalPackage}"
              "$mod, W, killactive,"
              "$mod, F, togglefloating,"
              "$mod, M, fullscreen, 1"
              "$mod, LEFT, movefocus, l"
              "$mod, RIGHT, movefocus, r"
              "$mod, UP, movefocus, u"
              "$mod, DOWN, movefocus, d"
              "$mod, KP_Subtract, exec, ${getExe scriptPackages.elgato-mic-fix}"
              "SHIFT CTRL, space, exec, ${getExe scriptPackages.rofi-launcher} drun"
              "SHIFT CTRL, R, exec, ${getExe scriptPackages.rofi-launcher-jetbrains}"
              "SHIFT CTRL, E, exec, ${getExe pkgs.nemo}"
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

            windowrulev2 =
              let
                partizionExtId = "ldimfpkkjopddckaglpeakpaepclcljn";
                partizionExtWindowClass = ''chrome-${partizionExtId}-Default'';
              in
              [
                ''float, class:^(${partizionExtWindowClass})$''
                ''center, class:^(${partizionExtWindowClass})$''
                ''size 40% 40%, class:^(${partizionExtWindowClass})$''
              ];
          };
        };
      };
    };
}
