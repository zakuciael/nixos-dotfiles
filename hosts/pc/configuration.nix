{
  config,
  pkgs,
  lib,
  system,
  inputs,
  ...
}: {
  imports = [./hardware.nix ./networking.nix];

  modules = {
    hardware = {
      grub = {
        enable = true;
        theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
      };
      sound.enable = true;
      amdgpu.enable = true;
      docker.enable = true;
    };
    desktop = {
      apps.enable = true;
      gnome.enable = true;
    };
  };
}
