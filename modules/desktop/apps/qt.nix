{
  config,
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
  home-manager.users.${username} = {
    home.packages = with pkgs; [qt6Packages.qt6ct libsForQt5.qt5ct];

    sessionVariables = {
      QT_QPA_PLATFORMTHEME = "qt5ct";
      QT_QPA_PLATFORM = "wayland;xcb";
    };

    qt = {
      enable = true;
      platformTheme = "qtct";
      style.name = "kvantum";
    };

    xdg.configFile = {
      "Kvantum/WhiteSur".source = "${pkgs.whitesur-kde}/share/Kvantum/WhiteSur";
      "Kvantum/WhiteSur-opaque".source = "${whitesur-kde-opaque}/share/Kvantum/WhiteSur-opaque";
      "Kvantum/kvantum.kvconfig".source = mapper.toINI "kvantum.kvconfig" {
        General.theme = "WhiteSur-opaqueDark";
      };
    };
  };
}
