{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (pkgs) writeTextDir;
  cfg = config.modules.services.thumbnail;

  # Thumbnails form 'raw' data and include EXIF tags for Adobe-DNG images
  nufraw-exif-thumbnailer = writeTextDir "share/thumbnailers/my-custom-nufraw.thumbnailer" ''
    [Thumbnailer Entry]
    TryExec=nufraw-batch
    Exec=nufraw-batch --silent --size %s --out-type=png --output=%o %i
    MimeType=image/x-adobe-dng;image/x-dng;
  '';
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
        nufraw
        nufraw-thumbnailer
        nufraw-exif-thumbnailer
        webp-pixbuf-loader
        f3d
      ];
    };
  };
}
