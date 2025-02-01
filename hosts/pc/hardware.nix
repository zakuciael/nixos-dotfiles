{ pkgs, inputs, ... }:
let
  inherit (inputs) nixos-hardware;
in
{
  imports = with nixos-hardware.nixosModules; [
    msi-b550-gaming-plus
    common-cpu-amd-zenpower
    common-cpu-amd-pstate
    common-gpu-amd
  ];

  # Additional settings for AMD GPU
  hardware.enableRedistributableFirmware = true;
  services.xserver.videoDrivers = [ "amdgpu" ];

  boot = {
    swraid.enable = true;
    supportedFilesystems = [ "ntfs" ];
    kernelPackages = pkgs.linuxPackages_xanmod_stable;
  };

  environment.systemPackages = [
    pkgs.gvfs # Needed to display disks in GUI
  ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-partlabel/nixos";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-partlabel/efi";
      fsType = "vfat";
    };

    "/media/storage".device = "/dev/md/storage";

    # Game disks
    "/media/games/linux" = {
      device = "/dev/disk/by-partlabel/linux-games";
      options = [ "x-gvfs-show" ];
    };

    # TODO: Steam had problem due to this disk not being owned by the current user... investigate.
    "/media/games/windows" = {
      device = "/dev/disk/by-partlabel/windows-games";
      fsType = "ntfs";
      options = [ "x-gvfs-show" ];
    };
  };
}
