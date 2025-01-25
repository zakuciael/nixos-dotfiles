final: prev:
let
  inherit (final) fetchurl fetchzip;
  inherit (final.lib) optionalAttrs;
  inherit (final.stdenv.hostPlatform) system;

  pname = "1password-cli";
  version = "2.30.0-beta.03";

  sources = rec {
    aarch64-linux = fetch {
      platform = "linux_arm64";
      extension = "zip";
      hash = "sha256-RvFlmgFrvrdlwAPYOJl9OGiUH4Cv0ZXw8YzwsS0LgHo=";
    };
    i686-linux = fetch {
      platform = "linux_386";
      extension = "zip";
      hash = "sha256-8HEJp9SCrSv2EZ+AhNcFi9avig9OFUqy8+eCM4pb9NA=";
    };
    x86_64-linux = fetch {
      platform = "linux_amd64";
      extension = "zip";
      hash = "sha256-7iaYCry3T9GD84GBX/A+IC27Ngq1WYGeYDV/yxMNamw=";
    };
    aarch64-darwin = fetch {
      platform = "apple_universal";
      extension = "pkg";
      hash = "sha256-0OyhQRAYXatOQ2dNYKIPUw/UO2QNn+GFILabXnsFgBA=";
    };
    x86_64-darwin = aarch64-darwin;
  };

  fetch =
    {
      platform,
      extension,
      hash,
    }:
    let
      args = {
        url = "https://cache.agilebits.com/dist/1P/op2/pkg/v${version}/op_${platform}_v${version}.${extension}";
        inherit hash;
      } // optionalAttrs (extension == "zip") { stripRoot = false; };
    in
    if extension == "zip" then fetchzip args else fetchurl args;
in
{
  _1password-cli-beta = prev._1password-cli.overrideAttrs {
    inherit pname version;

    src =
      if (sources ? "${system}") then
        sources.${system}
      else
        throw "Source for ${pname} is not available for ${system}";
  };
}
