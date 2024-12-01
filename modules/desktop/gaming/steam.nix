{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop.gaming.steam;
in {
  options.modules.desktop.gaming.steam = {
    enable = mkEnableOption "steam games";
  };

  config = mkIf (cfg.enable) {
    environment = {
      systemPackages = with pkgs; [mangohud];
    };

    programs = {
      gamescope.enable = true;
      gamemode.enable = true;
      steam = {
        enable = true;
        protontricks.enable = true;
        extest.enable = true;

        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;

        extraCompatPackages = with pkgs; [proton-ge-bin];
      };
    };
  };
}
