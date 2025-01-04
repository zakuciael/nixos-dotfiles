{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib)
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
      value =
        {
          inherit (value) device;
        }
        // (optionalAttrs (name == "windows") {
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

        });
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

  config = mkIf (cfg.enable) {
    users.users.${username}.extraGroups = [ "gamemode" ];
    home-manager.users.${username} = {
      home.packages = [
        pkgs.lutris-free
        pkgs.bottles
      ];
    };

    programs = {
      gamemode = {
        enable = true;
      };
      gamescope = {
        enable = true;
      };
    };

    boot.kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_stable;

    fileSystems = mkIf (builtins.any ({ value, ... }: value.device != null) (attrsToList cfg.disks)) (
      listToAttrs (builtins.map mkFileSystemConfig (attrsToList cfg.disks))
    );
  };
}
