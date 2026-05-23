{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib) getExe mkIf;
in
{
  home-manager.users.${username} = {
    home.packages = [ pkgs.hypremoji ];

    wayland.windowManager.hyprland.settings = mkIf config.modules.desktop.wm.hyprland.enable {
      bind = [
        "$mod, period, exec, ${getExe pkgs.hypremoji}"
      ];

      windowrule = [
        {
          name = "HyprEmoji";
          float = true;
          move = "(cursor_x-(window_w*0.5)) (cursor_y-(window_h*0.05))";
          "match:title" = "^(HyprEmoji)$";
        }
      ];
    };
  };
}
