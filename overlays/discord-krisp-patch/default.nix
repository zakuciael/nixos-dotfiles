final: prev:
let
  inherit (final) runCommand python3;
  inherit (final.lib) getExe toLower;
in
{
  # Fix for krisp module
  # Source PR: https://github.com/NixOS/nixpkgs/pull/290077
  discord-canary = prev.discord-canary.overrideAttrs (
    attrs:
    let
      binaryName = "DiscordCanary";
      fix-krisp-script =
        runCommand "fix-krisp.py"
          {
            inherit (attrs) version;
            pythonInterpreter = getExe (
              python3.withPackages (
                ps: with ps; [
                  pyelftools
                  capstone
                ]
              )
            );
            configDirName = toLower binaryName;
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
              --run "${getExe fix-krisp-script} $out/opt/${binaryName}/.${binaryName}-wrapped" \
                  --run ''
          ]
          attrs.installPhase;

    }
  );
}
