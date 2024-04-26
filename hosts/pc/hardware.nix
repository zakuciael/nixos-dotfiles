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

  fileSystems."/media/games/windows" = {
    device = "/dev/disk/by-partlabel/windows-games";
    fsType = "ntfs";
  };

  fileSystems."/media/games/linux" = {
    device = "/dev/disk/by-partlabel/linux-games";
  };

  # TODO: Temp, remove when full transision to NixOS is done.
  fileSystems."/media/arch" = {
    device = "/dev/disk/by-uuid/0db30fcb-b052-4ef0-9c08-1382d82b4eb5";
  };

  swapDevices = [{device = "/dev/disk/by-partlabel/swap";}];

  boot.initrd.kernelModules = ["kvm-intel"];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
