{
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.hm.dag; let
  inherit (lib.my.mapper) toRasi;
  inherit (pkgs) writeTextFile;
in rec {
  recursiveReadDir = path: {
    ignoredDirs ? [],
    suffixes ? [],
  } @ settings:
    builtins.filter (file: file != null) (flatten (
      mapAttrsToList (name: value: let
        newPath = "${path}/${name}";
      in
        if value == "regular"
        then
          if suffixes == [] || builtins.any (ext: hasSuffix ext newPath) suffixes
          then newPath
          else null
        else recursiveReadDir newPath settings)
      (
        filterAttrs (name: _:
          builtins.all (dir: name != dir) ignoredDirs)
        (builtins.readDir path)
      )
    ));

  findLayoutConfig = with lib;
    config: predicate: let
      default = {
        index = null;
        data = null;
      };
      mappedLayouts =
        imap0
        (index: data: {inherit index data;})
        config.modules.hardware.layout.layout;
    in
      getAttr "data" (findFirst predicate default mappedLayouts);

  findLayoutWorkspace = layoutConfig: predicate: let
    workspaces = builtins.map (x: x.value // {inherit (x) name;}) (attrsToList layoutConfig.workspaces);
  in
    findFirst predicate null workspaces;

  getLayoutMonitor = layoutConfig: wmType:
    getAttr "${wmType}" layoutConfig.monitor;

  typeOf = value:
    if isLiteral value
    then "literal"
    else if isMultiEntry value
    then "multi entry"
    else (builtins.typeOf value);

  indentLines = prefix: str:
    concatMapStringsSep "\n" (line: prefix + line) (splitString "\n" str);

  isRasiSection = value:
    isAttrs value && !(isLiteral value) && !(isMultiEntry value) && (!isDerivation value);

  isLiteral = value:
    isAttrs value && value ? _type && value._type == "literal";

  isMultiEntry = value:
    isAttrs value && value ? _type && value._type == "multi_entry";

  isDerivation = value:
    isAttrs value && value ? drvPath && value ? drvAttrs;

  mkGtkBookmark = {
    name ? null,
    path,
  }: ''file://${builtins.toPath path}${optionalString (name != null) " ${name}"}'';

  mkLiteral = value: {
    _type = "literal";
    data = value;
  };

  mkMultiEntry = value: {
    _type = "multi_entry";
    data = value;
  };

  mkAssertions = name: assertions: value: let
    failedAssertions = builtins.map (x: x.message) (builtins.filter (x: !x.assertion) assertions);
  in
    if failedAssertions != []
    then throw "${name} failed assertions:\n${concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
    else value;

  toDag = attrs:
    if !(isDag attrs)
    then
      (builtins.mapAttrs (_: value:
        if !(isEntry value)
        then entryAnywhere value
        else value)
      attrs)
    else attrs;

  sortAttrs = attrs: let
    sortedAttrs = topoSort (toDag attrs);
    sortedAttrsStr = builtins.toJSON sortedAttrs;
    newAttrs =
      if sortedAttrs ? result
      then sortedAttrs.result
      else abort "Unable to sort, dependency cycle detected: ${sortedAttrsStr}";
  in
    newAttrs;

  writeRofiScript = {
    name,
    config,
    text,
    runtimeEnv ? {},
    meta ? {},
    runtimeInputs ? [],
    imports ? [],
    theme ? {},
    configuration ? {},
  }: let
    configFile = pkgs.writeTextFile {
      name = "config.rasi";
      text = ''
        /* Configuration */
        ${optionalString (configuration != {}) (toRasi {} {configuration = configuration;})}
        /* Imports */
        ${optionalString (imports != []) (toRasi {} {"@import" = mkMultiEntry imports;})}
        /* Theme */
        ${optionalString (theme != {}) (toRasi {} theme)}
      '';
    };
  in
    pkgs.writeShellApplication {
      inherit name meta text;
      runtimeInputs = [config.home-manager.users.${username}.programs.rofi.finalPackage] ++ runtimeInputs;
      runtimeEnv =
        runtimeEnv
        // {
          ROFI_CONFIG_FILE = configFile;
        };
    };

  writeRasiFile = {
    name,
    attrs,
    destination ? "",
  }:
    writeTextFile {
      inherit name destination;
      text = toRasi {} attrs;
    };
}
