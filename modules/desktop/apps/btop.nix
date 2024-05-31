{username, ...}: {
  home-manager.users.${username} = {
    programs.btop = {
      enable = true;
      catppuccin.enable = true;
    };
  };
}
