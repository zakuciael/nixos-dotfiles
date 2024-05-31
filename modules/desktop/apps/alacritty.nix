{
  pkgs,
  username,
  ...
}: {
  home-manager.users.${username} = {
    # stylix.targets.alacritty.enable = true;

    programs.alacritty = {
      enable = true;
      catppuccin.enable = true;
      settings = {
        general = {
          shell = "${pkgs.fish}/bin/fish";
          "live_config_reload" = false;
        };
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
            family = "JetBrainsMono Nerd Font Mono";
            style = "Regular";
          };
          size = 11;
          builtin_box_drawing = true;
        };
        env.TERM = "xterm-256color";
      };
    };
  };
}
