{
  config,
  inputs,
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
    programs = {
      ghostty = {
        enable = true;
        package = inputs.ghostty.default; # TODO: Replace when nixpkgs will fully support Ghostty
        shellIntegration.enable = true;
        settings = {
          # Font settings
          font-size = 11;
          font-family = "JetBrains Mono";

          # Color theme
          theme = "catppuccin-mocha"; # TODO: Replace when nixpkgs, home-manager and catppuccin/nix will fully support Ghostty

          # Other
          window-decoration = false;
        };
      };

      # Install configuration sytax for bat
      bat = {
        syntaxes.ghostty = {
          src = cfg.package;
          file = "share/bat/syntaxes/ghostty.sublime-syntax";
        };
        config.map-syntax = [ "${hmConfig.xdg.configHome}/ghostty/config:Ghostty Config" ];
      };
    };
  };
}
