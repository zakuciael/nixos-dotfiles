{
  lib,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
  makeDesktopItem,
  openssh-fhs-compat,
  android-tools,
  gtk3,
  gdk-pixbuf,
  pango,
  cairo,
  at-spi2-core,
  harfbuzz,
  glib,
  libepoxy,
  fontconfig,
  freetype,
  dbus,
}:
let
  pname = "frameport";
  version = "1.4.0";

  src = fetchurl {
    url = "https://github.com/spoopyghosty0/frameport/releases/download/v${version}/FramePort-linux-x64.tar.gz";
    # From upstream SHA256SUMS.txt
    hash = "sha256-C3p4brdS/8lqve4xhNMN69x3DC/ThNPvW0m2vrvB0fE=";
  };

  # Flutter/Flet relocatable bundle (interpreter expects FHS /lib64/ld-linux).
  unpacked = stdenvNoCC.mkDerivation {
    pname = "${pname}-unpacked";
    inherit version src;

    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      # Tarball root is FramePort/; keep binary + lib/ as siblings for $ORIGIN/lib.
      tar -xzf "$src" -C "$out" --strip-components=1
      runHook postInstall
    '';
  };

  desktopItem = makeDesktopItem {
    name = "dev.frameport.frameport";
    desktopName = "FramePort";
    comment = "Run Meta Quest, Android and PC VR games on the Valve Steam Frame";
    exec = "${pname} %U";
    icon = "dev.frameport.frameport";
    terminal = false;
    categories = [ "Utility" ];
    startupWMClass = "dev.frameport.frameport";
  };
in
buildFHSEnv {
  inherit pname version;

  targetPkgs =
    pkgs: with pkgs; [
      openssh-fhs-compat
      android-tools
      gtk3
      gdk-pixbuf
      pango
      cairo
      at-spi2-core
      harfbuzz
      glib
      libepoxy
      fontconfig
      freetype
      dbus
      stdenv.cc.cc.lib
      zlib
      libGL
      libx11
      libxcursor
      libxext
      libxi
      libxinerama
      libxrandr
      libxrender
      libxfixes
      libxkbcommon
      wayland
    ];

  runScript = "${unpacked}/FramePort";

  extraInstallCommands = ''
    mkdir -p $out/share/icons
    # Install only the real app icons (skip flet's broken None.png placeholders).
    for size in 16 24 32 48 64 128 256 512; do
      install -Dm644 \
        ${unpacked}/share/icons/hicolor/"$size"x"$size"/apps/dev.frameport.frameport.png \
        $out/share/icons/hicolor/"$size"x"$size"/apps/dev.frameport.frameport.png
    done

    install -Dm644 ${desktopItem}/share/applications/* -t $out/share/applications
    substituteInPlace $out/share/applications/dev.frameport.frameport.desktop \
      --replace-fail 'Icon=dev.frameport.frameport' \
        "Icon=$out/share/icons/hicolor/256x256/apps/dev.frameport.frameport.png"
  '';

  meta = {
    description = "Install Meta Quest, Android and PC VR games on a Valve Steam Frame";
    homepage = "https://github.com/spoopyghosty0/frameport";
    downloadPage = "https://github.com/spoopyghosty0/frameport/releases";
    changelog = "https://github.com/spoopyghosty0/frameport/releases/tag/v${version}";
    license = lib.licenses.gpl3Only;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
