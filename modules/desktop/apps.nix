{
  pkgs,
  lib,
  config,
  home-manager,
  ...
}:
with lib;
with builtins; let
  cfg = config.modules.desktop.apps;
in {
  options.modules.desktop.apps = {
    enable = mkEnableOption "Install desktop applications";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.zakuciael = {
      programs.fish.shellAliases.open = "xdg-open";
      home.packages = with pkgs; [
        discord
        vscode
        google-chrome
      ];
    };
  };
}
