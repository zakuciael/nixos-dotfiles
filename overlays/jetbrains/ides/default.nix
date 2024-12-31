{ lib, ... }:
let
  supportedIdes = [
    "clion"
    "datagrip"
    "dataspell"
    "gateway"
    "goland"
    "idea-ultimate"
    "mps"
    "phpstorm"
    "pycharm-professional"
    "rider"
    "ruby-mine"
    "rust-rover"
    "webstorm"
  ];

in
[
  (
    final: prev:
    let
      inherit (lib) optionalString;
    in
    {
      jetbrains = prev.jetbrains // {
        goland = prev.jetbrains.goland.overrideAttrs (attrs: {
          postFixup =
            (attrs.postFixup or "")
            + optionalString final.stdenv.isLinux ''
              if [ -f $out/goland/plugins/go-plugin/lib/dlv/linux/dlv ]; then
                rm $out/goland/plugins/go-plugin/lib/dlv/linux/dlv
              fi

              ln -s ${final.delve}/bin/dlv $out/goland/plugins/go-plugin/lib/dlv/linux/dlv
            '';
        });
      };
    }
  )
  (
    final: prev:
    let
      inherit (lib) optionalAttrs attrValues toLower;
      inherit (lib.my.mapper) toJavaProperties;
      inherit (final) stdenv writeText fetchurl;
      inherit (stdenv.hostPlatform) system;

      versions = builtins.fromJSON (builtins.readFile ./versions.json);
      products = versions."${system}" or (throw "Unsupported system: ${system}");

      mkPatchedJetbrainsProductDerivation =
        name:
        {
          vmopts ? null,
          config_path ? null,
          caches_path ? null,
          plugins_path ? null,
          logs_path ? null,
          extraProperties ? null,
        }@opts:
        let
          shouldOverride = builtins.any (opt: opt != null) (attrValues opts);
          ide =
            if !prev.jetbrains ? "${name}" then
              throw "JetBrains IDE with name ${name} is not in nixpkgs"
            else
              prev.jetbrains."${name}".overrideAttrs {
                inherit (products."${name}") version;

                buildNumber = products."${name}".build_number;
                src = fetchurl {
                  inherit (products."${name}") url sha256;
                };
              };
        in
        if shouldOverride then
          stdenv.mkDerivation rec {
            inherit (ide) meta version buildNumber;

            pname = meta.mainProgram + "-with-opts";
            baseName = meta.mainProgram;
            src = ide;
            dontInstall = true;
            dontFixup = true;
            nativeBuildInputs = ide.nativeBuildInputs or [ ];
            buildInputs = ide.buildInputs or [ ];

            buildPhase =
              let
                rootDir =
                  if stdenv.hostPlatform.isDarwin then
                    "Applications/${ide.product}.app/Contents"
                  else
                    meta.mainProgram;
                ideaPropertiesFile = toJavaProperties "${meta.mainProgram}" (
                  { }
                  // optionalAttrs (config_path != null) { "idea.config.path" = config_path; }
                  // optionalAttrs (caches_path != null) { "idea.system.path" = caches_path; }
                  // optionalAttrs (plugins_path != null) { "idea.plugins.path" = plugins_path; }
                  // optionalAttrs (logs_path != null) { "idea.log.path" = logs_path; }
                  // optionalAttrs (extraProperties != null) extraProperties
                );

                hiName = if ide.vmoptsIDE == "WEBIDE" then "WEBSTORM" else ide.vmoptsIDE;
                loName = toLower hiName;
                vmoptsName = loName + lib.optionalString stdenv.hostPlatform.is64bit "64" + ".vmoptions";
                vmoptsFile = lib.optionalString (vmopts != null) (writeText vmoptsName vmopts);
              in
              ''
                cp -r ${ide} $out
                chmod +w -R $out

                printf "$(cat ${ideaPropertiesFile})\n\n# Default config\n\n$(cat "$out/${rootDir}/bin/idea.properties")" > "$out/${rootDir}/bin/idea.properties"

                substituteInPlace "$out/${rootDir}/bin/${loName}" \
                  --replace-fail "${ide.vmoptsIDE}_VM_OPTIONS-'''" "${ide.vmoptsIDE}_VM_OPTIONS-'${vmoptsFile}'"

                sed "s|${ide.outPath}|$out|" \
                  -i $(realpath $out/bin/${meta.mainProgram})

                if test -f "$out/bin/${meta.mainProgram}-remote-dev-server"; then
                  sed "s|${ide.outPath}|$out|" \
                    -i $(realpath $out/bin/${meta.mainProgram}-remote-dev-server)
                fi
              '';
          }
        else
          ide;
    in
    {
      jetbrains =
        prev.jetbrains
        // (lib.listToAttrs (
          builtins.map (name: {
            inherit name;
            value = lib.makeOverridable (mkPatchedJetbrainsProductDerivation name) { };
          }) supportedIdes
        ));
    }
  )
]
