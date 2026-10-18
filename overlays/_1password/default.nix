{ lib, ... }:
let
  inherit (lib) singleton;
in
{
  updateScript = "overlays/_1password/update.sh";

  overlays = singleton (
    final: prev:
    let
      inherit (final) stdenv fetchurl fetchzip;
      inherit (stdenv.hostPlatform) system;

      pname = "1password-cli";
      version = "2.41.0";
      sources = rec {
        aarch64-linux = fetch "linux_arm64" "sha256-hgvcy4oOZWXddsmKI9pOlRdMNM5tXSKrdZMgzPQ/FNw=" "zip";
        i686-linux = fetch "linux_386" "sha256-dFXFo+LAlLXpSzRWu4lwW31esHJckg/ykh+NKWvMQcU=" "zip";
        x86_64-linux = fetch "linux_amd64" "sha256-nhnJ2OX4BnVzD3ptKSvfmrkiDRpf8EwoqXix5o1sWl8=" "zip";
        aarch64-darwin =
          fetch "apple_universal" "sha256-6rF+DJKcEbYim1droOfS12THR4ysnK+fv6Ef5hvDVkc="
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
  );
}
