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

    # Password manager
    "_1password"

    # Application launchers
    "rofi"
    "vicinae"

    # Themes
    "gtk"
    "qt"

    # Tools
    "nh"
    "grimblast"
    "nmgui"

    # System components
    "hyprlock"
    "hypridle"
    "hypremoji"
    "swaync"
    "nemo"
    "waybar"

    # Apple stuff
    "librepods"
    "cider"

    # VPN
    "netbird"

    # Apps
    "obs"
    "discord"
    "thunderbird"
    "zen-browser"
    "amethyst-mod-manager"
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

      # Dirty hack around https://github.com/NixOS/nixpkgs/pull/474174
      programs.uwsm.waylandCompositors = mkForce { };
      services.displayManager.sessionPackages = [
        (pkgs.writeTextFile rec {
          name = "hyprland-uwsm";
          text = ''
            [Desktop Entry]
            Name=Hyprland (UWSM)
            Comment=Hyprland compositor managed by UWSM
            Exec=${lib.getExe config.programs.uwsm.package} start -F -- ${config.programs.hyprland.package}/share/wayland-sessions/hyprland.desktop
            DesktopNames=Hyprland
            Type=Application
          '';
          destination = "/share/wayland-sessions/${name}.desktop";
          derivationArgs = {
            passthru.providedSessions = [ "${name}" ];
          };
        })
      ];

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

          # Conflicts with `programs.hyprland.withUWSM`
          systemd.enable = false;

          configType = "lua";
          extraConfig = /* lua */ ''
            -- Source external file for quick debug
            require("debug")
          '';
          settings =
            let
              inherit (lib.my.utils.hypr)
                mkLuaInline
                dsp
                withMod
                mkBind
                mkBindWithOpts
                ;
            in
            {
              mod = {
                _var = "SUPER";
              };

              # Autostart Script
              on = {
                _args = [
                  "hyprland.start"
                  (mkLuaInline ''
                    function()
                      hl.exec_cmd("${autostartScript}")
                    end'')
                ];
              };

              config = {
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

                  col = {
                    active_border = {
                      colors = [
                        "rgba(${base0C}ff)"
                        "rgba(${base0D}ff)"
                        "rgba(${base0B}ff)"
                        "rgba(${base0E}ff)"
                      ];
                      angle = 45;
                    };
                    inactive_border = {
                      colors = [
                        "rgba(${base00}cc)"
                        "rgba(${base01}cc)"
                      ];
                      angle = 45;
                    };
                  };

                  layout = "dwindle";
                  resize_on_border = true;
                  no_focus_fallback = true;
                };

                # Misc settings
                misc = {
                  disable_hyprland_logo = true;
                  disable_splash_rendering = true;
                  middle_click_paste = false;
                  enable_anr_dialog = false;
                };

                # XWayland settings
                xwayland = {
                  force_zero_scaling = true;
                  create_abstract_socket = true;
                };

                ecosystem = {
                  no_update_news = true;
                  no_donation_nag = true;
                };

                # Render settings
                render = optionalAttrs cfg.hdr.enable {
                  cm_auto_hdr = 1;
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

                animations.enabled = true;

                # Layout settings
                dwindle.preserve_split = true;
                master.new_status = "master";
              };

              # Animation settings
              curve = [
                {
                  _args = [
                    "wind"
                    {
                      type = "bezier";
                      points = [
                        [
                          0.05
                          0.9
                        ]
                        [
                          0.1
                          1.05
                        ]
                      ];
                    }
                  ];
                }

                {
                  _args = [
                    "winIn"
                    {
                      type = "bezier";
                      points = [
                        [
                          0.1
                          1.1
                        ]
                        [
                          0.1
                          1.1
                        ]
                      ];
                    }
                  ];
                }
                {
                  _args = [
                    "winOut"
                    {
                      type = "bezier";
                      points = [
                        [
                          0.3
                          (mkLuaInline "-0.3")
                        ]
                        [
                          0
                          1
                        ]
                      ];
                    }
                  ];
                }
                {
                  _args = [
                    "liner"
                    {
                      type = "bezier";
                      points = [
                        [
                          1
                          1
                        ]
                        [
                          1
                          1
                        ]
                      ];
                    }
                  ];
                }
              ];

              animation = [
                {
                  leaf = "windows";
                  enabled = true;
                  speed = 6;
                  bezier = "wind";
                  style = "slide";
                }

                {
                  leaf = "windowsIn";
                  enabled = true;
                  speed = 6;
                  bezier = "winIn";
                  style = "slide";
                }
                {
                  leaf = "windowsOut";
                  enabled = true;
                  speed = 5;
                  bezier = "winOut";
                  style = "slide";
                }
                {
                  leaf = "windowsMove";
                  enabled = true;
                  speed = 5;
                  bezier = "wind";
                  style = "slide";
                }
                {
                  leaf = "border";
                  enabled = true;
                  speed = 1;
                  bezier = "liner";
                }
                {
                  leaf = "borderangle";
                  enabled = true;
                  speed = 80;
                  bezier = "liner";
                  style = "loop";
                }
                {
                  leaf = "fade";
                  enabled = true;
                  speed = 10;
                  bezier = "default";
                }
                {
                  leaf = "workspaces";
                  enabled = true;
                  speed = 5;
                  bezier = "wind";
                }
              ];

              # Layer ryles
              layer_rule = [
                {
                  match.namespace = "^swaync-(control-center|notification-window)$";
                  blur = true;
                  ignore_alpha = 0.5;
                }
              ];

              # Keybinds
              bind = [
                # Open terminal
                (mkBind (withMod "Return") (dsp.exec (getExe cfg.terminalPackage)))

                # Lock the session
                (mkBind (withMod "L") (dsp.exec "${getExe' pkgs.systemd "loginctl"} lock-session"))

                # Kill active window
                (mkBind (withMod "W") dsp.close)

                # Toggle floating mode for active window
                (mkBind (withMod "F") dsp.float)

                # Toggle maximized mode for active window
                (mkBind (withMod "M") (dsp.fullscreen "maximized"))

                # Move focus between windows using direction keys
                (mkBind (withMod "LEFT") (dsp.focus "left"))
                (mkBind (withMod "RIGHT") (dsp.focus "right"))
                (mkBind (withMod "UP") (dsp.focus "up"))
                (mkBind (withMod "DOWN") (dsp.focus "down"))

                # Open file explorer
                (mkBind "CTRL + SHIFT + E" (dsp.exec (getExe pkgs.nemo)))

                # Open power menu
                (mkBind "CTRL + SHIFT + Q" (dsp.exec (getExe scriptPackages.rofi-powermenu)))

                # Fix physical mute button for Elgato Wave 3 microphone
                (mkBind (withMod "F23") (dsp.exec (getExe scriptPackages.elgato-mic-fix)))

                # Drag / Resize active floating window with mouse buttons
                (mkBind (withMod "mouse:272") dsp.drag)
                (mkBind (withMod "mouse:273") dsp.resize)

                # Media control keys
                (mkBindWithOpts "XF86AudioPlay" (dsp.exec "${getExe pkgs.playerctl} play-pause") { locked = true; })
                (mkBindWithOpts "XF86audiostop" (dsp.exec "${getExe pkgs.playerctl} stop") { locked = true; })
                (mkBindWithOpts "XF86AudioNext" (dsp.exec "${getExe pkgs.playerctl} next") { locked = true; })
                (mkBindWithOpts "XF86AudioPrev" (dsp.exec "${getExe pkgs.playerctl} previous") { locked = true; })

                # Volume control keys
                (mkBindWithOpts "XF86AudioMute"
                  (dsp.exec "${getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SINK@ toggle")
                  { locked = true; }
                )
                (mkBindWithOpts "XF86AudioMicMute"
                  (dsp.exec "${getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
                  { locked = true; }
                )
                (mkBindWithOpts "XF86AudioRaiseVolume"
                  (dsp.exec "${getExe' pkgs.wireplumber "wpctl"} set-volume @DEFAULT_AUDIO_SINK@ 5%+")
                  { repeating = true; }
                )
                (mkBindWithOpts "XF86AudioLowerVolume"
                  (dsp.exec "${getExe' pkgs.wireplumber "wpctl"} set-volume @DEFAULT_AUDIO_SINK@ 5%-")
                  { repeating = true; }
                )

                # Brightness control keys
                (mkBindWithOpts "XF86MonBrightnessUp" (dsp.exec "${getExe pkgs.brightnessctl} -q set 5%+") {
                  repeating = true;
                })
                (mkBindWithOpts "XF86MonBrightnessDown" (dsp.exec "${getExe pkgs.brightnessctl} -q set 5%-") {
                  repeating = true;
                })
              ];
            };
        };
      };
    };
}
