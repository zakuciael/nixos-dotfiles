{
  config,
  lib,
  pkgs,
  ...
}: {
  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/efi";
    fsType = "vfat";
  };

  swapDevices = [{device = "/dev/disk/by-partlabel/swap";}];

  boot.initrd.kernelModules = ["kvm-intel"];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
