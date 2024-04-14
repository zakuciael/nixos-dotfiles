{
  config,
  pkgs,
  lib,
  ...
}: {
  home = {
    stateVersion = "23.11";
    username = "zakuciael";
    homeDirectory = "/home/zakuciael";
    packages = with pkgs; [
      (import ../../scripts/fix_elgato.nix {inherit pkgs;})
    ];
  };
}
