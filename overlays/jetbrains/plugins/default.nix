{lib, ...}: let
  inherit (lib) singleton;
in
  singleton (final: prev: let
    inherit (lib) optional isDerivation hasSuffix unique optionalString;
    inherit (final) callPackage fetchurl fetchzip stdenv autoPatchelfHook glib;
  in {
    jetbrains =
      prev.jetbrains
      // {
        # Local version of `jetbrains.plugins` to easily install and update plugins
        # Copied from: https://github.com/NixOS/nixpkgs/blob/6d8ddd87dc098ac9fb0468a80d2d94c400c5f856/pkgs/applications/editors/jetbrains/plugins/default.nix
        # All credits go to the package maintainers
        plugins = let
          pluginsJson = builtins.fromJSON (builtins.readFile ./plugins.json);
          specialPluginsInfo = callPackage ./specialPlugins.nix {};
          fetchPluginSrc = url: hash: let
            isJar = hasSuffix ".jar" url;
            fetcher =
              if isJar
              then fetchurl
              else fetchzip;
          in
            fetcher {
              executable = isJar;
              inherit url hash;
            };
          files = builtins.mapAttrs (key: value: fetchPluginSrc key value) pluginsJson.files;
          ids = builtins.attrNames pluginsJson.plugins;

          mkPlugin = id: file:
            if !specialPluginsInfo ? "${id}"
            then files."${file}"
            else
              stdenv.mkDerivation ({
                  name = "jetbrains-plugin-${id}";
                  installPhase = ''
                    runHook preInstall
                    mkdir -p $out && cp -r . $out
                    runHook postInstall
                  '';
                  src = files."${file}";
                }
                // specialPluginsInfo."${id}");

          selectFile = id: ide: build:
            if !builtins.elem ide pluginsJson.plugins."${id}".compatible
            then throw "Plugin with id ${id} (${pluginsJson.plugins."${id}".name}) does not support IDE ${ide}"
            else if !pluginsJson.plugins."${id}".builds ? "${build}"
            then throw "Jetbrains IDEs with build ${build} (${ide}) are not in nixpkgs. Try update_plugins.py with --with-build?"
            else if pluginsJson.plugins."${id}".builds."${build}" == null
            then throw "Plugin with id ${id} (${pluginsJson.plugins."${id}".name}) does not support build ${build} (${ide})"
            else pluginsJson.plugins."${id}".builds."${build}";

          byId =
            builtins.listToAttrs
            (map
              (id: {
                name = id;
                value = ide: build: mkPlugin id (selectFile id ide build);
              })
              ids);

          byName =
            builtins.listToAttrs
            (map
              (id: {
                name = pluginsJson.plugins."${id}".name;
                value = byId."${id}";
              })
              ids);
        in {
          # Only use if you know what you are doing
          raw = {inherit files byId byName ids;};

          addPlugins = ide: unprocessedPlugins: let
            processPlugin = plugin:
              if isDerivation plugin
              then plugin
              else if byId ? "${plugin}"
              then byId."${plugin}" (ide.baseName or ide.pname) ide.buildNumber
              else if byName ? "${plugin}"
              then byName."${plugin}" (ide.baseName or ide.pname) ide.buildNumber
              else throw "Could not resolve plugin ${plugin}";

            plugins = map processPlugin unprocessedPlugins;
          in
            stdenv.mkDerivation rec {
              pname = meta.mainProgram + "-with-plugins";
              baseName = ide.baseName or meta.mainProgram;
              version = ide.version;
              src = ide;
              dontInstall = true;
              dontFixup = true;
              passthru.plugins = plugins ++ (ide.plugins or []);
              newPlugins = plugins;
              disallowedReferences = [ide];
              nativeBuildInputs = (optional stdenv.hostPlatform.isLinux autoPatchelfHook) ++ (ide.nativeBuildInputs or []);
              buildInputs = unique ((ide.buildInputs or []) ++ [glib]);

              inherit (ide) meta;

              buildPhase = let
                rootDir =
                  if stdenv.hostPlatform.isDarwin
                  then "Applications/${ide.product}.app/Contents"
                  else meta.mainProgram;
              in
                ''
                  cp -r ${ide} $out
                  chmod +w -R $out
                  rm -f $out/${rootDir}/plugins/plugin-classpath.txt
                  IFS=' ' read -ra pluginArray <<< "$newPlugins"
                  for plugin in "''${pluginArray[@]}"
                  do
                    ln -s "$plugin" -t "$out/${rootDir}/plugins/"
                  done
                  sed "s|${ide.outPath}|$out|" \
                    -i $(realpath $out/bin/${meta.mainProgram})

                  if test -f "$out/bin/${meta.mainProgram}-remote-dev-server"; then
                    sed "s|${ide.outPath}|$out|" \
                      -i $(realpath $out/bin/${meta.mainProgram}-remote-dev-server)
                  fi

                ''
                + optionalString stdenv.hostPlatform.isLinux ''
                  autoPatchelf $out
                '';
            };
        };
      };
  })
