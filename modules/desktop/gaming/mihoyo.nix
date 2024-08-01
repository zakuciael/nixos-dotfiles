{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my;
with lib.my.utils; let
  inherit (pkgs) makeDesktopItem fetchurl symlinkJoin;
  inherit (pkgs.stdenv) mkDerivation;
  cfg = config.modules.desktop.gaming.mihoyo;
  layout = findLayoutConfig config ({index, ...}: index == 1); # Main monitor
  monitor = getLayoutMonitor layout "wayland";
  launcherClass = "^(moe.launcher.an-anime-game-launcher)$";
  gameTitle = "^(Genshin Impact)$";

  mkGameShortcut = {
    name,
    desktopName,
    iconSrc,
    package,
  }: let
    icon = mkDerivation {
      name = "${name}-icon";
      src = iconSrc;
      nativeBuildInputs = with pkgs; [libicns];
      buildCommand = ''
        cp "${iconSrc}" ./${name}.icns
        chmod -R u+w -- "./${name}.icns"
        mkdir -p "$out/share/pixmaps/"

        TMP_DIR=$(mktemp -d mihoyo-icon.XXXXXXXXXX)
        icns2png -x -d 32 -s 512 -o "$TMP_DIR" "./${name}.icns"
        cp "$TMP_DIR/${name}_512x512x32.png" "$out/share/pixmaps/${name}.png"
      '';
    };
    desktopEntry = makeDesktopItem {
      inherit name desktopName;
      genericName = desktopName;
      exec = "${getExe package} --run-game";
      categories = ["Game"];
      icon = name;
    };
  in
    symlinkJoin {
      inherit name;
      paths = [icon desktopEntry];
      meta = with lib; {
        description = "A shortcut for ${desktopName}";
        license = licenses.unlicense;
        maintainers = with maintainers; [zakuciael];
        platforms = platforms.linux;
      };
    };
in {
  options.modules.desktop.gaming.mihoyo = {
    enable = mkEnableOption "miHoYo games";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      home.packages = [
        (mkGameShortcut {
          name = "genshin-impact";
          desktopName = "Genshin Impact";
          iconSrc = fetchurl {
            url = "https://parsefiles.back4app.com/JPaQcFfEEQ1ePBxbf6wvzkPMEqKYHhPYv8boI1Rc/3c03a44960ac2060be92bd7182c35e83_F5ttFHp0ag.icns";
            hash = "sha256-jEa14o2TqUVuSzgpA8hvWmUedwoKt39iEwrn6NPzBKU=";
          };
          package = config.programs.anime-game-launcher.package;
        })
      ];

      wayland.windowManager.hyprland.settings = {
        windowrulev2 = [
          "float, class:${launcherClass}"
          "size 70% 70%, class:${launcherClass}"
          "monitor DP-1, class:${launcherClass}"
          "center, class:${launcherClass}"

          "float, title:${gameTitle}"
          "monitor DP-1, title:${gameTitle}"
          "center, title:${gameTitle}"
        ];
      };
    };

    programs.anime-game-launcher.enable = true;
  };
}
