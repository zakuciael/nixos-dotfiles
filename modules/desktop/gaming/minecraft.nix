{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my;
with lib.my.utils;
let
  cfg = config.modules.desktop.gaming.minecraft;
  layout = findLayoutConfig config ({ name, ... }: name == "main"); # Main monitor
  monitor = getLayoutMonitor layout "wayland";
in
{
  options.modules.desktop.gaming.minecraft = {
    enable = mkEnableOption "minecraft";
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = with pkgs; [ prismlauncher ];

      wayland.windowManager.hyprland.settings = {
        windowrule = [
          {
            name = "Minecraft";
            inherit monitor;
            float = true;
            center = true;
            maximize = true;
            "match:class" = "(Minecraft)";
          }
        ];
      };
    };
  };
}
