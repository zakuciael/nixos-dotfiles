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

  # TODO: Temp, remove when full transition to NixOS is done.
  fileSystems."/media/arch" = {
    device = "/dev/disk/by-uuid/0db30fcb-b052-4ef0-9c08-1382d82b4eb5";
  };

  swapDevices = [{device = "/dev/disk/by-partlabel/swap";}];

  modules.hardware.grub.extraEntries = ''
    menuentry "Arch Linux" --class arch {
      insmod part_gpt
      insmod fat
      search --no-floppy --fs-uuid --set=root 5BCB-27B7
      linux /vmlinuz-linux root=UUID=0db30fcb-b052-4ef0-9c08-1382d82b4eb5
      initrd /initramfs-linux.img
    }

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
