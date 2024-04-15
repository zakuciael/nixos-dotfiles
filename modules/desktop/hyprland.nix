{
  pkgs,
  lib,
  config,
  inputs,
  system,
  home-manager,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.desktop.hyprland;
  desktopApps = apps.desktopApps config cfg;
in {
  options.modules.desktop.hyprland = {
    enable = mkEnableOption "Enable hyprland desktop";
  };

  config = mkIf (cfg.enable) (mkMerge (with desktopApps; [
    alacritty
    _1password
    rofi
    {
      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${system}.hyprland;
        xwayland.enable = true;
      };

      home-manager.users.${username} = {
        imports = [inputs.hyprland.homeManagerModules.default];

        wayland.windowManager.hyprland = {
          enable = true;

          settings = {
            "$mod" = "SUPER";
            bind = [
              "$mod, return, exec, alacritty"
            ];
          };
        };
      };
    }
  ]));
}
