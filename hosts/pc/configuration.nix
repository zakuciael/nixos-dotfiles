{
  lib,
  inputs,
  username,
  dotfiles,
  ...
}:
with lib.my;
with lib.my.utils;
let
  colorScheme = inputs.nix-colors.colorSchemes.catppuccin-mocha;
in
{
  imports = [
    ./hardware.nix
    ./networking.nix
  ];

  nix.settings = {
    max-jobs = 6;
    cores = 6;
  };

  # Color theme configuration
  catppuccin.flavor = "mocha";

  # User settings
  home-manager.users."${username}" = {
    # nix-colors color scheme
    inherit colorScheme;
  };

  # Secret management configuration
  sops = {
    age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
  };

  modules = {
    hardware = {
      grub = {
        enable = true;
        # resolution = "1920x1080";
        resolution = "2560x1440";
        theme = inputs.distro-grub-themes.nixos-grub-theme;
      };
      layout = {
        enable = true;
        layout = [
          {
            name = "left";
            monitor = {
              xorg = "HDMI-A-1";
              wayland = "HDMI-A-1";
            };
            mode = "1920x1080";
            pos = {
              x = 0;
              y = 60;
            };
            rotate = "left";
            workspaces = mkLayoutWorkspaces [
              4
              5
              6
            ];
            wallpaper = dotfiles.wallpapers.pc."left.png".source;
          }
          {
            name = "main";
            monitor = {
              xorg = "DP-1";
              wayland = "DP-1";
            };
            primary = true;
            mode = "2560x1440";
            pos = {
              x = 1080;
              y = 150;
            };
            workspaces = mkLayoutWorkspaces [
              1
              2
              3
            ];
            wallpaper = dotfiles.wallpapers.pc."main.png".source;
          }
          {
            name = "right";
            monitor = {
              xorg = "DP-2";
              wayland = "DP-2";
            };
            mode = "1920x1080";
            pos = {
              x = 3640;
              y = 380;
            };
            workspaces = mkLayoutWorkspaces [
              7
              8
              9
            ];
            wallpaper = dotfiles.wallpapers.pc."right.jpg".source;
          }
        ];
      };
      bluetooth.enable = true;
      graphic-tablet.enable = true;
      printer.enable = true;
      sound.enable = true;
      docker.enable = true;
      yubikey.enable = true;
      peripherals.enable = true;
      corectrl = {
        enable = true;
        overclock = false;
      };
    };
    desktop = {
      apps.enable = true;
      sddm.enable = true;
      wm.hyprland = {
        enable = true;
        hdr.enable = true;
      };
      gaming = {
        enable = true;
        steam.enable = true;
        mihoyo.enable = true;
        minecraft.enable = true;
        heroic.enable = true;
        disks = {
          linux.device = "/dev/disk/by-partlabel/linux-games";
          windows.device = "/dev/disk/by-partlabel/windows-games";
        };
      };
    };
    services = {
      polkit.enable = true;
      gnome-keyring.enable = true;
      wallpaper.enable = true;
      ssh.enable = true;
      input-remapper.enable = true;
      # noisetorch = {
      #   enable = true;
      #   settings = {
      #     device = {
      #       id = "alsa_input.usb-Elgato_Systems_Elgato_Wave_3_BS26M1A01013-00.mono-fallback";
      #       unit = "sys-devices-pci0000:00-0000:00:08.1-0000:2f:00.3-usb3-3\\x2d4-3\\x2d4:1.0-sound-card0-controlC0.device";
      #     };
      #     threshold = 55;
      #   };
      # };
    };
    dev = {
      tools.enable = true;
      kubernetes.enable = true;
      ides = [
        "rust-rover"
        "idea"
        "rider"
        "clion"
        "datagrip"
        "goland"
      ];
      vscode = {
        enable = true;
        server = true;
      };
      nostale = {
        enable = true;
        installPath = "/media/games/linux/Other/NosTale";
      };
    };
    shell = {
      tmux.enable = true;
      direnv.enable = true;
      starship.enable = true;
      zoxide.enable = true;
      eza.enable = true;
      bat.enable = true;
      tools.enable = true;
    };
  };
}
