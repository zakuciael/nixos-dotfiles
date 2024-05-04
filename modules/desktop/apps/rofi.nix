{
  lib,
  pkgs,
  username,
  dotfiles,
  ...
}:
with lib;
with lib.my; {
  home-manager.users.${username} = {
    home.packages = with pkgs; [rofi-wayland];
    xdg.configFile.rofi.source = dotfiles.rofi.source;
  };
}
