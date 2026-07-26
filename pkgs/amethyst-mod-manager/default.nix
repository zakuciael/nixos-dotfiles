{
  buildFHSEnv,
  amethyst-mod-manager-unwrapped,
  _7zz,
  bash,
  cabextract,
  fontconfig,
  freetype,
  glib,
  python3,
  winetricks,
  xdg-utils,
}:

buildFHSEnv {
  name = "amethyst-mod-manager";

  multiArch = true;

  targetPkgs = _: [
    amethyst-mod-manager-unwrapped
    (_7zz.override { enableUnfree = true; })
    bash
    cabextract
    fontconfig
    freetype
    glib
    python3
    winetricks
    xdg-utils
  ];

  multiPkgs = p: [
    p.libGL
    p.libGLU
    p.libdrm
    p.libva
    p.mesa.llvmPackages.llvm.lib
    p.vulkan-loader
    p.wayland
    p.pipewire
    p.expat
    p.libelf
    p.fontconfig
    p.freetype
    p.harfbuzz
    p.libthai
    p.pango
    p.libXft
    p.libx11
    p.libxscrnsaver
    p.libxcomposite
    p.libxcursor
    p.libxdamage
    p.libxext
    p.libxfixes
    p.libxi
    p.libxinerama
    p.libxrandr
    p.libxrender
    p.libxmu
    p.libxt
    p.libxxf86vm
    p.libsm
    p.libice
    p.libxcb
    p.libxshmfence
    p.libpciaccess
    p.xkeyboard-config
    p.alsa-lib
    p.libpulseaudio
    p.libcanberra
    p.SDL2
    p.SDL2_image
    p.SDL2_mixer
    p.SDL2_ttf
    p.SDL
    p.SDL_image
    p.SDL_mixer
    p.SDL_ttf
    p.cups
    p.dbus
    p.dbus-glib
    p.glib
    p.atk
    p.cairo
    p.gdk-pixbuf
    p.gtk2
    p.gtk3
    p.gnome2.GConf
    p.at-spi2-atk
    p.at-spi2-core
    p.gsettings-desktop-schemas
    p.gtk-engine-murrine
    p.gst_all_1.gstreamer
    p.gst_all_1.gst-plugins-base
    p.gst_all_1.gst-plugins-good
    p.gst_all_1.gst-plugins-bad
    p.gst_all_1.gst-libav
    p.gst_all_1.gst-plugins-ugly
    p.curlWithGnuTls
    p.nspr
    p.nss
    p.openssl
    p.icu
    p.json-glib
    p.libidn
    p.libidn2
    p.libnghttp2
    p.libpsl
    p.rtmpdump
    p.flac
    p.libogg
    p.libvorbis
    p.libtheora
    p.speex
    p.libsamplerate
    p.libmikmod
    p.libvpx
    p.libcaca
    p.libjpeg
    p.libpng
    p.libpng12
    p.libtiff
    p.librsvg
    p.ffmpeg
    p.lcms2
    p.freeglut
    p.glew_1_10
    p.zlib
    p.xz
    p.bzip2
    p.brotli
    p.libcap
    p.libusb1
    p.udev
    p.libgcrypt
    p.libunwind
    p.attr
    p.ncurses
    p.tbb
    p.libuuid
    p.libbsd
    p.libffi
    p.pcre
    p.pixman
    p.lz4
    p.zstd
    p.keyutils
    p.libappindicator-gtk2
    p.libdbusmenu-gtk2
    p.libindicator-gtk2
    p.mono
  ];

  runScript = "amethyst-mod-manager";

  extraInstallCommands = ''
    ln -s ${amethyst-mod-manager-unwrapped}/share $out/share
  '';

  meta = (amethyst-mod-manager-unwrapped.meta or { }) // {
    description = "Linux native mod manager for a variety of games (FHS environment)";
    mainProgram = "amethyst-mod-manager";
  };
}
