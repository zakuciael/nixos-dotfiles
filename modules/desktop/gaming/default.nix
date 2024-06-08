{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.my; let
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
  mkFileSystemConfig = {
    name,
    value,
  }: {
    name = value.path;
    value = {inherit (value) device;} // (lib.optionalAttrs (name == "windows") {fsType = "ntfs";});
  };
in {
  options.modules.desktop.gaming = {
    enable = mkEnableOption "game configurations";
    disks = {
      linux = mkDiskOptions "/media/games/linux";
      windows = mkDiskOptions "/media/games/windows";
    };
  };

  config = mkIf (cfg.enable) {
    boot.kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_stable;

    fileSystems =
      mkIf
      (builtins.any ({value, ...}: value.device != null) (attrsToList cfg.disks))
      (listToAttrs (builtins.map mkFileSystemConfig (lib.attrsToList cfg.disks)));
  };
}
