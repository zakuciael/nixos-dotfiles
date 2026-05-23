{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib) getExe mkIf;
in
{
  home-manager.users.${username} = {
    home.packages = [ pkgs.vortex ];

    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/nxm" = [ "com.nexusmods.vortex.desktop" ];
    };
  };
}
