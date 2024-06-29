{
  pkgs,
  unstable,
  username,
  ...
}: {
  programs.dconf.enable = true;

  home-manager.users.${username} = rec {
    home = {
      packages = with pkgs; [gnome.dconf-editor];

      sessionVariables = {
        XCURSOR_PATH = "${gtk.cursorTheme.package}/share/icons";
        XCURSOR_SIZE = 24;
        XCURSOR_THEME = gtk.cursorTheme.name;
      };
    };

    gtk = {
      enable = true;
      theme = {
        name = "WhiteSur-Dark";
        package = pkgs.whitesur-gtk-theme;
      };
      iconTheme = {
        name = "WhiteSur-dark";
        package = unstable.whitesur-icon-theme.override {
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
    };
  };
}
