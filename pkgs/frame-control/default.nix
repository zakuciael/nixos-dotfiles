{
  lib,
  appimageTools,
  fetchurl,
  imagemagick,
  openssh-fhs-compat,
  kitty,
}:
let
  pname = "frame-control";
  version = "0.4.61";

  src = fetchurl {
    url = "https://github.com/saphid/frame-control/releases/download/v${version}/Frame-Control-linux-x86_64.AppImage";
    # From upstream SHA256SUMS for Frame-Control-linux-x86_64.AppImage
    hash = "sha256-5vAsbEDGf2gT62KAwEfNq6NtcJmUFX3/uVTf2v8RdmQ=";
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };

  icon = "${appimageContents}/usr/share/icons/hicolor/1024x1024/apps/${pname}.png";
in
appimageTools.wrapType2 {
  inherit pname version src;

  # Host SSH via -F wrapper (HM ~/.ssh/config is store-owned inside FHS).
  # x64 builds already bundle adb. kitty is used for the in-app terminal.
  extraPkgs = pkgs: [
    openssh-fhs-compat
    kitty
  ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/${pname}.desktop -t $out/share/applications
    # Upstream: Exec=AppRun --no-sandbox %U (keeps %U for frame-control:// links)
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
    description = "Manage a Valve Steam Frame from your computer over SSH";
    homepage = "https://framecontrol.fun/";
    downloadPage = "https://github.com/saphid/frame-control/releases";
    changelog = "https://github.com/saphid/frame-control/releases/tag/v${version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
