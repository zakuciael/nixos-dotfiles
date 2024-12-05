{lib, ...}: let
in [
  (final: prev: let
    inherit (lib) optionalString;
  in {
    jetbrains =
      prev.jetbrains
      // {
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
  })
  (final: prev: let
    inherit (lib) optionalString optionalAttrs;
    inherit (lib.my.mapper) toJavaProperties;

    mkPatchedJetbrainsProductDerivation = name: {
      vmopts ? null,
      config_path ? null,
      caches_path ? null,
      plugins_path ? null,
      logs_path ? null,
      extraProperties ? null,
    }: let
      pkg =
        if !prev.jetbrains ? "${name}"
        then throw "JetBrains IDE with name ${name} is not in nixpkgs"
        else prev.jetbrains."${name}";
    in
      (pkg.override {
        inherit vmopts;
      })
      .overrideAttrs (prevAttrs: rec {
        ideaPropertiesIDE = pkg.vmoptsIDE;
        ideaPropertiesFile =
          optionalString
          (config_path != null || caches_path != null || plugins_path != null || logs_path != null || extraProperties != null)
          (
            toJavaProperties "idea.properties" ({}
              // optionalAttrs (config_path != null) {"idea.config.path" = config_path;}
              // optionalAttrs (caches_path != null) {"idea.system.path" = caches_path;}
              // optionalAttrs (plugins_path != null) {"idea.plugins.path" = plugins_path;}
              // optionalAttrs (logs_path != null) {"idea.log.path" = logs_path;}
              // optionalAttrs (extraProperties != null) extraProperties)
          );

        installPhase =
          builtins.replaceStrings
          [''--set-default JDK_HOME "$jdk" \'']
          [
            ''
              --set-default ${ideaPropertiesIDE}_PROPERTIES "${ideaPropertiesFile}" \
                --set-default JDK_HOME "$jdk" \''
          ]
          prevAttrs.installPhase;
      });
    ides = [
      "clion"
      "datagrip"
      "dataspell"
      "gateway"
      "goland"
      "idea-community"
      "idea-ultimate"
      "mps"
      "phpstorm"
      "pycharm-community"
      "pycharm-professional"
      "rider"
      "ruby-mine"
      "rust-rover"
      "webstorm"
    ];
  in {
    jetbrains =
      prev.jetbrains
      // (lib.listToAttrs (builtins.map (name: {
          inherit name;
          value = lib.makeOverridable (mkPatchedJetbrainsProductDerivation name) {};
        })
        ides));
  })
]
