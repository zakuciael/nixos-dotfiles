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
      version = "2.44.0-beta.02";
      sources = rec {
        aarch64-linux = fetch "linux_arm64" "sha256-fJO5xTe3Irme60ApyxRV+PSEyxM3BN7KCQ44WUTM+Dg=" "zip";
        i686-linux = fetch "linux_386" "sha256-HmMEhJif6u9MWGrpJn1PUik3AJ01nBgZLqiJyGfz9WU=" "zip";
        x86_64-linux = fetch "linux_amd64" "sha256-tidkiDFROrAuRBcs2d6Fe10pY4vZQ8AHTZ6MZsyRTGs=" "zip";
        aarch64-darwin =
          fetch "apple_universal" "sha256-nRMcFPjg3sgdbYu8pjSTHuzHZw4qUQfOG9OUszVyTOA="
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
