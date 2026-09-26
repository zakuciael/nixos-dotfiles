{
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username} = {
    home.packages = [ pkgs.amethyst-mod-manager ];

    xdg.mimeApps = {
      defaultApplications = {
        "x-scheme-handler/nxm" = [ "amethystmodmanager-nxm.desktop" ];
      };
      associations.added = {
        "x-scheme-handler/nxm" = [ "amethystmodmanager-nxm.desktop" ];
      };
    };
  };
}
