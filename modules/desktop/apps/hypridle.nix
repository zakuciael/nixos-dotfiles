{
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib) getExe getExe';
in
{
  home-manager.users.${username}.services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "pidof hyprlock || ${getExe pkgs.hyprlock}"; # don't spawn a second instance if already running
        before_sleep_cmd = "${getExe' pkgs.systemd "loginctl"} lock-session"; # lock before suspend
        after_sleep_cmd = "${getExe' pkgs.hyprland "hyprctl"} dispatch dpms on";
      };

      listener = [
        {
          timeout = 300; # 5min.
          on-timeout = "${getExe pkgs.brightnessctl} -s set 10"; # set monitor backlight to minimum, avoid 0 on OLED monitor.
          on-resume = "${getExe pkgs.brightnessctl} -r"; # monitor backlight restore.
        }

        # turn off keyboard backlight, comment out this section if you dont have a keyboard backlight.
        {
          timeout = 300; # 5min.
          on-timeout = "${getExe pkgs.brightnessctl} -sd rgb:kbd_backlight set 0"; # turn off keyboard backlight.
          on-resume = "${getExe pkgs.brightnessctl} -rd rgb:kbd_backlight"; # turn on keyboard backlight.
        }

        {
          timeout = 600; # 10min
          on-timeout = "${getExe' pkgs.systemd "loginctl"} lock-session"; # lock screen when timeout has passed
        }

        {
          timeout = 900; # 15min
          on-timeout = "${getExe' pkgs.hyprland "hyprctl"} dispatch dpms off"; # screen off when timeout has passed
          on-resume = "${getExe' pkgs.hyprland "hyprctl"} dispatch dpms on && ${getExe pkgs.brightnessctl} -r"; # screen on when activity is detected after timeout has fired.
        }

        {
          timeout = 1800; # 30min
          on-timeout = "${getExe' pkgs.systemd "systemctl"} suspend"; # suspend pc
        }
      ];
    };
  };
}
