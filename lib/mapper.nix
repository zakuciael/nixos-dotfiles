{
  lib,
  pkgs,
}:
with lib;
with lib.my;
with lib.my.utils; rec {
  mapDirToAttrs = path:
    builtins.mapAttrs
    (n: v: let
      source = path + "/${n}";
      sourceAttrs = {inherit source;};
    in
      if v == "regular"
      then sourceAttrs
      else sourceAttrs // mapDirToAttrs source)
    (attrsets.filterAttrs (n: v: n != ".git") (builtins.readDir path));

  mapKeyToNumpad = num: let
    keys = [
      "KP_End"
      "KP_Down"
      "KP_Next"
      "KP_Left"
      "KP_Begin"
      "KP_Right"
      "KP_Home"
      "KP_Up"
      "KP_Prior"
      "KP_Insert"
    ];
  in
    builtins.elemAt keys (num - 1);

  toString = value:
    if builtins.typeOf value == "bool"
    then (boolToString value)
    else (builtins.toString value);

  fromYAML = f: let
    jsonFile =
      pkgs.runCommand "in.json"
      {nativeBuildInputs = [pkgs.remarshal];}
      ''yaml2json < "${f}" > "$out"'';
  in
    builtins.fromJSON (builtins.readFile jsonFile);

  toINI = name: attrs: (pkgs.formats.ini {}).generate name attrs;

  toTOML = name: attrs: (pkgs.formats.toml {}).generate name attrs;

  toYAML = name: attrs: (pkgs.formats.yaml {}).generate name attrs;

  toJSON = name: attrs: (pkgs.formats.json {}).generate name attrs;

  toJavaProperties = name: attrs: (pkgs.formats.javaProperties {}).generate name attrs;

  toRasiKeyValue = {indent ? ""}: name: value:
    if isRasiSection value
    then toRasiSection {inherit indent;} name value # Sections
    else if isMultiEntry value
    then concatStringsSep "\n" (builtins.map (v: toRasiKeyValue {inherit indent;} name v) value.data) # Multi entry
    else if hasPrefix "@import" name || hasPrefix "@theme" name
    then "${indent}${name} ${toRasiValue name (
      if isDerivation value
      then "${value}"
      else value
    )}" # Imports and Themes
    else "${indent}${name}: ${toRasiValue name value};"; # Normal values

  toRasiSection = {indent ? ""}: name: value:
    mkAssertions "toRasiSection" [
      {
        assertion = (isAttrs value) && !(isLiteral value);
        message = "${name} is a ${typeOf value} while a set was expected";
      }
    ] (
      let
        configStr = toRasi {indent = indent + "  ";} value;
      in ''
        ${indent}${name} {
        ${configStr}
        ${indent}}''
    );

  toRasiValue = name: value: let
    formatters = {
      "bool" = {
        test = isBool;
        mapper = _: boolToString;
      };
      "int" = {
        test = isInt;
        mapper = _: builtins.toString;
      };
      "string" = {
        test = isString;
        mapper = _: value: ''"${value}"'';
      };
      "list" = {
        test = isList;
        mapper = name: value: "[ ${
          strings.concatStringsSep
          ","
          (imap0 (i: v: toRasiValue "${name}[${toString i}]" v) value)
        } ]";
      };
      "literal" = {
        test = isLiteral;
        mapper = _: value: value.data;
      };
    };
  in
    mkAssertions "toRasiValue" [
      {
        assertion = builtins.any (test: test value) (mapAttrsToList (_: x: x.test) formatters);
        message = "${name} is a ${utils.typeOf value} while one of [${
          concatStringsSep
          ", "
          (builtins.attrNames formatters)
        }] was expected";
      }
    ] (formatters.${utils.typeOf value}.mapper name value);

  toRasi = {indent ? ""}: attrs:
    mkAssertions "toRasi" [
      {
        assertion = isAttrs attrs;
        message = "value is a ${utils.typeOf attrs} while a set was expected";
      }
    ] (let
      filteredAttrs =
        filterAttrs
        (_: value: value.data != null) (toDag attrs);
    in
      concatStringsSep "\n"
      (
        builtins.map ({
          name,
          data,
        }:
          toRasiKeyValue {inherit indent;} name data)
        (utils.sortAttrs filteredAttrs)
      ));
}
