{
  lib,
  pkgs,
  username,
  ...
}: let
  inherit (lib.my) mapper;
  whitesur-kde-opaque = pkgs.whitesur-kde.overrideAttrs {
    pname = "whitesur-kde-opaque";
    installPhase = ''
      runHook preInstall

      mkdir -p $out/doc

      name= ./install.sh --opaque

      mkdir -p $out/share/sddm/themes
      cp -a sddm/WhiteSur $out/share/sddm/themes/

      runHook postInstall
    '';
  };
in {
  programs.dconf.enable = true;

  home-manager.users.${username} = rec {
    home = {
      packages = with pkgs; [gnome.dconf-editor qt6Packages.qt6ct libsForQt5.qt5ct];

      sessionVariables = {
        QT_QPA_PLATFORMTHEME = "qt5ct";
        XCURSOR_PATH = "${gtk.cursorTheme.package}/share/icons";
        XCURSOR_SIZE = 24;
        XCURSOR_THEME = gtk.cursorTheme.name;
      };
    };

    qt = {
      enable = true;
      platformTheme = "qtct";
      style.name = "kvantum";
    };

    gtk = {
      enable = true;
      theme = {
        name = "WhiteSur-Dark";
        package = pkgs.whitesur-gtk-theme;
      };
      iconTheme = {
        name = "WhiteSur-dark";
        package = pkgs.whitesur-icon-theme.override {
          boldPanelIcons = true;
          alternativeIcons = true;
          themeVariants = ["default"];
        };
      };
      cursorTheme = {
        name = "WhiteSur-cursors";
        package = pkgs.whitesur-cursors;
        size = 24;
      };

      gtk4.extraConfig = {
        "gtk-application-prefer-dark-theme" = true;
      };
      gtk3.extraConfig = gtk.gtk4.extraConfig;
    };

    xdg.configFile = {
      "gtk-4.0/gtk.css".source = "${gtk.theme.package}/share/themes/${gtk.theme.name}/gtk-4.0/gtk.css";
      "gtk-4.0/gtk-dark.css".source = "${gtk.theme.package}/share/themes/${gtk.theme.name}/gtk-4.0/gtk-dark.css";
      "gtk-4.0/gtk.gresource".source = "${gtk.theme.package}/share/themes/${gtk.theme.name}/gtk-4.0/gtk.gresource";
      "Kvantum/WhiteSur".source = "${pkgs.whitesur-kde}/share/Kvantum/WhiteSur";
      "Kvantum/WhiteSur-opaque".source = "${whitesur-kde-opaque}/share/Kvantum/WhiteSur-opaque";
      "Kvantum/kvantum.kvconfig".source = mapper.toINI "kvantum.kvconfig" {
        General.theme = "WhiteSur-opaqueDark";
      };
    };
  };
}
