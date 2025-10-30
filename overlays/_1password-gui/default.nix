{ lib, ... }:
let
  inherit (lib) singleton;
in
singleton (
  final: prev:
  let
    inherit (final) stdenv fetchurl;
    hostOs = stdenv.hostPlatform.parsed.kernel.name;
    hostArch = stdenv.hostPlatform.parsed.cpu.name;
    sources = builtins.fromJSON (builtins.readFile ./sources.json);

    mkVersion =
      channel:
      let
        sourcesChan = sources.${channel} or (throw "unsupported channel ${channel}");
        sourcesChanOs = sourcesChan.${hostOs} or (throw "unsupported OS ${hostOs}");
        sourcesChanOsArch =
          sourcesChanOs.sources.${hostArch} or (throw "unsupported architecture ${hostArch}");
      in
      {
        inherit (sourcesChanOs) version;
        src = fetchurl {
          inherit (sourcesChanOsArch) url hash;
        };
      };

  in
  {
    _1password-gui-beta = prev._1password-gui.overrideAttrs {
      inherit (mkVersion "beta") version src;
    };

    _1password-gui = prev._1password-gui.overrideAttrs {
      inherit (mkVersion "stable") version src;
    };
  }
)
