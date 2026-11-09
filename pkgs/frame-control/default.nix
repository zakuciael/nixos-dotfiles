{
  lib,
  appimageTools,
  fetchurl,
  imagemagick,
  openssh-fhs-compat,
  kitty,
  rsync,
}:
let
  pname = "frame-control";
  version = "0.4.61";

  src = fetchurl {
    url = "https://github.com/saphid/frame-control/releases/download/v${version}/Frame-Control-linux-x86_64.AppImage";
    # From upstream SHA256SUMS for Frame-Control-linux-x86_64.AppImage
    hash = "sha256-5vAsbEDGf2gT62KAwEfNq6NtcJmUFX3/uVTf2v8RdmQ=";
  };

  # wrapType2 only forwards pname/version/src into extract, so patch via a custom
  # contents derivation and wrapAppImage instead.
  appimageContents = appimageTools.extract {
    inherit pname version src;
    postExtract = ''
      # Nix store paths are 0444/0555. Frame Control syncs them to the headset with
      # rsync -a / scp -r, which preserves those modes. A 0555 staging dir then makes
      # `rm -rf ~/.devkit-utils.frame-control` fail with "Permission denied".
      substituteInPlace $out/resources/ui/frame_titles.py \
        --replace-fail \
          "cmd = ['rsync', '-a', *(['--delete'] if delete else []), '-e', shlex.join(['ssh', *opts])," \
          "cmd = ['rsync', '-a', '--chmod=ugo=rwX', *(['--delete'] if delete else []), '-e', shlex.join(['ssh', *opts]),"

      # Clear leftover 0555 staging dirs from earlier broken syncs.
      substituteInPlace $out/resources/ui/frame_titles.py \
        --replace-fail \
          "ssh(f'rm -rf {tmp}', timeout=30)" \
          "ssh(f'chmod -R u+rwX {tmp} 2>/dev/null; rm -rf {tmp}', timeout=30)"

      # Ensure the copied tree is writable before merge / cleanup.
      substituteInPlace $out/resources/ui/frame_titles.py \
        --replace-fail \
          "ssh(f'mkdir -p {UTILS} && cp -R {tmp}/. {UTILS}/ && rm -rf {tmp} {UTILS}/__pycache__ '" \
          "ssh(f'chmod -R u+rwX {tmp} && mkdir -p {UTILS} && cp -R {tmp}/. {UTILS}/ && chmod -R u+rwX {UTILS} && rm -rf {tmp} {UTILS}/__pycache__ '"
    '';
  };

  icon = "${appimageContents}/usr/share/icons/hicolor/1024x1024/apps/${pname}.png";
in
appimageTools.wrapAppImage {
  inherit pname version;
  contents = appimageContents;

  # Host SSH via -F wrapper (HM ~/.ssh/config is store-owned inside FHS).
  # x64 builds already bundle adb. kitty is used for the in-app terminal.
  # rsync is preferred for Frame syncs (see frame_titles._copy_tree).
  extraPkgs = pkgs: [
    openssh-fhs-compat
    kitty
    rsync
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
