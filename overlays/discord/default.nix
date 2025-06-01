{ lib, ... }:
let
  inherit (lib) singleton;
in
singleton (
  final: prev: {
    # Fix for krisp module
    # Source PR: https://github.com/NixOS/nixpkgs/pull/290077
    discord-canary = prev.discord-canary.overrideAttrs (
      prevAttrs:
      let
        inherit (lib) getExe toLower;
        inherit (final) runCommand python3;
        binaryName = "DiscordCanary";
        buildInputs = [ final.libgccjit ] ++ prevAttrs.buildInputs;

        fixKrisp =
          runCommand "fix-krisp.py"
            {
              pythonInterpreter = getExe (
                python3.withPackages (
                  ps: with ps; [
                    pyelftools
                    capstone
                  ]
                )
              );
              configDirName = toLower binaryName;
              version = prevAttrs.version;
              meta.mainProgram = "fix-krisp.py";
            }
            ''
              mkdir -p $out/bin
              cp ${./fix-krisp.py} $out/bin/fix-krisp.py
              substituteAllInPlace $out/bin/fix-krisp.py
              chmod +x $out/bin/fix-krisp.py
            '';
      in
      {
        installPhase =
          builtins.replaceStrings
            [ ''--run '' ]
            [
              ''
                --run "${getExe fixKrisp} $out/opt/${binaryName}/.${binaryName}-wrapped" \
                    --run ''
            ]
            prevAttrs.installPhase;
      }
    );
  }
)
