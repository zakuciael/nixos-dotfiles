{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  libpcap,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "pcapplusplus";
  version = "26.07";

  src = fetchFromGitHub {
    owner = "seladb";
    repo = "PcapPlusPlus";
    tag = "v${finalAttrs.version}";
    hash = "sha256-lz5RtkFGIvCojVekqptGvP+eNSmfSrRJue6J324re6U=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    libpcap
  ];

  propagatedBuildInputs = [
    libpcap
  ];

  cmakeFlags = [
    (lib.cmakeBool "PCAPPP_BUILD_EXAMPLES" false)
    (lib.cmakeBool "PCAPPP_BUILD_TESTS" false)
  ];

  # Upstream records absolute include paths into the generated cmake package
  # config; rewrite them to be prefix-relative for Nix.
  postInstall = ''
    substituteInPlace "$out/lib/cmake/pcapplusplus/PcapPlusPlusConfig.cmake" \
      --replace-fail "\''${PACKAGE_PREFIX_DIR}/$out/" "\''${PACKAGE_PREFIX_DIR}/"
  '';

  meta = {
    description = "Multi-platform C++ library for capturing, parsing and crafting network packets";
    homepage = "https://pcapplusplus.github.io/";
    license = lib.licenses.unlicense;
    platforms = lib.platforms.unix;
  };
})
