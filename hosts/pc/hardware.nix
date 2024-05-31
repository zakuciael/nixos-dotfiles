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

  fileSystems."/media/storage" = {
    device = "/dev/md/storage";
  };

  # TODO: Temp, remove when full transision to NixOS is done.
  fileSystems."/media/arch" = {
    device = "/dev/disk/by-uuid/0db30fcb-b052-4ef0-9c08-1382d82b4eb5";
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
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.swraid.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault pkgs.system;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
