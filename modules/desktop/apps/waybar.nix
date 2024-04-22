{
  pkgs,
  lib,
  config,
  username,
  ...
}:
with lib; let
  colorScheme = config.home-manager.users.${username}.colorScheme;
  package = pkgs.waybar;
in {
  modules.desktop.hyprland.autostart.programs = [
    {
      cmd = "${pkgs.toybox}/bin/pkill waybar && ${package}/bin/waybar";
      once = false;
      priority = 0;
    }
  ];

  home-manager.users.${username} = {
    home.packages = with pkgs; [pavucontrol];
    programs.waybar = {
      inherit package;
    enable = true;

    settings = [
      {
        layer = "top";
        position = "top";

        modules-left = ["hyprland/window"];
        modules-center = ["pulseaudio" "cpu" "hyprland/workspaces" "memory" "disk" "clock"];
        modules-right = ["tray"];

        "hyprland/workspaces" = {
          format = "{name}";
          format-icons = {
            default = " ";
            active = " ";
            urgent = " ";
          };
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
        };
        "hyprland/window" = {
          max-length = 25;
          separate-outputs = false;
        };
        "clock" = {
          format = "{: %H:%M}";
            tooltip = true;
            tooltip-format = "{:%A, %d %B %Y }";
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
            format = " {free} / {total}";
          tooltip = true;
        };
        "network" = {
          format-icons = ["󰤯" "󰤟" "󰤢" "󰤥" "󰤨"];
          format-ethernet = " {bandwidthDownOctets}";
          format-wifi = "{icon} {signalStrength}%";
          format-disconnected = "󰤮";
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
            default = ["" "" ""];
          };
            on-click = "sleep 0.1 && ${pkgs.pavucontrol}/bin/pavucontrol";
        };

        /*
        "clock" = {
          format = '' {:L%H:%M}'';
          tooltip = true;
          tooltip-format = "<big>{:%A, %d.%B %Y }</big><tt><small>{calendar}</small></tt>";
        };
        */
      }
    ];

    style = assert assertMsg (colorScheme.author != "") "You need to select a nix-colors theme to use this Waybar config"; (with colorScheme.palette; ''
      * {
        font-size: 16px;
        font-family: JetBrainsMono Nerd Font, Font Awesome, sans-serif;
        font-weight: bold;
      }

      window#waybar {
        background-color: rgba(26, 27, 38, 0);
        border-bottom: 1px solid rgba(26, 27, 38, 0);
        border-radius: 0px;
        color: #${base0F};
      }

      #workspaces {
        background: linear-gradient(180deg, #${base00}, #${base01});
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
        background-color: #${base00};
        opacity: 1.0;
        transition: all 0.3s ease-in-out;
      }

      #workspaces button.active {
        color: #${base00};
        background: #${base04};
        border-radius: 15px;
        min-width: 40px;
        transition: all 0.3s ease-in-out;
        opacity: 1.0;
      }

      #workspaces button:hover {
        color: #${base00};
        background: #${base04};
        border-radius: 15px;
        opacity: 1.0;
      }

      tooltip {
        background: #${base00};
        border: 1px solid #${base04};
        border-radius: 10px;
      }

      tooltip label {
        color: #${base07};
      }

      #window {
        color: #${base05};
        background: #${base00};
        border-radius: 0px 15px 50px 0px;
        margin: 5px 5px 5px 0px;
        padding: 2px 20px;
      }

      #memory {
        color: #${base0F};
        background: #${base00};
        border-radius: 15px 50px 15px 50px;
        margin: 5px;
        padding: 2px 20px;
      }

      #clock {
        color: #${base0B};
        background: #${base00};
        border-radius: 15px 50px 15px 50px;
        margin: 5px;
        padding: 2px 20px;
      }

      #cpu {
        color: #${base07};
        background: #${base00};
        border-radius: 50px 15px 50px 15px;
        margin: 5px;
        padding: 2px 20px;
      }

      #disk {
        color: #${base03};
        background: #${base00};
        border-radius: 15px 50px 15px 50px;
        margin: 5px;
        padding: 2px 20px;
      }

      #network {
        color: #${base09};
        background: #${base00};
        border-radius: 50px 15px 50px 15px;
        margin: 5px;
        padding: 2px 20px;
      }

      #tray {
        color: #${base05};
        background: #${base00};
        border-radius: 15px 0px 0px 50px;
        margin: 5px 0px 5px 5px;
        padding: 2px 20px;
      }

      #pulseaudio {
        color: #${base0D};
        background: #${base00};
        border-radius: 50px 15px 50px 15px;
        margin: 5px;
        padding: 2px 20px;
      }
    '');

    /*


    window#waybar {
      background-color: #${base00};
      border-bottom: 1px solid rgba(26, 27, 38, 0);
      border-radius: 0px;
      color: #${base0F};
    }

    #workspaces {
      background: #${base01};
      margin: 2px;
      padding: 0px 1px;
      border-radius: 15px;
      border: 0px;
      font-style: normal;
      color: #${base00};
    }

    #workspaces button {
      padding: 0px 5px;
      margin: 4px 3px;
      border-radius: 10px;
      border: 0px;
      color: #${base00};
      background: linear-gradient(45deg, #${base0E}, #${base0F}, #${base0D}, #${base09});
      background-size: 300% 300%;
      animation: gradient_horizontal 15s ease infinite;
      opacity: 0.5;
      transition: ${betterTransition};
    }

    #workspaces button.active {
      padding: 0px 5px;
      margin: 4px 3px;
      border-radius: 10px;
      border: 0px;
      color: #${base00};
      background: linear-gradient(45deg, #${base0E}, #${base0F}, #${base0D}, #${base09});
      background-size: 300% 300%;
      animation: gradient_horizontal 15s ease infinite;
      transition: ${betterTransition};
      opacity: 1.0;
      min-width: 40px;
    }

    #workspaces button:hover {
      border-radius: 10px;
      color: #${base00};
      background: linear-gradient(45deg, #${base0E}, #${base0F}, #${base0D}, #${base09});
      background-size: 300% 300%;
      animation: gradient_horizontal 15s ease infinite;
      opacity: 0.8;
      transition: ${betterTransition};
    }

    @keyframes gradient_horizontal {
      0% {
        background-position: 0% 50%;
      }

      50% {
        background-position: 100% 50%;
      }

      100% {
        background-position: 0% 50%;
      }
    }

    @keyframes swiping {
      0% {
        background-position: 0% 200%;
      }

      100% {
        background-position: 200% 200%;
      }
    }

    tooltip {
      background: #${base00};
      border: 1px solid #${base0E};
      border-radius: 10px;
    }

    tooltip label {
      color: #${base07};
    }

    #window {
      margin: 4px;
      padding: 2px 10px;
      color: #${base05};
      background: #${base01};
      border-radius: 10px;
    }

    #memory {
      color: #${base0F};
      background: #${base01};
      margin: 4px;
      padding: 2px 10px;
      border-radius: 10px;
    }

    #clock {
      color: #${base01};
      background: linear-gradient(45deg, #${base0C}, #${base0F}, #${base0B}, #${base08});
      background-size: 300% 300%;
      animation: gradient_horizontal 15s ease infinite;
      margin: 4px;
      padding: 2px 10px;
      border-radius: 10px;
    }

    #cpu {
      color: #${base07};
      background: #${base01};
      margin: 4px;
      padding: 2px 10px;
      border-radius: 10px;
    }

    #disk {
      color: #${base03};
      background: #${base01};
      margin: 4px;
      padding: 2px 10px;
      border-radius: 10px;
    }

    #battery {
      color: #${base08};
      background: #${base01};
      margin: 4px;
      padding: 2px 10px;
      border-radius: 10px;
    }

    #network {
      color: #${base09};
      background: #${base01};
      margin: 4px;
      padding: 2px 10px;
      border-radius: 10px;
    }

    #custom-hyprbindings {
      color: #${base0E};
      background: #${base01};
      margin: 4px;
      padding: 2px 10px;
      border-radius: 10px;
    }

    #tray {
      color: #${base05};
      background: #${base01};
      margin: 4px;
      padding: 2px 10px;
      border-radius: 10px;
    }

    #pulseaudio {
      color: #${base0D};
      background: #${base01};
      margin: 4px;
      padding: 2px 10px;
      border-radius: 10px;
    }

    #custom-notification {
      color: #${base0C};
      background: #${base01};
      margin: 4px;
      padding: 2px 10px;
      border-radius: 10px;
    }

    #custom-themeselector {
      color: #${base0D};
      background: #${base01};
      margin: 4px 0px;
      padding: 2px 10px 2px 5px;
      border-radius: 0px 10px 10px 0px;
    }

    #custom-startmenu {
      color: #${base00};
      background: linear-gradient(45deg, #${base09}, #${base03}, #${base0C}, #${base07});
      background-size: 300% 300%;
      animation: gradient_horizontal 15s ease infinite;
      margin: 4px;
      padding: 2px 10px;
      border-radius: 10px;
    }

    #idle_inhibitor {
      color: #${base09};
      background: #${base01};
      margin: 4px 0px;
      padding: 2px 14px;
      border-radius: 0px;
    }

    #custom-exit {
      color: #${base0E};
      background: #${base01};
      border-radius: 10px 0px 0px 10px;
      margin: 4px 0px;
      padding: 2px 5px 2px 15px;
    }
    */
  };
}
