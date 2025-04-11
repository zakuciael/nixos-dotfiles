{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkDefault;
  nixos-hardware = inputs.nixos-hardware.outPath;
in
{
  imports = [
    "${nixos-hardware}/msi/b550-gaming-plus"
    "${nixos-hardware}/common/cpu/amd/zenpower.nix"
    "${nixos-hardware}/common/cpu/amd/pstate.nix"
    "${nixos-hardware}/common/gpu/amd"
  ];

  # Additional settings for AMD GPU
  hardware.enableRedistributableFirmware = true;
  services.xserver.videoDrivers = [ "amdgpu" ];

  boot = {
    kernelPackages = mkDefault pkgs.linuxPackages_latest;
    swraid.enable = true;
    supportedFilesystems = [ "ntfs" ];
    extraModprobeConfig = ''
      blacklist ntfs3
    '';
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-partlabel/nixos";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-partlabel/efi";
      fsType = "vfat";
    };

    "/media/storage" = {
      device = "/dev/md/storage";
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-partlabel/swap"; }
  ];

  modules.hardware.grub.extraEntries = {
    Windows = {
      class = "windows";
      body = ''
        insmod part_gpt
        insmod fat
        insmod search_fs_uuid
        insmod chain
        search --no-floppy --fs-uuid --set=root F042-E2DF
        chainloader /efi/Microsoft/Boot/bootmgfw.efi
      '';
    };
  };
}
