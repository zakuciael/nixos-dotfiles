{
  lib,
  inputs,
  username,
  ...
}:
with lib.my; {
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
    };
    services = {
      polkit.enable = true;
      gnome-keyring.enable = true;
    };
  };
}
