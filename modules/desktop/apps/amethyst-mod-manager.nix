{
  inputs,
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username} = {
    home.packages = [ inputs.amethyst-mod-manager.packages.default ];

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
