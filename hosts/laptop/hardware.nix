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
    inputs.nixos-hardware.nixosModules.framework-16-amd-ai-300-series
  ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/212b17c3-8442-4cc3-b8ae-473e05395685";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/70C6-9199";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };
  swapDevices = [
    { device = "/dev/disk/by-uuid/a8192c2c-91b6-45f3-81cd-192a3f9fdbc5"; }
  ];

  boot = {
    initrd = {
      availableKernelModules = [ ];
      kernelModules = [ "amdgpu" ];
    };
    kernelPackages = mkDefault pkgs.linuxPackages_latest;
  };

  hardware = {
    enableAllFirmware = true;
    cpu.amd.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;

    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
