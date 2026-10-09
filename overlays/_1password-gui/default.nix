{ lib, ... }:
let
  inherit (lib) singleton;
in
{
  updateScript = "overlays/_1password-gui/update.sh";

  overlays = singleton (
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

      # nixpkgs only patchelfs {1password,1Password-BrowserSupport,1Password-LastPass-Exporter,op-ssh-sign}.
      # Newer Electron helpers (notably chrome_crashpad_handler) ship without RUNPATH and fail at
      # runtime looking for libglib-2.0.so.0 when spawned outside the wrapper's LD_LIBRARY_PATH.
      patchHelperBins =
        old:
        (old.postInstall or "")
        + lib.optionalString stdenv.hostPlatform.isLinux ''
          interp="$(cat $NIX_CC/nix-support/dynamic-linker)"
          rpath="$(patchelf --print-rpath $out/share/1password/1password)"
          for bin in chrome_crashpad_handler 1Password-Crash-Handler 1password-mcp chrome-sandbox; do
            if [[ -e $out/share/1password/$bin ]]; then
              patchelf --set-interpreter "$interp" --set-rpath "$rpath" \
                "$out/share/1password/$bin"
            fi
          done
        '';

      mkGuiOverride =
        channel: old:
        {
          inherit (mkVersion channel) version src;
          postInstall = patchHelperBins old;
        };

    in
    {
      _1password-gui-beta = prev._1password-gui.overrideAttrs (mkGuiOverride "beta");

      _1password-gui = prev._1password-gui.overrideAttrs (mkGuiOverride "stable");
    }
  );
}
