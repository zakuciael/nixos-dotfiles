{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkDefault;
  nixos-hardware = inputs.nixos-hardware.nixosModules;
in
{
  imports = [
    nixos-hardware.common-cpu-amd
    nixos-hardware.common-cpu-amd-zenpower
    nixos-hardware.common-cpu-amd-pstate
    nixos-hardware.common-pc-ssd
    nixos-hardware.common-pc
    nixos-hardware.common-gpu-amd
  ];

  # Additional settings for AMD GPU
  hardware.enableRedistributableFirmware = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  # GPU feature flags (https://github.com/torvalds/linux/blob/d0b3b7b22dfa1f4b515fd3a295b3fd958f9e81af/drivers/gpu/drm/amd/include/amd_shared.h#L185):
  # - PP_OVERDRIVE_MASK (0x4000) - "OverDrive" functionality, which allows you to manually overclock or undervolt your AMD graphics card.
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xfff7ffff" ];
  hardware.graphics.extraPackages = with pkgs; [
    vulkan-loader
    vulkan-validation-layers
    vulkan-extension-layer
  ];

  boot = {
    # Kernel module for motherboard's Nuvoton NCT6687D-R chipset
    kernelModules = [ "nct6687" ];
    extraModulePackages = with config.boot.kernelPackages; [
      nct6687d
    ];

    # Avoid kernel module conflicts
    extraModprobeConfig = ''
      blacklist nct6683
    '';

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
      fsType = "auto";
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
