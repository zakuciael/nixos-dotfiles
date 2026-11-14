{
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username} = {
    home.packages = [ pkgs.motrix ];

    xdg.mimeApps.defaultApplications = {
      "application/x-bittorrent" = [ "motrix.desktop" ];
      "x-scheme-handler/mo" = [ "motrix.desktop" ];
      "x-scheme-handler/motrix" = [ "motrix.desktop" ];
      "x-scheme-handler/magnet" = [ "motrix.desktop" ];
      "x-scheme-handler/thunder" = [ "motrix.desktop" ];
    };
  };
}
