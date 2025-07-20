{ lib, ... }:
let
  inherit (lib)
    singleton
    listToAttrs
    optionalAttrs
    optionalString
    filterAttrs
    attrValues
    toLower
    makeOverridable
    concatStringsSep
    ;
  inherit (lib.asserts) assertMsg;
  inherit (lib.my.mapper) toJavaProperties;

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
singleton (
  final: prev:
  let
    inherit (final)
      stdenv
      fetchurl
      symlinkJoin
      makeWrapper
      writeText
      ;
    inherit (stdenv.hostPlatform) system is64bit;

    versions = ./versions.json |> builtins.readFile |> builtins.fromJSON;
    products = versions."${system}" or (throw "Unsupported system: ${system}");

    mkIDE =
      name:
      {
        vmopts ? null,
        config_path ? null,
        caches_path ? null,
        plugins_path ? null,
        logs_path ? null,
        extra_properties ? null,
      }@opts:
      assert assertMsg (
        vmopts == null || (builtins.isList vmopts) && (vmopts |> builtins.all (val: builtins.isString val))
      ) "vmopts is not of type 'list of strings'";
      assert assertMsg (
        config_path == null || builtins.isString config_path
      ) "config_path is not of type 'string'";
      assert assertMsg (
        caches_path == null || builtins.isString config_path
      ) "caches_path is not of type 'string'";
      assert assertMsg (
        plugins_path == null || builtins.isString plugins_path
      ) "plugins_path is not of type 'string'";
      assert assertMsg (
        logs_path == null || builtins.isString logs_path
      ) "logs_path is not of type 'string'";
      assert assertMsg (
        extra_properties == null || builtins.isAttrs extra_properties
      ) "extra_properties is not of type 'attrs'";
      let
        override_properties =
          opts |> filterAttrs (n: _: n != "vmopts") |> attrValues |> builtins.any (opt: opt != null);
        override_vmopts = vmopts != null;

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

        inherit (ide) meta;
        root_dir =
          if stdenv.hostPlatform.isDarwin then
            "Applications/${ide.product}.app/Contents"
          else
            meta.mainProgram;

        properties_file = toJavaProperties "${meta.mainProgram}" (
          { }
          // optionalAttrs (config_path != null) { "idea.config.path" = config_path; }
          // optionalAttrs (caches_path != null) { "idea.system.path" = caches_path; }
          // optionalAttrs (plugins_path != null) { "idea.plugins.path" = plugins_path; }
          // optionalAttrs (logs_path != null) { "idea.log.path" = logs_path; }
          // optionalAttrs (extra_properties != null) extra_properties
        );

        ide_name = toLower (if ide.vmoptsIDE == "WEBIDE" then "WEBSTORM" else ide.vmoptsIDE);
        vmopts_file_name = ide_name + (optionalString is64bit "64") + ".vmoptions";
        vmopts_file = optionalString override_vmopts (
          writeText vmopts_file_name (vmopts |> concatStringsSep "\n")
        );
      in
      if override_properties || override_vmopts then
        symlinkJoin {
          inherit (ide) meta pname version;
          name = "${ide.pname}-with-opts-${ide.version}";

          paths = [ ide ];
          buildInputs = [ makeWrapper ];

          postBuild = ''
            # Copies the original file to make it writable and returns its path
            makeWritable() {
              local input="$1"

              if [ ! -f "$input" ]; then
                echo "makeWritable(): ERROR: file '$input' does not exist" >&2
                return 1
              fi

              mv $input{,.orig}
              cp $(realpath $input.orig) $input
              rm -rf $input.orig
              chmod +w $input

              echo "$input"
            }

            ${optionalString override_properties ''
              # Add custom properties file to the install directory
              printf "$(cat ${properties_file})\n\n# Default config\n\n$(cat $(makeWritable "$out/${root_dir}/bin/idea.properties"))" > "$out/${root_dir}/bin/idea.properties"
            ''}

            needsWrapping=()

            if [ -f "$out/${root_dir}/bin/${ide_name}" ]; then
              needsWrapping+=("$out/${root_dir}/bin/${ide_name}")
            fi
            if [ -f "$out/${root_dir}/bin/${ide_name}.sh" ]; then
              needsWrapping+=("$out/${root_dir}/bin/${ide_name}.sh")
            fi

            for launcher in "''${needsWrapping[@]}"
            do
              substituteInPlace $(makeWritable "$launcher") \
                --replace-fail "${ide.outPath}" "$out"

              wrapProgram "$launcher" \
                --set-default "${ide.vmoptsIDE}_VM_OPTIONS" "${vmopts_file}" \
                --set-default "${ide.vmoptsIDE}_PROPERTIES" "$out/${root_dir}/bin/idea.properties"
            done

            if [ -f "$out/${root_dir}/bin/remote-dev-server-wrapped.sh" ]; then
              substituteInPlace $(makeWritable "$out/${root_dir}/bin/remote-dev-server-wrapped.sh") \
                --replace-fail "${ide.outPath}" "$out"
            fi
          '';
        }
      else
        ide;

  in
  {
    jetbrains =
      prev.jetbrains
      // (
        supportedIdes
        |> builtins.map (name: {
          inherit name;
          value = makeOverridable (mkIDE name) { };
        })
        |> listToAttrs
      );
  }
)
