{
  lib,
  stdenv,
  fetchFromGitHub,
  callPackage,
  cmake,
  ninja,
  pkg-config,
  makeBinaryWrapper,
  shaderc,
  freetype,
  glfw3,
  glm,
  glaze,
  httplib,
  libpcap,
  mbedtls,
  protobuf,
  range-v3,
  tl-expected,
  utfcpp,
  catch2_3,
  vulkan-headers,
  vulkan-loader,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxinerama,
  libxrandr,
  libxxf86vm,
  libglvnd,
  dataDir ? null,
}:
let
  sources = lib.importJSON ./sources.json;

  libsail = callPackage ./libsail.nix { };
  pcapplusplus = callPackage ./pcapplusplus.nix { };
  skyr-url = callPackage ./skyr-url.nix { };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "zzz-packet-capture";
  version = sources."zzz-packet-capture".version;

  src = fetchFromGitHub {
    inherit (sources."zzz-packet-capture")
      owner
      repo
      rev
      hash
      ;
  };

  glt = fetchFromGitHub {
    inherit (sources.glt) owner repo rev hash;
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    makeBinaryWrapper
    shaderc # glslc for glt shader compilation
  ];

  buildInputs = [
    catch2_3
    freetype
    glaze
    glfw3
    glm
    httplib
    libglvnd
    libpcap
    libsail
    libx11
    libxcb
    libxcursor
    libxi
    libxinerama
    libxrandr
    libxxf86vm
    mbedtls
    pcapplusplus
    protobuf
    range-v3
    skyr-url
    tl-expected
    utfcpp
    vulkan-headers
    vulkan-loader
  ];

  # Also needed at runtime for GLFW / Vulkan dlopen
  runtimeLibs = [
    libglvnd
    libx11
    libxcb
    libxcursor
    libxi
    libxinerama
    libxrandr
    libxxf86vm
    vulkan-loader
  ];

  postUnpack = ''
    rm -rf "$sourceRoot/glt"
    cp -r "${finalAttrs.glt}" "$sourceRoot/glt"
    chmod -R u+w "$sourceRoot/glt"
  '';

  postPatch = ''
    patch -d glt -p1 < ${./httplib-x11.patch}

    # Drop vcpkg; dependencies come from Nix.
    substituteInPlace CMakeLists.txt \
      --replace-fail 'set(VCPKG_ROOT "''${CMAKE_CURRENT_SOURCE_DIR}/glt/vcpkg")' "" \
      --replace-fail 'set(CMAKE_TOOLCHAIN_FILE "''${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "")' "" \
      --replace-fail 'set(VCPKG_OVERLAY_PORTS "''${CMAKE_CURRENT_SOURCE_DIR}/vcpkg-overlay-ports")' ""

    substituteInPlace glt/CMakeLists.txt \
      --replace-fail 'set(VCPKG_ROOT "''${CMAKE_CURRENT_SOURCE_DIR}/vcpkg")' "" \
      --replace-fail 'set(CMAKE_TOOLCHAIN_FILE "''${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "")' "" \
      --replace-fail 'find_package(freetype CONFIG REQUIRED)' 'find_package(Freetype REQUIRED)' \
      --replace-fail 'target_link_libraries(glt PUBLIC freetype)' 'target_link_libraries(glt PUBLIC Freetype::Freetype)' \
      --replace-fail 'CPPHTTPLIB_MBEDTLS_SUPPORT ' "" \
      --replace-fail 'target_compile_options(glt PRIVATE -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Wno-c++11-narrowing -Wno-narrowing -Werror)' \
                       'target_compile_options(glt PRIVATE -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Wno-c++11-narrowing -Wno-narrowing)' \
      --replace-fail 'target_compile_definitions(glt PRIVATE SAIL_STATIC)' ""
  '';

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_BUILD_TYPE" "Release")
  ];

  # Upstream has no install() rules for the executable.
  installPhase = ''
    runHook preInstall

    install -Dm755 zzz_packet_capture $out/libexec/zzz-packet-capture/zzz_packet_capture
    install -dm755 $out/share/zzz-packet-capture
    cp -r ../assets $out/share/zzz-packet-capture/assets

    makeBinaryWrapper $out/libexec/zzz-packet-capture/zzz_packet_capture $out/bin/zzz_packet_capture \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath finalAttrs.runtimeLibs} \
      ${lib.optionalString (dataDir != null) "--chdir ${lib.escapeShellArg dataDir}"}

    runHook postInstall
  '';

  passthru = {
    inherit libsail pcapplusplus skyr-url;
    updateScript = ./update.sh;
  };

  meta = {
    description = "Packet-capture scanner for Zenless Zone Zero inventory export";
    homepage = "https://github.com/AleXu224/zzz_packet_capture";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ zakuciael ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "zzz_packet_capture";
  };
})
