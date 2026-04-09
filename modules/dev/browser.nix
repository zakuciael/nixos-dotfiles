{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf getExe;
  inherit (pkgs) makeDesktopItem;
  cfg = config.modules.dev.browser;

  browserFolder = "/home/google-chrome-dev";
in
{
  options.modules.dev.browser = {
    enable = mkEnableOption "browser for development";
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = [
        (makeDesktopItem {
          name = "google-chrome-dev";
          desktopName = "Google Chrome (Dev)";
          icon = "google-chrome";
          exec = ''
            env HOME=${browserFolder} ${getExe pkgs.google-chrome} --profile-directory=google-chrome-dev
          '';
        })
      ];
    };

    system.activationScripts."generate-dev-browser-folder" = /* bash */ ''
      mkdir -p ${browserFolder}
    '';
  };
}
