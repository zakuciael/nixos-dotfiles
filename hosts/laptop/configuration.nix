{
  config,
  lib,
  pkgs,
  inputs,
  username,
  dotfiles,
  ...
}:
with lib.my;
with lib.my.utils; let
  colorScheme = inputs.nix-colors.colorSchemes.catppuccin-mocha;
in {
  imports = [./hardware.nix ./networking.nix];

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
    gtk.gtk3.bookmarks = let
      homeDirectory = config.home-manager.users.${username}.home.homeDirectory;
    in [
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
            workspaces = mkLayoutWorkspaces [1 2 3 4 5 6 7 8 9];
            wallpaper = dotfiles.wallpapers.pc."main.png".source;
          }
        ];
      };
      sound.enable = true;
      # amdgpu.enable = true;
      # docker.enable = true;
      # yubikey.enable = true;
    };
    desktop = {
      apps.enable = true;
      sddm.enable = true;
      wm.hyprland.enable = true;
    };
    services = {
      polkit.enable = true;
      gnome-keyring.enable = true;
      # wallpaper.enable = true;
      ssh = {
        enable = true;
        server = {
          enable = true;
        };
      };
    };
    dev = {
      tools.enable = true;
      # kubernetes.enable = true;
      # ides = ["rust-rover" "webstorm" "idea-ultimate" "rider"];
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