{ lib, ... }:
with lib;
singleton (
  final: prev: {
    _1password-gui-beta =
      (prev._1password-gui.override {
        channel = "beta";
      }).overrideAttrs
        {
          preFixup = ''
            makeShellWrapper $out/share/1password/1password $out/bin/1password \
              "''${gappsWrapperArgs[@]}" \
              --suffix PATH : ${makeBinPath (with final; [ xdg-utils ])} \
              --prefix LD_LIBRARY_PATH : ${makeLibraryPath (with final; [ udev ])} \
              --add-flags "\''${NIXOS_OZONE_WL:+--ozone-platform-hint=auto}"
          '';
        };

    _1password-cli-beta = prev._1password-cli.overrideAttrs (
      let
        inherit (prev) stdenv fetchurl fetchzip;

        inherit (stdenv.hostPlatform) system;
        fetch =
          srcPlatform: hash: extension:
          let
            args = {
              url = "https://cache.agilebits.com/dist/1P/op2/pkg/v${version}/op_${srcPlatform}_v${version}.${extension}";
              inherit hash;
            } // lib.optionalAttrs (extension == "zip") { stripRoot = false; };
          in
          if extension == "zip" then fetchzip args else fetchurl args;

        pname = "1password-cli";
        version = "2.30.0-beta.03";
        sources = rec {
          aarch64-linux = fetch "linux_arm64" "sha256-RvFlmgFrvrdlwAPYOJl9OGiUH4Cv0ZXw8YzwsS0LgHo=" "zip";
          i686-linux = fetch "linux_386" "sha256-8HEJp9SCrSv2EZ+AhNcFi9avig9OFUqy8+eCM4pb9NA=" "zip";
          x86_64-linux = fetch "linux_amd64" "sha256-7iaYCry3T9GD84GBX/A+IC27Ngq1WYGeYDV/yxMNamw=" "zip";
          aarch64-darwin =
            fetch "apple_universal" "sha256-0OyhQRAYXatOQ2dNYKIPUw/UO2QNn+GFILabXnsFgBA="
              "pkg";
          x86_64-darwin = aarch64-darwin;
        };
        platforms = builtins.attrNames sources;
      in
      {
        inherit pname version;

        src =
          if (builtins.elem system platforms) then
            sources.${system}
          else
            throw "Source for ${pname} is not available for ${system}";
      }
    );
  }
)
