{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my; {
  home-manager.users.${username} = {
    home.packages = with pkgs; [btop];
    programs.btop.catppuccin.enable = true;
  };
}
