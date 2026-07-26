{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib.my.utils) findLayoutConfig getLayoutMonitor;

  inherit (lib) mkEnableOption mkIf getExe;

  cfg = config.modules.desktop.gaming;
  layout = findLayoutConfig config ({ name, ... }: name == "main");
  monitor = getLayoutMonitor layout "wayland";
in
{
  options.modules.desktop.gaming = {
    enable = mkEnableOption "game configurations";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.gvfs ];
    home-manager.users.${username} = {
      home.packages = with pkgs; [
        lutris
        (bottles.override { removeWarningPopup = true; })
        umu-launcher
        r2modman
      ];

      wayland.windowManager.hyprland.settings.windowrule =
        lib.optionals config.modules.desktop.wm.hyprland.enable
          [
            {
              name = "Map Steam Games to Content Type";
              "match:class" = "^(steam_app_.*)$";
              content = "game";
            }

            {
              name = "Default Rules for Games";
              "match:content" = "game";
              inherit monitor;
              idle_inhibit = "fullscreen";
            }
          ];
    };

    # Make system Esync-compatible
    systemd.settings.Manager = {
      DefaultLimitNOFILE = 524288;
    };
    security.pam.loginLimits = [
      {
        domain = username;
        type = "hard";
        item = "nofile";
        value = "524288";
      }
    ];

    users.users.${username}.extraGroups = [ "gamemode" ];
    programs = {
      gamemode = {
        enable = true;
        enableRenice = true;
        settings = {
          general = {
            softrealtime = "auto";
            renice = 10;
          };
          custom = {
            start = "${getExe pkgs.libnotify} -a 'Gamemode' 'Optimizations activated'";
            end = "${getExe pkgs.libnotify} -a 'Gamemode' 'Optimizations deactivated'";
          };
        };
      };
      gamescope = {
        enable = true;
      };
    };

    services.udev = {
      extraRules = ''
        # Disable DS4 touchpad acting as mouse

        # USB
        ATTRS{name}=="Sony Interactive Entertainment Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
        # Bluetooth
        ATTRS{name}=="Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
      '';
      packages = with pkgs; [
        game-devices-udev-rules
      ];
    };

    hardware.uinput.enable = true;
  };
}
