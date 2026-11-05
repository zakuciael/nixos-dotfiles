{
  lib,
  appimageTools,
  fetchurl,
  imagemagick,
  openssh-fhs-compat,
}:
let
  pname = "frameloader";
  version = "0.1.0";

  src = fetchurl {
    url = "https://github.com/travelerdev/frameloader/releases/download/v${version}/Frameloader-linux-x86_64.AppImage";
    hash = "sha256-MhHMj64R/dJkCCAViAA0gV3AOWFt636vy0hJeiRoJ+8=";
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };

  icon = "${appimageContents}/usr/share/icons/hicolor/1024x1024/apps/${pname}.png";
in
appimageTools.wrapType2 {
  inherit pname version src;

  # Host SSH via -F wrapper (HM ~/.ssh/config is store-owned inside FHS).
  extraPkgs = pkgs: [ openssh-fhs-compat ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/${pname}.desktop -t $out/share/applications
    # Upstream: Exec=AppRun --no-sandbox %U
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}'

    # Upstream only ships 1024x1024; many DEs ignore that size alone.
    for size in 16 24 32 48 64 128 256 512; do
      mkdir -p $out/share/icons/hicolor/"$size"x"$size"/apps
      ${lib.getExe imagemagick} ${icon} -resize "$size"x"$size" \
        $out/share/icons/hicolor/"$size"x"$size"/apps/${pname}.png
    done
    install -Dm644 ${icon} $out/share/icons/hicolor/1024x1024/apps/${pname}.png
    install -Dm644 ${icon} $out/share/pixmaps/${pname}.png
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Icon=${pname}' "Icon=$out/share/icons/hicolor/256x256/apps/${pname}.png"
  '';

  meta = {
    description = "Sideload APK, Windows, and Linux apps onto a Steam Frame";
    homepage = "https://www.frameloader.com/";
    downloadPage = "https://github.com/travelerdev/frameloader/releases";
    changelog = "https://github.com/travelerdev/frameloader/releases/tag/v${version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
