{
  config,
  lib,
  pkgs,
  inputs,
  username,
  dotfiles,
  ...
}:
with lib.my; let
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

  # ZSA keyboard configuration
  hardware.keyboard.zsa.enable = true;
  environment.systemPackages = with pkgs; [wally-cli];

  modules = {
    hardware = {
      grub = {
        enable = true;
        resolution = "1920x1080";
        theme = inputs.distro-grub-themes.nixos-grub-theme;
      };
      layout = {
        enable = true;
        layout = let
          mkWorkspaces = names:
            builtins.listToAttrs (builtins.map (name: let
                fixedName =
                  if builtins.typeOf name == "string"
                  then name
                  else (toString name);
              in {
                name = fixedName;
                value = {
                  keybinds = [fixedName (mapper.mapKeyToNumpad name)];
                };
              })
              names);
        in [
          {
            # Left
            monitor = {
              xorg = "DisplayPort-1";
              wayland = "DP-2";
            };
            mode = "1920x1080";
            pos = {
              x = 0;
              y = 0;
            };
            rotate = "left";
            workspaces = mkWorkspaces [4 5 6];
            wallpaper = dotfiles.wallpapers.pc."left.png".source;
          }
          {
            # Main
            monitor = {
              xorg = "DisplayPort-0";
              wayland = "DP-1";
            };
            primary = true;
            mode = "1920x1080";
            pos = {
              x = 1080;
              y = 393;
            };
            workspaces = mkWorkspaces [1 2 3];
            wallpaper = dotfiles.wallpapers.pc."main.png".source;
          }
          {
            # Right
            monitor = {
              xorg = "HDMI-A-0";
              wayland = "HDMI-A-1";
            };
            mode = "1920x1080";
            pos = {
              x = 3000;
              y = 440;
            };
            workspaces = mkWorkspaces [7 8 9];
            wallpaper = dotfiles.wallpapers.pc."right.jpg".source;
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
      wm.hyprland.enable = true;
      gaming = {
        enable = true;
        steam.enable = true;
        mihoyo.enable = true;
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
    };
    dev = {
      tools.enable = true;
      kubernetes.enable = true;
      ides = ["rust-rover" "webstorm" "idea-ultimate" "rider"];
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
