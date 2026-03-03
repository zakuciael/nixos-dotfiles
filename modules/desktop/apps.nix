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

      # Default apps
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "google-chrome.desktop";
          "x-scheme-handler/http" = "google-chrome.desktop";
          "x-scheme-handler/https" = "google-chrome.desktop";
          "x-scheme-handler/about" = "google-chrome.desktop";
          "x-scheme-handler/unknown" = "google-chrome.desktop";

          "image/png" = "org.gnome.eog.desktop";
          "image/jpeg" = "org.gnome.eog.desktop";
          "image/webp" = "org.gnome.eog.desktop;";

          "text/markdown" = "org.gnome.TextEditor.desktop";
          "text/x-log" = "org.gnome.TextEditor.desktop";
          "application/json" = "org.gnome.TextEditor.desktop";
          "text/plain" = "org.gnome.TextEditor.desktop";
        };
        associations.added = {
          "image/png" = "org.gnome.eog.desktop";
          "image/jpeg" = "org.gnome.eog.desktop";
          "image/webp" = "org.gnome.eog.desktop;";

          "text/markdown" = "org.gnome.TextEditor.desktop";
          "text/x-log" = "org.gnome.TextEditor.desktop";
          "application/json" = "org.gnome.TextEditor.desktop";
          "text/plain" = "org.gnome.TextEditor.desktop";
        };
      };

      home.packages = with pkgs; [
        # Browser
        (google-chrome.override {
          commandLineArgs = "--disable-features=WaylandWpColorManagerV1"; # FIXME: Remove when new version of Hyprland is merged to nixpkgs
        })

        # Files
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
        gitkraken
      ];
    };
  };
}
