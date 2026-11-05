{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib)
    getExe
    mkIf
    mkEnableOption
    mkMerge
    ;
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
    vr.enable = mkEnableOption "SteamVR / Steam Frame (wireless adapter + async reprojection)";
  };

  config = mkIf cfg.enable (mkMerge [
    {
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

        wayland.windowManager.hyprland.settings.window_rule =
          lib.optionals config.modules.desktop.wm.hyprland.enable
            [
              {
                name = "Steam Notifications Fix";
                match = {
                  class = "^(steam)$";
                  title = "^(notificationtoasts)";
                };

                inherit monitor;
                float = true;
                no_focus = true;
                no_initial_focus = true;
                move = "100%-w-8 100%-h-8";
              }
            ];
      };

      environment.systemPackages = with pkgs; [
        mangohud
        gamescope-wsi # For HDR support in gamescope
        protonup-qt
        pkgsCross.mingw32.wine-discord-ipc-bridge
      ];

      programs = {
        # Support for games distributed as AppImages
        appimage = {
          enable = true;
          binfmt = true;
        };

        steam = {
          enable = true; # also enables hardware.steam-hardware (uinput + Valve udev)
          protontricks.enable = true;
          extest.enable = true;

          # Also required for Steam Frame / Steam Link discovery + vrlink
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
              [ p.pkgsCross.mingw32.wine-discord-ipc-bridge ]
              ++ (lib.optionals config.programs.gamemode.enable [ p.gamemode ])
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
        description = "Steam";
        script =
          "${getExe steamPkg} -nochatui -nofriendsui -silent"
          + lib.optionalString cfg.vr.enable " -pipewire"
          + " %U";
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
    }

    # SteamVR / Steam Frame — needs kernel ≥ 7.2 + redistributable firmware (hosts/*/hardware.nix).
    (mkIf cfg.vr.enable {
      environment.systemPackages = with pkgs; [
        iw # regdom / phy checks + Frame sideload / management tools
        wayvr
        frameloader
        frame-control
      ];

      # Frame wireless adapter (RTL8852CU / 28de:2432, rtw89_8852cu); Steam drives it via NetworkManager.
      users.users.${username}.extraGroups = [ "networkmanager" ];
      hardware.wirelessRegulatoryDatabase = true; # installs regulatory.db; country is set below
      networking.networkmanager.wifi.backend = "wpa_supplicant"; # iwd fails 6 GHz / hidden Frame SSID scans
      # World domain (00) disables 6 GHz; set a real country (PL) so 5945–6425 MHz is usable.
      boot.extraModprobeConfig = ''
        options cfg80211 ieee80211_regdom=PL
      '';

      # SteamVR async reprojection — patched amdgpu out-of-tree (pkgs/amdgpu-steam-vr).
      boot.extraModulePackages = [
        (pkgs.amdgpu-steam-vr.override {
          kernel = config.boot.kernelPackages.kernel;
        })
      ];

      home-manager.users.${username} = {
        # frame-control://install links from websites (see Frame Control web-install docs)
        xdg.mimeApps = {
          defaultApplications = {
            "x-scheme-handler/frame-control" = [ "frame-control.desktop" ];
          };
          associations.added = {
            "x-scheme-handler/frame-control" = [ "frame-control.desktop" ];
          };
        };

        xdg.configFile = {
          "openxr/1/active_runtime.json".text = builtins.toJSON {
            file_format_version = "1.0.0";
            runtime = {
              VALVE_runtime_is_steamvr = true;
              library_path = "${hmConfig.home.homeDirectory}/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrclient.so";
              name = "SteamVR";
            };
          };
          "openxr/1/active_runtime.i686.json".text = builtins.toJSON {
            file_format_version = "1.0.0";
            runtime = {
              VALVE_runtime_is_steamvr = true;
              library_path = "bin/vrclient.so";
              name = "SteamVR";
            };
          };
        };
      };
    })
  ]);
}
