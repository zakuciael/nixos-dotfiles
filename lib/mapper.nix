{
  lib,
  pkgs,
}:
with lib; rec {
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

  # TODO: Replace with `lib.hm.generators.toHyprconf` when nix-community/home-manager#5324 lands in a stable release
  toHyprconf = {
    attrs,
    indentLevel ? 0,
    importantPrefixes ? ["$"],
  }: let
    inherit
      (lib)
      all
      concatMapStringsSep
      concatStrings
      concatStringsSep
      filterAttrs
      foldl
      generators
      hasPrefix
      isAttrs
      isList
      mapAttrsToList
      replicate
      ;

    initialIndent = concatStrings (replicate indentLevel "  ");

    toHyprconf' = indent: attrs: let
      sections =
        filterAttrs (n: v: isAttrs v || (isList v && all isAttrs v)) attrs;

      mkSection = n: attrs:
        if lib.isList attrs
        then (concatMapStringsSep "\n" (a: mkSection n a) attrs)
        else ''
          ${indent}${n} {
          ${toHyprconf' "  ${indent}" attrs}${indent}}
        '';

      mkFields = generators.toKeyValue {
        listsAsDuplicateKeys = true;
        inherit indent;
      };

      allFields =
        filterAttrs (n: v: !(isAttrs v || (isList v && all isAttrs v)))
        attrs;

      isImportantField = n: _:
        foldl (acc: prev:
          if hasPrefix prev n
          then true
          else acc)
        false
        importantPrefixes;

      importantFields = filterAttrs isImportantField allFields;

      fields =
        builtins.removeAttrs allFields
        (mapAttrsToList (n: _: n) importantFields);
    in
      mkFields importantFields
      + concatStringsSep "\n" (mapAttrsToList mkSection sections)
      + mkFields fields;
  in
    toHyprconf' initialIndent attrs;

  toCfg = name: attrs: let
    # This script fix problem for nitrogen, becauses for some resons
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
}
