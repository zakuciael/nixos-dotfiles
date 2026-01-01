{
  config,
  lib,
  pkgs,
  username,
  desktop,
  ...
}:
let
  inherit (lib.my.utils) recursiveMerge;
  inherit (lib)
    getBin
    mkOption
    mkEnableOption
    types
    optionalAttrs
    mkIf
    listToAttrs
    attrsToList
    ;

  cfg = config.modules.desktop.gaming;
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
  mkFileSystemConfig =
    {
      name,
      value,
    }:
    {
      name = value.path;
      value = recursiveMerge [
        {
          inherit (value) device;
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
              "uid=${builtins.toString user.uid}"
              "gid=${builtins.toString group.gid}"
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
        protonup-qt
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

    fileSystems = mkIf (builtins.any ({ value, ... }: value.device != null) (attrsToList cfg.disks)) (
      listToAttrs (builtins.map mkFileSystemConfig (attrsToList cfg.disks))
    );
  };
}
