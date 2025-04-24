{
  config,
  lib,
  username,
  desktop,
  ...
}:
let
  inherit (lib) getExe;
  hmConfig = config.home-manager.users.${username};
in
{
  modules.desktop.wm.${desktop}.terminalPackage = hmConfig.programs.alacritty.package;

  home-manager.users.${username} = {
    programs = {
      alacritty = {
        enable = true;
        catppuccin.enable = true;
        settings = {
          shell = getExe config.users.users.${username}.shell;
          "live_config_reload" = false;
          window = {
            padding = {
              x = 10;
              y = 10;
            };
            opacity = 0.9;
            blur = true;
            dynamic_padding = true;
            dynamic_title = true;
          };
          scrolling.history = 100000;
          font = {
            normal = {
              family = "JetBrains Mono";
              style = "Regular";
            };
            size = 11;
            builtin_box_drawing = true;
          };
          env.TERM = "xterm-256color";
        };
      };
    };
  };
}
