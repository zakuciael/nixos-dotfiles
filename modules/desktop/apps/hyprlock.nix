{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (pkgs) writeShellApplication;
  inherit (lib) getExe getExe';
  inherit (lib.my.utils) findLayoutConfig;
  inherit (config.home-manager.users.${username}.xdg) cacheHome;

  allLayouts = config.modules.hardware.layout.layout;
  monitor = (findLayoutConfig config ({ name, ... }: name == "main")).monitor.wayland;

  networkScript = writeShellApplication {
    name = "network-label";
    runtimeInputs = with pkgs; [
      networkmanager
      busybox
    ];
    text = ''
      status="$(nmcli general status | grep -oh "\w*connect\w*")"

      if [[ "$status" == "disconnected" ]]; then
        printf "Disconnected 󰤮⠀"
      elif [[ "$status" == "connecting" ]]; then
        printf "Connecting 󱍸⠀"
      elif [[ "$status" == "connected" ]]; then
        wow="$(nmcli con show --active | awk 'NR==2 {print $5}')"
        if [ "$wow" == "ethernet" ]
        then
          #printf "Wierd In "
          printf "󰈀⠀\n"
        else
          #ssid="$(echo $(nmcli -g name connection show --active | awk 'NR==1'))"
          #printf "$ssid  "
          if strength="$(awk 'NR==3 {print $3}' /proc/net/wireless | sed 's/\.//g')"; then
            if [[ "$strength" -eq "0" ]]; then
              printf "󰤯⠀\n"
            elif [[ ("$strength" -ge "0") && ("$strength" -le "25") ]]; then
              printf "󰤟⠀\n"
            elif [[ ("$strength" -ge "25") && ("$strength" -le "50") ]]; then
              printf "󰤢⠀\n"
            elif [[ ("$strength" -ge "50") && ("$strength" -le "75") ]]; then
              printf "󰤥⠀\n"
            elif [[ ("$strength" -ge "75") && ("$strength" -le "100") ]]; then
              printf "󰤨⠀\n"
            fi
          else
            printf "Idk :))"
          fi
        fi
      fi
    '';
  };

  songDetailScript = writeShellApplication {
    name = "song-detail";
    runtimeInputs = [ pkgs.playerctl ];
    text = ''
      artist="$(playerctl metadata xesam:artist)"
      title="$(playerctl metadata xesam:title)"

      case "$1" in
      --title)
        echo "$title"
        ;;
      --artist)
        echo "$artist"
        ;;
      esac
    '';
  };

  songArtworkScript = writeShellApplication {
    name = "song-artwork";
    runtimeInputs = with pkgs; [
      playerctl
      imagemagick
    ];
    text = ''
      url="$(playerctl metadata mpris:artUrl)"
      artist="$(playerctl metadata xesam:artist)"
      album="$(playerctl metadata xesam:album)"
      metadata="$(printf '%s - %s' "$artist" "$album")"

      mkdir -p "${cacheHome}/album-artwork"

      if [ "$url" == "No player found" ]
      then
        exit
      elif [ -f "${cacheHome}/album-artwork/''${metadata}.png" ]
      then
        echo "${cacheHome}/album-artwork/''${metadata}.png"
      else
        curl -s "$url" -o "${cacheHome}/album-artwork/''${metadata}"
        magick "${cacheHome}/album-artwork/''${metadata}" "${cacheHome}/album-artwork/''${metadata}.png"
        rm "${cacheHome}/album-artwork/''${metadata}"
        echo "${cacheHome}/album-artwork/''${metadata}.png"
      fi
    '';
  };
in
{
  home-manager.users.${username}.programs.hyprlock = {
    enable = true;
    sourceFirst = true;
    settings = {
      general = {
        no_fade_in = false;
        no_fade_out = false;
        hide_cursor = false;
        grace = 0;
        disable_loading_bar = false;
      };

      background =
        allLayouts
        |> map (layout: {
          monitor = layout.monitor.wayland;
          path = toString layout.wallpaper;
          blur_passes = 2;
          contrast = 1;
          brightness = 0.6;
          vibrancy = 0.2;
          vibrancy_darkness = 0.2;

        });

      # Password input
      input-field = {
        inherit monitor;
        size = "250, 60";
        outline_thickness = 2;
        dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
        dots_spacing = 0.35; # Scale of dots' absolute size, 0.0 - 1.0
        dots_center = true;
        outer_color = "rgba(0, 0, 0, 0)";
        inner_color = "rgba(0, 0, 0, 0.2)";
        font_color = "rgb(209, 207, 207)";
        fade_on_empty = false;
        rounding = 32;
        fail_color = "rgba(191, 97, 106, 0.75)";
        check_color = "rgba(235, 203, 139, 0.75)";
        placeholder_text = "<span foreground='##cdd6f4'>Input Password...</span>";
        hide_input = false;
        position = "0, -400";
        halign = "center";
        valign = "center";
      };

      label = [
        # Date
        {
          inherit monitor;
          text = ''cmd[update:1000] echo "$(${getExe' pkgs.busybox "date"} +"%A, %B %d")"'';
          color = "rgba(209, 207, 207, 0.75)";
          font_size = 22;
          font_family = "JetBrains Mono";
          position = "0, 300";
          halign = "center";
          valign = "center";
        }

        # Time
        {
          inherit monitor;
          text = ''cmd[update:1000] echo "$(${getExe' pkgs.busybox "date"} +"%-H:%M")"'';
          color = "rgba(209, 207, 207, 0.75)";
          font_size = 95;
          font_family = "JetBrains Mono ExtraBold";
          position = "0, 200";
          halign = "center";
          valign = "center";
        }

        # Song title
        {
          inherit monitor;
          text = ''cmd[update:1000] echo "$(${getExe songDetailScript} --title)"'';
          color = "rgba(209, 207, 207, 0.75)";
          font_size = 17;
          font_family = "Source Code Pro bold";
          position = "0, -200";
          halign = "center";
          valign = "center";
        }

        # Song artist
        {
          inherit monitor;
          text = ''cmd[update:1000] echo "$(${getExe songDetailScript} --artist)"'';
          color = "rgba(209, 207, 207, 0.75)";
          font_size = 15;
          font_family = "Source Code Pro";
          position = "0, -230";
          halign = "center";
          valign = "center";
        }

        # Network icon
        {
          inherit monitor;
          text = ''cmd[update:5000] echo "$(${getExe networkScript})"'';
          color = "rgba(209, 207, 207, 0.75)";
          font_size = 14;
          font_family = "Source Code Pro bold";
          position = "-20, -10";
          halign = "right";
          valign = "top";
        }
      ];

      image = [
        # Song artwork
        {
          inherit monitor;
          size = 256; # lesser side if not 1:1 ratio
          rounding = 6; # negative values mean circle
          border_size = 3;
          border_color = "rgb(133, 180, 234)";
          rotate = 0; # degrees, counter-clockwise
          reload_time = 2;
          reload_cmd = "${getExe songArtworkScript}";
          position = "0, -25";
          halign = "center";
          valign = "center";
          opacity = 1;
        }
      ];
    };
  };

  fonts.packages = [ pkgs.source-code-pro ];

  security.pam.services.hyprlock.u2fAuth = false;
}
