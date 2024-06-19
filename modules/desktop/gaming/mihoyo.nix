{
  config,
  lib,
  username,
  ...
}:
with lib;
with lib.my;
with lib.my.utils; let
  cfg = config.modules.desktop.gaming.mihoyo;
  layout = findLayoutConfig config ({index, ...}: index == 1); # Main monitor
  monitor = getLayoutMonitor layout "wayland";
  launcherClass = "^(moe.launcher.an-anime-game-launcher)$";
  gameTitle = "^(Genshin Impact)$";
in {
  options.modules.desktop.gaming.mihoyo = {
    enable = mkEnableOption "miHoYo games";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      wayland.windowManager.hyprland.settings = {
        windowrulev2 = [
          "float, class:${launcherClass}"
          "size 70% 70%, class:${launcherClass}"
          "monitor ${monitor}, class:${launcherClass}"
          "monitor ${monitor}, title:${gameTitle}"
        ];
      };
    };

    programs.anime-game-launcher.enable = true;
  };
}
