{
  config,
  pkgs,
  lib,
  system,
  inputs,
  ...
}:
with lib;
with lib.my; {
  imports = [./hardware.nix ./networking.nix];

  modules = {
    hardware = {
      grub = {
        enable = true;
        theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
      };
      monitors = {
        enable = true;
        layout = [
          {
            output = "HDMI-A-0";
            monitorConfig = ''
              Option "Mode" "1920x1080"
              Option "PreferredMode" "1920x1080"
              Option "Position" "3000 440"
            '';
          }
          {
            output = "DisplayPort-0";
            primary = true;
            monitorConfig = ''
              Option "Mode" "1920x1080"
              Option "PreferredMode" "1920x1080"
              Option "Position" "1080 393"
            '';
          }
          {
            output = "DisplayPort-1";
            monitorConfig = ''
              Option "Mode" "1920x1080"
              Option "PreferredMode" "1920x1080"
              Option "Position" "0 0"
              Option "Rotate" "left"
            '';
          }
        ];
      };
      sound.enable = true;
      amdgpu.enable = true;
      docker.enable = true;
      yubikey.enable = true;
    };
    desktop = {
      apps.enable = true;
      sddm.enable = true;
      hyprland.enable = true;
    };
    services = {
      polkit.enable = true;
    };
  };
}
