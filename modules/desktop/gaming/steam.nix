{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib) getExe mkIf mkEnableOption;
  inherit (lib.my.utils) findLayoutConfig getLayoutMonitor;
  inherit (lib.hm) dag;

  cfg = config.modules.desktop.gaming.steam;
  hmConfig = config.home-manager.users.${username};
  steamPkg = config.programs.steam.package;

  layout = findLayoutConfig config ({ name, ... }: name == "main"); # Main monitor
  monitor = getLayoutMonitor layout "wayland";

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

      wayland.windowManager.hyprland.settings.windowrule =
        lib.optionals config.modules.desktop.wm.hyprland.enable
          [
            {
              name = "Steam Notifications Fix";
              "match:class" = "^(steam)$";
              "match:title" = "^(notificationtoasts)";

              inherit monitor;
              float = true;
              no_focus = true;
              no_initial_focus = true;
              move = "100%-w-8 100%-h-8";
            }
          ];
    };

    environment = {
      systemPackages = with pkgs; [
        mangohud
        gamescope-wsi # For HDR support in gamescope
        protonup-qt
        pkgsCross.mingw32.wine-discord-ipc-bridge
      ];
    };

    programs = {
      # Support for games distributed as AppImages
      appimage = {
        enable = true;
        binfmt = true;
      };

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

        package = pkgs.steam.override {
          extraEnv = {
            MANGOHUD = "1";
            MANGOHUD_CONFIG = "read_cfg,no_display";
            GAMEMODERUN = "1";
            AMD_VULKAN_ICD = "RADV";
            WINEDLLOVERRIDES = "dxgi=n,b";
          };

          extraPkgs =
            p:
            (lib.optionals config.programs.gamemode.enable [ p.gamemode ])
            ++ (lib.optionals config.programs.gamescope.enable (
              with p;
              [
                libXcursor
                libXi
                libXinerama
                libXScrnSaver
                libpng
                libpulseaudio
                libvorbis
                stdenv.cc.cc.lib # Provides libstdc++.so.6
                libkrb5
                keyutils
              ]
            ));
        };

        extraCompatPackages = with pkgs; [
          proton-ge-bin
          steamtinkerlaunch
        ];
      };
    };

    systemd.user.services."steam" = {
      description = "Launch Steam";
      script = "${getExe steamPkg} -nochatui -nofriendsui -silent %U";

      after = [
        "graphical-session.target"
        "tray.target"
      ];
      requires = [ "graphical-session.target" ];
      wants = [ "tray.target" ];
      wantedBy = [ "graphical-session.target" ];

      unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";

      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 5;
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 3"; # Make sure tray is visible
      };
    };
  };
}
