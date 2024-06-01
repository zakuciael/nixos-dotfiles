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

  toINI = name: attrs: (pkgs.formats.ini {}).generate name attrs;

  toTOML = name: attrs: (pkgs.formats.toml {}).generate name attrs;

  toCfg = name: attrs: let
    # This script fix problem for nitrogen, because for some reason
    # nitrogen read path with " chars and throws exception for that
    fixCfgPaths =
      builtins.toFile "fixCfgPaths.py"
      /*
      python
      */
      ''
        #!/usr/bin/env python
        from typing import List
        import sys

        if len(sys.argv) < 2:
          raise AssertionError("Missing required input file")

        content: List[str] = []
        inputFile = sys.argv[1]

        with open(inputFile, "r") as f:
            for line in f:
                content.append(line)

        if len(content) <= 0:
            raise AssertionError("file is empty")

        with open(inputFile, "w") as f:
            for i, line in enumerate(content):
                if "/" in line:
                    content[i] = line.replace("\"", "")

            f.writelines(content)
      '';
  in
    (toTOML name attrs).overrideAttrs
    (final: prev: {
      nativeBuildInputs = prev.nativeBuildInputs ++ [pkgs.python3];
      buildCommand =
        /*
        bash
        */
        ''
          json2toml "$valuePath" $out
          python ${fixCfgPaths} $out
        '';
    });

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
