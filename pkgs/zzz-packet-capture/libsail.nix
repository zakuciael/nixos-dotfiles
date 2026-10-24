{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  libwebp,
  libpng,
  libjpeg,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libsail";
  version = "0.9.10";

  src = fetchFromGitHub {
    owner = "HappySeaFox";
    repo = "sail";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OuWaWWL6ZEFixXAmPEi2bpSSwuhhVDgw9f/7K44YuEw=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    libjpeg
    libpng
    libwebp
  ];

  cmakeFlags = [
    (lib.cmakeBool "SAIL_BUILD_APPS" false)
    (lib.cmakeBool "SAIL_BUILD_EXAMPLES" false)
    (lib.cmakeBool "SAIL_BUILD_BINDINGS" true)
    (lib.cmakeBool "SAIL_COMBINE_CODECS" true)
    (lib.cmakeBool "BUILD_SHARED_LIBS" true)
    (lib.cmakeBool "BUILD_TESTING" false)
    # Enough for glt image loading; matches upstream webp feature + jpeg/png.
    "-DSAIL_ONLY_CODECS=jpeg;png;webp"
  ];

  meta = {
    description = "Squirrel Abstract Imaging Library";
    homepage = "https://github.com/HappySeaFox/sail";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
