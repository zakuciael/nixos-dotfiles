{
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.hm.dag;
let
  inherit (lib.my.mapper) fromYAML toRasi mapKeyToNumpad;
  inherit (pkgs) writeTextFile;
in
rec {
  recursiveReadDir =
    path:
    {
      ignoredDirs ? [ ],
      suffixes ? [ ],
    }@settings:
    builtins.filter (file: file != null) (
      flatten (
        mapAttrsToList (
          name: value:
          let
            newPath = "${path}/${name}";
          in
          if value == "regular" then
            if suffixes == [ ] || builtins.any (ext: hasSuffix ext newPath) suffixes then newPath else null
          else
            recursiveReadDir newPath settings
        ) (filterAttrs (name: _: builtins.all (dir: name != dir) ignoredDirs) (builtins.readDir path))
      )
    );

  recursiveImportDir =
    path:
    {
      ignoredDirs ? [ ],
    }@settings:
    builtins.filter (file: file != null) (
      flatten (
        mapAttrsToList (
          name: value:
          let
            newPath = "${path}/${name}";
          in
          if value == "regular" then
            (
              if
                builtins.match ".*\\.nix" name != null
                &&
                  # ignore Emacs lock files (.#foo.nix)
                  builtins.match "\\.#.*" name == null
              then
                newPath
              else
                null
            )
          else
            (
              if builtins.pathExists (newPath + "/default.nix") then
                newPath
              else
                recursiveImportDir newPath settings
            )
        ) (filterAttrs (name: _: builtins.all (dir: name != dir) ignoredDirs) (builtins.readDir path))
      )
    );

  recursiveReadSecretNames =
    {
      config,
      base ? null,
    }:
    let
      secrets = readSecrets { inherit config base; };
    in
    if builtins.isString secrets then
      [ base ]
    else if builtins.isAttrs secrets then
      let
        result = builtins.map (
          name:
          recursiveReadSecretNames {
            inherit config;
            base = "${removeSuffix "/" base}/${name}";
          }
        ) (builtins.attrNames secrets);
      in
      flatten result
    else
      null;

  readSecrets =
    {
      config,
      base ? null,
    }:
    let
      basePath = builtins.filter (v: v != "") (splitString "/" base);
      fullSecrets = fromYAML config.sops.defaultSopsFile;
      secrets = if base != null then (attrByPath basePath null fullSecrets) else fullSecrets;
    in
    secrets;

  mkSecretName = path: concatStringsSep "/" (builtins.map (v: removeSuffix "/" v) path);

  mkSecretPlaceholder = config: path: config.sops.placeholder."${mkSecretName path}";

  mkSecretPath = config: path: config.sops.secrets."${mkSecretName path}".path;

  findLayoutConfig =
    with lib;
    config: predicate:
    let
      default = {
        name = null;
        index = null;
        data = null;
      };
      mappedLayouts = imap0 (index: data: {
        inherit (data) name;
        inherit index data;
      }) config.modules.hardware.layout.layout;
    in
    getAttr "data" (findFirst predicate default mappedLayouts);

  findLayoutWorkspace =
    layoutConfig: predicate:
    let
      arr = attrsToList layoutConfig.workspaces;
      workspaces = imap1 (
        i: x:
        x.value
        // {
          inherit (x) name;
          last = i == (builtins.length arr);
        }
      ) arr;
    in
    findFirst predicate null workspaces;

  getLayoutMonitor = layoutConfig: wmType: getAttr "${wmType}" layoutConfig.monitor;

  typeOf =
    value:
    if isLiteral value then
      "literal"
    else if isMultiEntry value then
      "multi entry"
    else
      (builtins.typeOf value);

  indentLines = prefix: str: concatMapStringsSep "\n" (line: prefix + line) (splitString "\n" str);

  isRasiSection =
    value: isAttrs value && !(isLiteral value) && !(isMultiEntry value) && (!isDerivation value);

  isLiteral = value: isAttrs value && value ? _type && value._type == "literal";

  isMultiEntry = value: isAttrs value && value ? _type && value._type == "multi_entry";

  isDerivation = value: isAttrs value && value ? drvPath && value ? drvAttrs;

  mkGtkBookmark =
    {
      name ? null,
      path,
    }:
    ''file://${builtins.toPath path}${optionalString (name != null) " ${name}"}'';

  mkLiteral = value: {
    _type = "literal";
    data = value;
  };

  mkMultiEntry = value: {
    _type = "multi_entry";
    data = value;
  };

  mkAssertions =
    name: assertions: value:
    let
      failedAssertions = builtins.map (x: x.message) (builtins.filter (x: !x.assertion) assertions);
    in
    if failedAssertions != [ ] then
      throw "${name} failed assertions:\n${concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
    else
      value;

  mkLayoutWorkspaces =
    names:
    builtins.listToAttrs (
      builtins.map (
        name:
        let
          fixedName = toString name;
        in
        {
          name = fixedName;
          value = {
            keybinds = [
              fixedName
              (mapKeyToNumpad name)
            ];
          };
        }
      ) names
    );

  toDag =
    attrs:
    if !(isDag attrs) then
      (builtins.mapAttrs (_: value: if !(isEntry value) then entryAnywhere value else value) attrs)
    else
      attrs;

  sortAttrs =
    attrs:
    let
      sortedAttrs = topoSort (toDag attrs);
      sortedAttrsStr = builtins.toJSON sortedAttrs;
      newAttrs =
        if sortedAttrs ? result then
          sortedAttrs.result
        else
          abort "Unable to sort, dependency cycle detected: ${sortedAttrsStr}";
    in
    newAttrs;

  writeRofiScript =
    {
      name,
      config,
      text,
      runtimeEnv ? { },
      meta ? { },
      runtimeInputs ? [ ],
      imports ? [ ],
      theme ? { },
      configuration ? { },
    }:
    let
      configFile = pkgs.writeTextFile {
        name = "config.rasi";
        text = ''
          /* Configuration */
          ${optionalString (configuration != { }) (toRasi { } { configuration = configuration; })}
          /* Imports */
          ${optionalString (imports != [ ]) (toRasi { } { "@import" = mkMultiEntry imports; })}
          /* Theme */
          ${optionalString (theme != { }) (toRasi { } theme)}
        '';
      };
    in
    pkgs.writeShellApplication {
      inherit name meta text;
      runtimeInputs = [
        config.home-manager.users.${username}.programs.rofi.finalPackage
      ] ++ runtimeInputs;
      runtimeEnv = runtimeEnv // {
        ROFI_CONFIG_FILE = configFile;
      };
    };

  writeRasiFile =
    {
      name,
      attrs,
      destination ? "",
    }:
    writeTextFile {
      inherit name destination;
      text = toRasi { } attrs;
    };
}
