{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  boot.supportedFilesystems = ["ntfs"];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/df1bba7f-d325-41a0-95d8-35dfb05cb990";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A878-849A";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [{device = "/dev/disk/by-uuid/760c0f81-0773-45f5-b853-08ef5eb92314";}];

  boot.initrd.kernelModules = [];
  boot.kernelPackages = mkDefault pkgs.linuxPackages_latest;

  nixpkgs.hostPlatform = mkDefault pkgs.system;
  hardware = {
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
  };
}
