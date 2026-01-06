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
    # Special case, since GParted doesn't work well when installed as user package.
    environment.systemPackages = with pkgs; [ gparted ];

    home-manager.users.${username} = {
      programs.fish.shellAliases.open = "${getBin pkgs.xdg-utils}/bin/xdg-open";
      home.packages = with pkgs; [
        # Browser
        (google-chrome.override {
          commandLineArgs = "--disable-features=WaylandWpColorManagerV1"; # FIXME: Remove when new version of Hyprland is merged to nixpkgs
        })

        # Files
        nemo
        kdePackages.ark

        # Music, Videos, Photos, etc.
        eog
        vlc
        mpv
        gnome-text-editor
        gnome-calculator
        gnome-calendar

        # Other
        czkawka
        font-manager
        pear-desktop # YouTube Music
        errands
        xclicker
        fluent-reader
        xournalpp
        figma-linux
        gitbutler
      ];
    };
  };
}
