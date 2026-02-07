{
  config,
  lib,
  pkgs,
  inputs,
  username,
  ...
}:
with lib;
with lib.my;
with lib.my.utils;
let
  inherit (pkgs) makeDesktopItem symlinkJoin;
  inherit (pkgs.stdenv) mkDerivation;
  cfg = config.modules.desktop.gaming.mihoyo;
  layout = findLayoutConfig config ({ name, ... }: name == "main"); # Main monitor
  monitor = getLayoutMonitor layout "wayland";

  mkGameShortcut =
    {
      name,
      desktopName,
      iconSrc,
      package,
    }:
    let
      icon = mkDerivation {
        name = "${name}-icon";
        src = iconSrc;
        nativeBuildInputs = with pkgs; [ libicns ];
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
        categories = [ "Game" ];
        icon = name;
      };
    in
    symlinkJoin {
      inherit name;
      paths = [
        icon
        desktopEntry
      ];
      meta = with lib; {
        description = "A shortcut for ${desktopName}";
        license = licenses.unlicense;
        maintainers = with maintainers; [ zakuciael ];
        platforms = platforms.linux;
      };
    };
in
{
  options.modules.desktop.gaming.mihoyo = {
    enable = mkEnableOption "miHoYo games";
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = [
        (mkGameShortcut {
          name = "genshin-impact";
          desktopName = "Genshin Impact";
          iconSrc = builtins.fetchurl {
            url = "https://parsefiles.back4app.com/JPaQcFfEEQ1ePBxbf6wvzkPMEqKYHhPYv8boI1Rc/3c03a44960ac2060be92bd7182c35e83_F5ttFHp0ag.icns";
            sha256 = "sha256-jEa14o2TqUVuSzgpA8hvWmUedwoKt39iEwrn6NPzBKU=";
          };
          package = config.programs.anime-game-launcher.package;
        })
      ];

      wayland.windowManager.hyprland.settings = {
        windowrule = [
          {
            name = "AAGL Launcher";
            "match:class" = "^(moe.launcher.an-anime-game-launcher)$";
            float = true;
            center = true;
            size = "(monitor_w*0.7) (monitor_h*0.7)";
            inherit monitor;
          }
          {
            name = "Genshin Impact Fullscreen";
            "match:class" = "^(genshinimpact.exe)$";
            fullscreen = true;
            immediate = true;
            inherit monitor;
          }
        ];
      };
    };

    programs.anime-game-launcher = {
      enable = true;
      package = inputs.aagl.packages.anime-game-launcher;
    };
  };
}
