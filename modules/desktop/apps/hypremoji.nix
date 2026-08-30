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

    wayland.windowManager.hyprland.settings =
      let
        inherit (lib.my.utils.hypr) mkBind withMod dsp;
      in
      mkIf config.modules.desktop.wm.hyprland.enable {
        bind = [
          (mkBind (withMod "Period") (dsp.exec (getExe pkgs.hypremoji)))
        ];

        window_rule = [
          {
            name = "HyprEmoji";
            float = true;
            move = "(cursor_x-(window_w*0.5)) (cursor_y-(window_h*0.05))";
            match.title = "^(HyprEmoji)$";
          }
        ];
      };
  };
}
