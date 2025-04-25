{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
with lib;
{
  imports = [
    "${inputs.nixos-hardware.outPath}/common/cpu/intel"
    "${inputs.nixos-hardware.outPath}/common/pc/laptop"
    "${inputs.nixos-hardware.outPath}/common/pc/laptop/ssd"
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/df1bba7f-d325-41a0-95d8-35dfb05cb990";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A878-849A";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/760c0f81-0773-45f5-b853-08ef5eb92314"; } ];

  boot = {
    supportedFilesystems = [ "ntfs" ];
    initrd.kernelModules = [ ];
    kernelPackages = mkDefault pkgs.linuxPackages_latest;
    # Kernel Panic on suspend fix, taken from ArchLinux wiki.
    kernelParams = [
      "acpi_enforce_resources=lax"
      "i915.enable_dc=0"
    ];
    # Audio Mute LED
    extraModprobeConfig = ''
      options snd-hda-intel model=mute-led-gpio
      blacklist ntfs3
    '';
  };

  hardware = {
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;

    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  modules.hardware.grub.extraEntries = {
    Windows = {
      class = "windows";
      body = ''
        insmod part_gpt
        insmod fat
        insmod search_fs_uuid
        insmod chain
        search --no-floppy --fs-uuid --set=root A878-849A
        chainloader /efi/Microsoft/Boot/bootmgfw.efi
      '';
    };
  };

}
