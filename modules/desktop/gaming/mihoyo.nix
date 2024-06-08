{
  config,
  lib,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.desktop.gaming.mihoyo;
in {
  options.modules.desktop.gaming.mihoyo = {
    enable = mkEnableOption "miHoYo games";
  };

  config = mkIf (cfg.enable) {
    programs.anime-game-launcher.enable = true;
  };
}
