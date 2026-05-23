{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib.my.utils) findLayoutConfig getLayoutMonitor recursiveMerge;

  inherit (lib)
    mkOption
    mkEnableOption
    types
    optionalAttrs
    mkIf
    mapAttrs'
    filterAttrs
    ;

  cfg = config.modules.desktop.gaming;
  layout = findLayoutConfig config ({ name, ... }: name == "main");
  monitor = getLayoutMonitor layout "wayland";

  mkDiskOptions = path: {
    device = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Location of the device.";
    };
    path = mkOption {
      type = types.nullOr types.str;
      default = path;
      description = "Location of the mounted file system.";
    };
  };
  mkFileSystemConfig = name: disk: {
    name = disk.path;
    value = recursiveMerge [
      {
        inherit (disk) device;
        fsType = "auto";
        options = [
          "x-gfs-show"
          "x-gvfs-show"
        ];
      }
      (optionalAttrs (name == "windows") {
        fsType = "ntfs";
        options =
          let
            user = config.users.users.${username};
            group = config.users.groups.${user.group};
          in
          [
            "uid=${toString user.uid}"
            "gid=${toString group.gid}"
            "dmask=022"
            "fmask=133"
          ];

      })
    ];
  };
in
{
  options.modules.desktop.gaming = {
    enable = mkEnableOption "game configurations";
    disks = {
      linux = mkDiskOptions "/media/games/linux";
      windows = mkDiskOptions "/media/games/windows";
    };
  };

  config = mkIf cfg.enable {
    users.users.${username}.extraGroups = [ "gamemode" ];
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

    programs = {
      gamemode = {
        enable = true;
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

    fileSystems =
      cfg.disks |> filterAttrs (_: disk: disk.device != null) |> mapAttrs' mkFileSystemConfig;
  };
}
