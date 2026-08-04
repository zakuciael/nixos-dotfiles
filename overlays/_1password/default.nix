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
    version = "2.38.2-beta.01";
    sources = rec {
      aarch64-linux = fetch "linux_arm64" "sha256-RZpDhSIMA5rYNea0bmGnbXKvZ4PUHUVF5mclDKVLLYE=" "zip";
      i686-linux = fetch "linux_386" "sha256-To1xzagoMcA/EGiw3BlPVGEBL60e5E6N4FpjfhDc0XQ=" "zip";
      x86_64-linux = fetch "linux_amd64" "sha256-Ut61t5L2j8RnmEP73CT2UbYI32tL3jjc4fq8LUsGaGk=" "zip";
      aarch64-darwin =
        fetch "apple_universal" "sha256-xu4RkpUKJXt0u+FCNjww5zEjUU1VaHSSdIimJIf+GXw="
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
