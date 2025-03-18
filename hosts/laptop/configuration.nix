{
  config,
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

  environment = {
    variables = {
      FLAKE = "/home/${username}/dev/config/nixos-dotfiles";
    };
  };

  # Color theme configuration
  catppuccin.flavor = "mocha";

  # User settings
  home-manager.users."${username}" = {
    # nix-colors color scheme
    inherit colorScheme;

    # Custom bookmarks
    gtk.gtk3.bookmarks =
      let
        homeDirectory = config.home-manager.users.${username}.home.homeDirectory;
      in
      [
        (utils.mkGtkBookmark {
          name = "Development";
          path = "${homeDirectory}/dev";
        })
        (utils.mkGtkBookmark {
          name = "NixOS Config";
          path = "${homeDirectory}/dev/config/nixos-dotfiles";
        })
      ];
  };

  # Secret management configuration
  sops.age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  users.users.${username} = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIATlv70/tWh3bGxYH1WshsBo/v7FnqvQ8kn0I1BW/pZF"
    ];
  };

  modules = {
    hardware = {
      grub = {
        enable = true;
        resolution = "1920x1080";
        theme = inputs.distro-grub-themes.nixos-grub-theme;
      };
      layout = {
        enable = true;
        layout = [
          {
            name = "main";
            monitor = {
              xorg = "eDP1";
              wayland = "eDP-1";
            };
            mode = "1920x1080";
            scale = 1.2;
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
            wallpaper = dotfiles.wallpapers.laptop."main.jpeg".source;
          }
        ];
      };
      printer.enable = true;
      bluetooth.enable = true;
      sound.enable = true;
      docker.enable = true;
      yubikey.enable = true;
      nfc.enable = true;
    };
    desktop = {
      apps.enable = true;
      sddm.enable = true;
      wm.hyprland.enable = true;
    };
    services = {
      polkit.enable = true;
      gnome-keyring.enable = true;
      wallpaper.enable = true;
      samba = {
        enable = true;
        shares = {
          "/media/shares/Dev\ Resources" = {
            url = "//51.83.129.177/dev resources";
            secret = "development";
          };
          "/media/shares/Dev\ Tools" = {
            url = "//51.83.129.177/dev tools";
            secret = "development";
          };
        };
      };
      ssh = {
        enable = true;
        server = {
          enable = true;
        };
      };
    };
    dev = {
      tools.enable = true;
      vscode = {
        enable = true;
        server = true;
      };
      kubernetes.enable = true;
      ides = [
        "idea-ultimate"
        "rust-rover"
        "goland"
      ];
      nostale = {
        enable = true;
        installPath = "/media/games/linux/Other/NosTale";
      };
    };
    shell = {
      tmux.enable = true;
      nix.enable = true;
      direnv.enable = true;
      starship.enable = true;
      zoxide.enable = true;
      eza.enable = true;
      bat.enable = true;
      tools.enable = true;
    };
  };
}
