{
  config,
  lib,
  pkgs,
  ...
}: {
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/b4810647-5a2a-47dd-9c41-e2be29f12fe6";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/5BCB-27B7";
    fsType = "vfat";
  };

  boot.tmp = {
    cleanOnBoot = true;
    useTmpfs = true;
    tmpfsSize = "25%";
  };

  boot.initrd.kernelModules = ["kvm-intel"];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
