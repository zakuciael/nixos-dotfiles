{
  config,
  lib,
  pkgs,
  username,
  desktop,
  ...
}:
let
  inherit (lib) getExe;
  nemo = pkgs.nemo-with-extensions.override {
    useDefaultExtensions = true;
    extensions = with pkgs; [
      nemo-preview
    ];
  };
in
{
  home-manager.users.${username} = {
    home.packages = [
      nemo
    ];

    xdg = {
      desktopEntries.nemo = {
        name = "Nemo";
        exec = "${nemo}/bin/nemo";
      };
      mimeApps = {
        defaultApplications = {
          "inode/directory" = [ "nemo.desktop" ];
          "application/x-gnome-saved-search" = [ "nemo.desktop" ];
        };
      };
    };

    dconf = {
      settings = {
        "org/cinnamon/desktop/applications/terminal" = {
          exec = "${getExe config.modules.desktop.wm.${desktop}.terminalPackage}";
          # exec-arg = ""; # argument
        };
      };
    };
  };
}
