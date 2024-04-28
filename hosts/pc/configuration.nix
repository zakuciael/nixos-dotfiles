{
  system,
  inputs,
  username,
  mapper,
  ...
}: let
  monitors = {
    main = {
      xserver = "DisplayPort-0";
      wayland = "DP-1";
    };
    left = {
      xserver = "DisplayPort-1";
      wayland = "DP-2";
    };
    right = {
      xserver = "HDMI-A-0";
      wayland = "HDMI-A-1";
    };
  };
in {
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
            output = monitors.main;
            primary = true;
            mode = "1920x1080";
            position = "1080x393";
          }
          {
            output = monitors.left;
            mode = "1920x1080";
            position = "0x0";
            rotate = "left";
          }
          {
            output = monitors.right;
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
      hyprland = {
        enable = true;
        monitorBinds = [
          {
            monitor = monitors.main.wayland;
            key = mapper.mapKeyToNumpad 1;
          }
          {
            monitor = monitors.left.wayland;
            key = mapper.mapKeyToNumpad 2;
          }
          {
            monitor = monitors.right.wayland;
            key = mapper.mapKeyToNumpad 3;
          }
        ];
      };
    };
    services = {
      polkit.enable = true;
    };
  };
}
