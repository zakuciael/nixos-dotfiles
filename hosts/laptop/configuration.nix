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
    max-jobs = 4;
    cores = 2;
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

  users.users.${username} = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIATlv70/tWh3bGxYH1WshsBo/v7FnqvQ8kn0I1BW/pZF"
    ];
  };

  modules = {
    hardware = {
      grub = {
        enable = true;
        resolution = "2560x1600";
        theme = inputs.distro-grub-themes.nixos-grub-theme;
      };
      layout = {
        enable = true;
        layout = [
          {
            name = "main";
            monitor = {
              xorg = "eDP2";
              wayland = "eDP-2";
            };
            mode = "2560x1600";
            scale = 1.60;
            workspaces = mkLayoutWorkspaces [
              1
              2
              3
              4
              5
              6
              7
              8
              9
            ];
            wallpaper = dotfiles.wallpapers.laptop."main.jpg".source;
          }
        ];
      };
      bluetooth.enable = true;
      graphic-tablet.enable = true;
      printer.enable = true;
      sound.enable = true;
      docker.enable = true;
      yubikey.enable = true;
    };
    desktop = {
      apps.enable = true;
      sddm.enable = true;
      wm.hyprland.enable = true;
      gaming = {
        enable = true;
        steam.enable = true;
        mihoyo.enable = true;
      };
    };
    services = {
      polkit.enable = true;
      gnome-keyring.enable = true;
      wallpaper.enable = true;
      ssh = {
        enable = true;
        server = {
          enable = true;
        };
      };
    };
    dev = {
      tools.enable = true;
      kubernetes.enable = true;
      browser.enable = true;
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
