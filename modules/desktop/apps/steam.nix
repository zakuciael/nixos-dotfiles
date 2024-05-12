{
  lib,
  pkgs,
  ...
}:
with lib;
with lib.my; {
  environment = {
    systemPackages = with pkgs; [mangohud steam-run];
  };

  programs = {
    gamescope.enable = true;
    gamemode.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
      extraCompatPackages = with pkgs; [proton-ge-bin];
    };
  };
}
