{
  lib,
  pkgs,
  username,
  desktop,
  colorScheme,
  ...
}:
with lib;
let
  package = pkgs.waybar;
in
{
  # TODO: Add priority for waybar, so it starts before any other app
  modules.desktop.wm.${desktop}.autostartPrograms = [
    "${package}/bin/waybar"
  ];

  home-manager.users.${username} = {
    programs.waybar = {
      inherit package;
      enable = true;

      settings = [
        {
          layer = "top";
          position = "top";

          modules-left = [ "hyprland/window" ];
          modules-center = [
            "pulseaudio"
            "network"
            "cpu"
            "hyprland/workspaces"
            "memory"
            "battery"
            "disk"
            "clock"
          ];
          modules-right = [
            "upower#keyboard"
            "upower#mouse"
            "tray"
          ];

          "hyprland/workspaces" = {
            format = "{name}";
            format-icons = {
              default = " ";
              active = " ";
              urgent = " ";
            };
            on-scroll-up = "hyprctl dispatch workspace m+1";
            on-scroll-down = "hyprctl dispatch workspace m-1";
          };
          "hyprland/window" = {
            max-length = 25;
            separate-outputs = true;
          };
          "clock" = {
            format = " {:%H:%M}";
            tooltip = true;
            tooltip-format = "{:%A, %d %B %Y}";
          };
          "memory" = {
            interval = 5;
            format = " {}%";
            tooltip = true;
          };
          "cpu" = {
            interval = 5;
            format = " {usage:2}%";
            tooltip = true;
          };
          "disk" = {
            format = " {free}";
            tooltip = true;
          };
          "network" = {
            format-icons = [
              "󰤯"
              "󰤟"
              "󰤢"
              "󰤥"
              "󰤨"
            ];
            format-ethernet = "󰈀 Ethernet";
            format-wifi = "{icon} {essid}";
            format-disconnected = "󰤮 Disconnected";
            tooltip = false;
          };
          "tray" = {
            spacing = 12;
          };
          "pulseaudio" = {
            format = "{icon} {volume}% {format_source}";
            format-bluetooth = "{volume}% {icon} {format_source}";
            format-bluetooth-muted = "󰝟 {icon} {format_source}";
            format-muted = "󰝟 {format_source}";
            format-source = " {volume}%";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "󰋎";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
            on-click = "sleep 0.1 && ${pkgs.pavucontrol}/bin/pavucontrol";
          };
          "battery" = {
            format-icons = [
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-time = "{H}h {M}min";
            tooltip = true;
            tooltip-format = "{timeTo}";
            interval = 60;
            states = {
              warning = 30;
              critical = 15;
            };
          };
          "upower#keyboard" = {
            native-path = "/org/bluez/hci0/dev_D0_01_1B_5C_9F_C4";
            format = "󰌌 {percentage}";
            tooltip = false;
            show-icon = false;
            hide-if-empty = true;
          };
          "upower#mouse" = {
            native-path = "/org/bluez/hci0/dev_EF_9B_87_CC_57_EC";
            format = "󰍽 {percentage}";
            tooltip = false;
            show-icon = false;
            hide-if-empty = true;
          };
        }
      ];

      style =
        with colorScheme.palette;
        let
          modulesPadding = ''
            margin: 5px;
            padding: 2px 20px;
          '';
          # Border for modules located on the left side of the screen
          borderLeft = ''
            border-radius: 50px 15px 50px 15px;
          '';
          # Border for modules located on the left side of the screen
          borderRight = ''
            border-radius: 15px 50px 15px 50px;
          '';
        in
        ''
          * {
            font-size: 14px;
            font-family: JetBrains Mono, sans-serif;
            font-weight: bold;
          }

          window#waybar {
            background-color: rgba(26, 27, 38, 0);
            border-bottom: 1px solid rgba(26, 27, 38, 0);
            border-radius: 0px;
            color: #${base0F};
          }

          #workspaces {
            background: linear-gradient(180deg, #${base02}, #${base00});
            margin: 5px;
            padding: 0px 1px;
            border-radius: 15px;
            border: 0px;
            font-style: normal;
            color: #${base00};
          }

          #workspaces button {
            padding: 0px 5px;
            margin: 4px 3px;
            border-radius: 15px;
            border: 0px;
            color: #${base00};
            background-color: #${base04};
            opacity: 1.0;
            transition: all 0.3s ease-in-out;
          }

          #workspaces button.active {
            color: #${base00};
            background: #${base07};
            border-radius: 15px;
            min-width: 40px;
            transition: all 0.3s ease-in-out;
            opacity: 1.0;
          }

          #workspaces button:hover {
            color: #${base00};
            background: #${base0D};
            border-radius: 15px;
            opacity: 1.0;
          }

          tooltip {
            background: #${base00};
            border: 1px solid #${base04};
            border-radius: 10px;
          }

          tooltip label {
            color: #${base05};
          }

          #window {
            color: #${base05};
            background: #${base00};
            border-radius: 0px 15px 50px 0px;
            margin: 5px 5px 5px 0px;
            padding: 2px 20px;
          }

          #memory {
            color: #${base0D};
            background: #${base00};
            ${borderRight}
            ${modulesPadding}
          }

          #clock {
            color: #${base05};
            background: #${base00};
            ${borderRight}
            ${modulesPadding}
          }

          #cpu {
            color: #${base0C};
            background: #${base00};
            ${borderLeft}
            ${modulesPadding}
          }

          #battery {
            color: #${base08};
            background: #${base00};
            ${borderRight}
            ${modulesPadding}
          }

          #disk {
            color: #${base0B};
            background: #${base00};
            ${borderRight}
            ${modulesPadding}
          }

          #network {
            color: #${base09};
            background: #${base00};
            ${borderLeft}
            ${modulesPadding}
          }

          #tray {
            color: #${base05};
            background: #${base00};
            border-radius: 15px 0px 0px 50px;
            margin: 5px 0px 5px 5px;
            padding: 2px 20px;
          }

          #pulseaudio {
            color: #${base0E};
            background: #${base00};
            ${borderLeft}
            ${modulesPadding}
          }

          #upower {
            color: #${base0A};
            background: #${base00};
            ${borderRight}
            ${modulesPadding}
          }
        '';
    };
  };
}
