{
  config,
  username,
  desktop,
  ...
}:
let
  hmConfig = config.home-manager.users.${username};
  cfg = hmConfig.programs.ghostty;
in
{
  modules.desktop.wm.${desktop}.terminalPackage = cfg.package;

  home-manager.users.${username} = {
    catppuccin.ghostty.enable = true;

    programs = {
      ghostty = {
        enable = true;
        enableBashIntegration = true; # By default enable at least bash integration.
        enableFishIntegration = config.modules.shell.fish.enable;
        installBatSyntax = config.modules.shell.bat.enable;

        settings = {
          # Font settings
          font-size = 11;
          font-family = "JetBrains Mono";

          # Other
          window-decoration = false;
        };
      };
    };
  };
}
