{
  config,
  lib,
  pkgs,
  inputs,
  username,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.hm) dag;
  cfg = config.modules.desktop.gaming.steam;
  hmConfig = config.home-manager.users.${username};
in
{
  options.modules.desktop.gaming.steam = {
    enable = mkEnableOption "steam games";
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      "steam/api_key" = {
        owner = config.users.users.${username}.name;
        group = config.users.users.${username}.group;
        restartUnits = [ "steam-presence.service" ];
      };
      "steam/sgdb_api_key" = {
        owner = config.users.users.${username}.name;
        group = config.users.users.${username}.group;
        restartUnits = [ "steam-presence.service" ];
      };
    };

    home-manager.users.${username} = {
      home.activation.createSteamDesktopLink =
        let
          desktopEntriesDirectory = "${hmConfig.xdg.dataHome}/applications";
          desktopDirectory = "${hmConfig.xdg.userDirs.desktop}";
        in
        dag.entryBefore [ "createXdgUserDirectories" ] ''
          [[ -L "${desktopEntriesDirectory}" ]] || run mkdir -p $VERBOSE_ARG "${desktopEntriesDirectory}"
          [[ -L "${desktopDirectory}" ]] || run ln -s $VERBOSE_ARG "${desktopEntriesDirectory}" "${desktopDirectory}"
        '';
    };

    environment = {
      systemPackages = with pkgs; [ mangohud ];
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

        presence = {
          enable = true;
          steamApiKeyFile = config.sops.secrets."steam/api_key".path;
          userIds = [ "76561198131289262" ];

          fetchSteamRichPresence = true;
          fetchSteamReviews = false;
          addSteamStoreButton = false;
          webScrape = false;
          coverArt = {
            steamGridDB = {
              enable = true;
              apiKeyFile = config.sops.secrets."steam/sgdb_api_key".path;
            };
            useSteamStoreFallback = true;
          };
        };

        extraCompatPackages = [
          pkgs.proton-ge-bin
          pkgs.steamtinkerlaunch
          inputs.nostale-dev-env.packages.proton-ge-nostale
        ];
      };
    };
  };
}
