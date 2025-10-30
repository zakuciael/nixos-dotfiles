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
    version = "2.32.0";
    sources = rec {
      aarch64-linux = fetch "linux_arm64" "sha256-7t8Ar6vF8lU3fPy5Gw9jtUkcx9gYKg6AFDB8/3QBvbk=" "zip";
      i686-linux = fetch "linux_386" "sha256-+KSi87muDH/A8LNH7iDPQC/CnZhTpvFNSw1cuewqaXI=" "zip";
      x86_64-linux = fetch "linux_amd64" "sha256-4I7lSey6I4mQ7dDtuOASnZzAItFYkIDZ8UMsqb0q5tE=" "zip";
      aarch64-darwin =
        fetch "apple_universal" "sha256-PVSI/iYsjphNqs0DGQlzRhmvnwj4RHcNODE2nbQ8CO0="
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
