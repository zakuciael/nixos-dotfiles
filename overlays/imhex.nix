final: prev: let
  inherit (prev) fetchFromGitHub;
  inherit (prev.lib) makeLibraryPath;

  # TODO: Remove when this https://github.com/NixOS/nixpkgs/pull/323510 is merged to upstream
  glfw3-patched = let
    inherit (prev) stdenv libxkbcommon libdecor wayland;
    inherit (prev.lib) optionalString getLib;
  in
    prev.glfw3.overrideAttrs {
      postPatch = optionalString stdenv.isLinux ''
        substituteInPlace src/wl_init.c \
          --replace-fail "libxkbcommon.so.0" "${getLib libxkbcommon}/lib/libxkbcommon.so.0" \
          --replace-fail "libdecor-0.so.0" "${getLib libdecor}/lib/libdecor-0.so.0" \
          --replace-fail "libwayland-client.so.0" "${getLib wayland}/lib/libwayland-client.so.0" \
          --replace-fail "libwayland-cursor.so.0" "${getLib wayland}/lib/libwayland-cursor.so.0" \
          --replace-fail "libwayland-egl.so.1" "${getLib wayland}/lib/libwayland-egl.so.1"
      '';
    };

  version = "1.35.3";
  patterns_version = "1.35.3";

  patterns_src = fetchFromGitHub {
    name = "ImHex-Patterns-source-${patterns_version}";
    owner = "WerWolv";
    repo = "ImHex-Patterns";
    rev = "ImHex-v${patterns_version}";
    hash = "sha256-h86qoFMSP9ehsXJXOccUK9Mfqe+DVObfSRT4TCtK0rY=";
  };
in {
  # TODO: Remove when this https://github.com/NixOS/nixpkgs/pull/323501 is merged to upstream
  imhex = prev.imhex.overrideAttrs {
    inherit version;

    src = fetchFromGitHub {
      name = "ImHex-source-${version}";
      fetchSubmodules = true;
      owner = "WerWolv";
      repo = "ImHex";
      rev = "refs/tags/v${version}";
      hash = "sha256-8vhOOHfg4D9B9yYgnGZBpcjAjuL4M4oHHax9ad5PJtA=";
    };

    nativeBuildInputs = with prev; [
      autoPatchelfHook
      cmake
      llvm_17
      python3
      perl
      pkg-config
      rsync
    ];

    buildInputs = with prev; [
      capstone
      curl
      dbus
      file
      fmt_8
      glfw3-patched
      gtk3
      jansson
      libGLU
      mbedtls
      nlohmann_json
      yara
    ];

    autoPatchelfIgnoreMissingDeps = [
      "fonts.hexpluglib"
      "ui.hexpluglib"
    ];

    appendRunpaths = [
      (makeLibraryPath (with prev; [libGL]))
      "${placeholder "out"}/lib/imhex/plugins"
    ];

    postInstall = ''
      mkdir -p $out/share/imhex
      rsync -av --exclude="*_schema.json" ${patterns_src}/{constants,encodings,includes,magic,patterns} $out/share/imhex
    '';
  };
}
