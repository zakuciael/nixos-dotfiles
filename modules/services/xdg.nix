{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.services.xdg;
  homeDirectory = config.home-manager.users.${username}.home.homeDirectory;
  userDirs = config.home-manager.users.${username}.xdg.userDirs;
in {
  options.modules.services.xdg = {
    enable = mkEnableOption "XDG user dirs";
  };

  config = mkIf (cfg.enable) {
    environment.systemPackages = [pkgs.xdg-user-dirs];

    systemd.user.services."xdg-user-dirs-update" = {
      description = "Update XDG user dir configuration";
      documentation = ["man:xdg-user-dirs-update(1)"];
      wantedBy = ["default.target"];
      script = "${pkgs.xdg-user-dirs}/bin/xdg-user-dirs-update";
      serviceConfig = {
        Type = "oneshot";
      };
    };

    home-manager.users.${username} = {
      gtk.gtk3.bookmarks = [
        (utils.mkGtkBookmark {
          name = "Documents";
          path = userDirs.documents;
        })
        (utils.mkGtkBookmark {
          name = "Downloads";
          path = userDirs.download;
        })
        (utils.mkGtkBookmark {
          name = "Videos";
          path = userDirs.videos;
        })
        (utils.mkGtkBookmark {
          name = "Pictures";
          path = userDirs.pictures;
        })
        (utils.mkGtkBookmark {
          name = "Music";
          path = userDirs.music;
        })
      ];

      xdg.userDirs = {
        enable = true;
        createDirectories = true;
        extraConfig = {
          XDG_SCREENSHOTS_DIR = "${homeDirectory}/Pictures/Screenshots/";
        };
      };
    };
  };
}
