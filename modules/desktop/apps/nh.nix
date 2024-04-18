{
  pkgs,
  unstable,
  lib,
  config,
  home-manager,
  username,
  ...
}:
with lib;
with lib.my; {
  programs.nh.enable = true;
}
