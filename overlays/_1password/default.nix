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
    version = "2.33.1";
    sources = rec {
      aarch64-linux = fetch "linux_arm64" "sha256-rBXJ5BT/1TFySOgC1wpgOz4tcOF9flHplfonYGOA9Ac=" "zip";
      i686-linux = fetch "linux_386" "sha256-2Hh+ML+hewwZATrh01kPXoNBdYWN3dI2ZqfLBiH/gK8=" "zip";
      x86_64-linux = fetch "linux_amd64" "sha256-ge+4thdTnymQYFQ2G9qwh9i3zsY13W1M5za1CXybUqI=" "zip";
      aarch64-darwin =
        fetch "apple_universal" "sha256-+3NI4BIazI21m6teLBvKalCTN8cx6RhFqwXnkNK6tjQ="
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
