{
  system,
  inputs,
  username,
  ...
}: {
  imports = [./hardware.nix ./networking.nix];

  environment = {
    variables = {
      FLAKE = "/home/${username}/dev/config/nixos-dotfiles";
    };
  };

  home-manager.users.${username}.colorScheme = inputs.nix-colors.colorSchemes.catppuccin-mocha;

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
            output = {
              xserver = "DisplayPort-0";
              wayland = "DP-1";
            };
            primary = true;
            mode = "1920x1080";
            position = "1080x393";
          }
          {
            output = {
              xserver = "DisplayPort-1";
              wayland = "DP-2";
            };
            mode = "1920x1080";
            position = "0x0";
            rotate = "left";
          }
          {
            output = {
              xserver = "HDMI-A-0";
              wayland = "HDMI-A-1";
            };
            mode = "1920x1080";
            position = "3000x440";
          }
        ];
      };
      sound.enable = true;
      amdgpu.enable = true;
      docker.enable = true;
      yubikey.enable = true;
      keyring.enable = true;
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
