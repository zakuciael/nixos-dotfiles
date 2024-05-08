{
  pkgs,
  inputs,
  username,
  dotfiles,
  ...
}: {
  home-manager.users.${username} = {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      plugins = [inputs.rofi-jetbrains.default];
    };

    xdg.configFile.rofi.source = dotfiles.rofi.source;
  };
}
