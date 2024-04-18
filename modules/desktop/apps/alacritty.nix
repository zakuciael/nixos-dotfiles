{
  pkgs,
  username,
  ...
}: {
  home-manager.users.${username}.programs.alacritty = {
    enable = true;
    settings = {
      general = {
        shell = "${pkgs.fish}/bin/fish";
        "live_config_reload" = false;
      };
      env.TERM = "xterm-256color";
    };
  };
}
