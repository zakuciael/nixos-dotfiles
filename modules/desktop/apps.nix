{
  config,
  lib,
  pkgs,
  inputs,
  username,
  ...
}:
with lib;
with builtins;
let
  cfg = config.modules.desktop.apps;
  mkAutostartModules =
    programs:
    builtins.listToAttrs (
      builtins.map (desktop: {
        name = desktop;
        value = {
          autostartPrograms = programs;
        };
      }) (builtins.attrNames config.modules.desktop.wm)
    );
in
{
  options.modules.desktop.apps = {
    enable = mkEnableOption "general desktop applications";
  };

  config = mkIf cfg.enable {
    programs.noisetorch.enable = true;

    home-manager.users.${username} = {
      programs.fish.shellAliases.open = "${getBin pkgs.xdg-utils}/bin/xdg-open";
      home.packages = with pkgs; [
        # Browser
        google-chrome

        # Files
        nemo
        libsForQt5.ark

        # Music, Videos, Photos, etc.
        spotify
        eog
        vlc-wayland
        gnome-text-editor
        gnome-calculator
        gnome-calendar

        # Other
        czkawka
        font-manager
        youtube-music
        errands
      ];
    };
  };
}
