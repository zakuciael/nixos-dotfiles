{
  pkgs,
  username,
  config,
  lib,
  ...
}:
with lib; let
  colorScheme = config.home-manager.users.${username}.colorScheme;
in {
  home-manager.users.${username}.programs.alacritty = {
    enable = true;
    settings = {
      general = {
        shell = "${pkgs.fish}/bin/fish";
        "live_config_reload" = false;
      };
      env.TERM = "xterm-256color";

      colors = assert assertMsg (colorScheme.author != "") "You need to select a nix-colors theme to use this Alacritty config"; (with colorScheme.palette; {
        bright = {
          black = "0x${base00}";
          blue = "0x${base0D}";
          cyan = "0x${base0C}";
          green = "0x${base0B}";
          magenta = "0x${base0E}";
          red = "0x${base08}";
          white = "0x${base06}";
          yellow = "0x${base09}";
        };
        cursor = {
          cursor = "0x${base06}";
          text = "0x${base06}";
        };
        normal = {
          black = "0x${base00}";
          blue = "0x${base0D}";
          cyan = "0x${base0C}";
          green = "0x${base0B}";
          magenta = "0x${base0E}";
          red = "0x${base08}";
          white = "0x${base06}";
          yellow = "0x${base0A}";
        };
        primary = {
          background = "0x${base00}";
          foreground = "0x${base06}";
        };
      });
    };
  };
}
