{
  pkgs,
  lib,
  config,
  username,
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
    programs.noisetorch.enable = true;

    home-manager.users.${username} = {
      programs.fish.shellAliases.open = "xdg-open";
      home.packages = with pkgs; [
        discord
        vesktop
        vscode
        google-chrome
        warp-terminal
        wakatime
      ];
    };
  };
}
