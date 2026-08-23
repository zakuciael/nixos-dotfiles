{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.services.thumbnail;
in
{
  options.modules.services.thumbnail = {
    enable = mkEnableOption "a D-Bus thumbnailer servic";
  };

  config = mkIf cfg.enable {
    services.tumbler.enable = true;
    environment = {
      pathsToLink = [
        "share/thumbnailers"
      ];

      systemPackages = with pkgs; [
        ffmpeg-headless
        ffmpegthumbnailer
        gdk-pixbuf
        libheif
        libheif.out
        webp-pixbuf-loader
        f3d
      ];
    };
  };
}
