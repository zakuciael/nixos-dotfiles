{
  config,
  system,
  inputs,
  username,
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
        settings.workspaces = [
          # Main monitor
          {
            selector = "1";
            default = true;
            monitor = monitors.main.wayland;
          }
          {
            selector = "2";
            monitor = monitors.main.wayland;
          }
          {
            selector = "3";
            monitor = monitors.main.wayland;
          }

          # Left vertical monitor
          {
            selector = "4";
            default = true;
            monitor = monitors.left.wayland;
          }
          {
            selector = "5";
            monitor = monitors.left.wayland;
          }
          {
            selector = "6";
            monitor = monitors.left.wayland;
          }

          # Right monitor
          {
            selector = "7";
            default = true;
            monitor = monitors.right.wayland;
          }
          {
            selector = "8";
            monitor = monitors.right.wayland;
          }
          {
            selector = "9";
            monitor = monitors.right.wayland;
          }
        ];
      };
    };
    services = {
      polkit.enable = true;
    };
  };
}
