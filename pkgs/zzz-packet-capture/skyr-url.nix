{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  nlohmann_json,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "skyr-url";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "cpp-netlib";
    repo = "url";
    tag = "v${finalAttrs.version}";
    hash = "sha256-n6i930yq9NQI5ZNX4564FXmNE1yQoT0obzFTk3SCk7I=";
  };

  nativeBuildInputs = [
    cmake
    ninja
  ];

  buildInputs = [
    nlohmann_json
  ];

  cmakeFlags = [
    (lib.cmakeBool "skyr_BUILD_TESTS" false)
    (lib.cmakeBool "skyr_BUILD_DOCS" false)
    (lib.cmakeBool "skyr_BUILD_EXAMPLES" false)
    (lib.cmakeBool "skyr_BUILD_BENCHMARKS" false)
    (lib.cmakeBool "skyr_WARNINGS_AS_ERRORS" false)
  ];

  meta = {
    description = "C++ library implementing the WhatWG URL specification";
    homepage = "https://github.com/cpp-netlib/url";
    license = lib.licenses.bsl11;
    platforms = lib.platforms.all;
  };
})
