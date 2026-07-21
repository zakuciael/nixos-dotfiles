{ lib, ... }:
let
  inherit (lib) singleton;
in
singleton (
  final: prev:
  let
    inherit (final) stdenv fetchurl fetchzip;
    inherit (stdenv.hostPlatform) system;

    pname = "1password-cli";
    version = "2.34.1";
    sources = rec {
      aarch64-linux = fetch "linux_arm64" "sha256-uEukRq71eeayvNguD9XepvP1Br5AkE2Ag/Chv2idf4A=" "zip";
      i686-linux = fetch "linux_386" "sha256-p/F3YZLJnlimrVE2qxTHvIB4m47kuwhoCWTC40VIvMs=" "zip";
      x86_64-linux = fetch "linux_amd64" "sha256-oAABMlwwv5X91TT6FK2aPpg+e2CvmHT1rqIVRTjQNCQ=" "zip";
      aarch64-darwin =
        fetch "apple_universal" "sha256-vp1Y1M6DUanx1CAVhLrqgBovwws6Y/5jOgnwTZE8Hhc="
          "pkg";
      x86_64-darwin = aarch64-darwin;
    };

    platforms = builtins.attrNames sources;

    fetch =
      srcPlatform: hash: extension:
      let
        args = {
          url = "https://cache.agilebits.com/dist/1P/op2/pkg/v${version}/op_${srcPlatform}_v${version}.${extension}";
          inherit hash;
        }
        // lib.optionalAttrs (extension == "zip") { stripRoot = false; };
      in
      if extension == "zip" then fetchzip args else fetchurl args;
  in
  {
    _1password-cli = prev._1password-cli.overrideAttrs {
      inherit pname version;

      src =
        if (builtins.elem system platforms) then
          sources.${system}
        else
          throw "Source for ${pname} is not available for ${system}";
    };

  }
)
