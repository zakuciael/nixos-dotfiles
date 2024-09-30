{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  boot.supportedFilesystems = ["ntfs"];

  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/efi";
    fsType = "vfat";
  };

  fileSystems."/media/storage" = {
    device = "/dev/md/storage";
  };

  swapDevices = [{device = "/dev/disk/by-partlabel/swap";}];

  modules.hardware.grub.extraEntries = ''
    menuentry "Windows" --class windows {
      insmod part_gpt
      insmod fat
      insmod search_fs_uuid
      insmod chain
      search --no-floppy --fs-uuid --set=root F042-E2DF
      chainloader /efi/Microsoft/Boot/bootmgfw.efi
    }
  '';

  boot.initrd.kernelModules = ["kvm-intel"];
  boot.kernelPackages = mkDefault pkgs.linuxPackages_latest;
  boot.swraid.enable = true;

  nixpkgs.hostPlatform = mkDefault pkgs.system;
  hardware.cpu.intel.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
}
