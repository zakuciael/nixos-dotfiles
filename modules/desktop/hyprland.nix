{
  pkgs,
  lib,
  config,
  inputs,
  system,
  username,
  scripts,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.desktop.hyprland;
  desktopApps = apps.desktopApps config cfg;
  launcherScript = import scripts."rofi-launcher.nix".source {inherit pkgs;};
  powermenuScript = import scripts."rofi-powermenu.nix".source {inherit pkgs;};
in {
  options.modules.desktop.hyprland = {
    enable = mkEnableOption "Enable hyprland desktop";
  };

  config = mkIf (cfg.enable) (mkMerge (with desktopApps; [
    alacritty
    _1password
    rofi
    nh
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
              "$mod, W, killactive"
              "SHIFT CTRL, space, exec, ${launcherScript}/bin/rofi-launcher drun"
              "SHIFT CTRL, Q, exec, ${powermenuScript}/bin/rofi-powermenu"
            ];
            bindm = [
              "$mod, mouse:272, movewindow"
              "$mod, mouse:273, resizewindow"
            ];
          };
        };
      };
    }
  ]));
}
