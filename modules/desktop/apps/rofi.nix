{
  pkgs,
  lib,
  username,
  dotfiles,
  scripts,
  ...
}:
with lib;
with lib.my; let
  launcherScript = import scripts."rofi-launcher.nix".source {inherit pkgs;};
  powermenuScript = import scripts."rofi-powermenu.nix".source {inherit pkgs;};
in {
  home-manager.users.${username} = {
    home.packages = with pkgs; [rofi-wayland launcherScript powermenuScript];
    xdg.configFile.rofi.source = dotfiles.rofi.source;
  };
}
