{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  postplan,
}:
let
  sources =
    lib.importJSON ./sources.json
    |> lib.mapAttrs (
      _: src:
      fetchFromGitHub {
        inherit (src)
          owner
          repo
          rev
          hash
          ;
      }
    );

  # Install every immediate subdirectory that contains SKILL.md into $out.
  # Later calls overwrite earlier ones on name conflicts (same as attrset //).
  installSkillsFromDir =
    dir: # bash
    ''
      if [ -d ${lib.escapeShellArg dir} ]; then
        for skill in ${lib.escapeShellArg dir}/*; do
          [ -d "$skill" ] || continue
          [ -f "$skill/SKILL.md" ] || continue
          ln -sfn "$skill" "$out/$(basename "$skill")"
        done
      fi
    '';

  # Like installSkillsFromDir, but for selected subpaths under a source tree.
  installSkillsFrom =
    {
      src,
      base ? null,
      subpaths ? [ ],
    }:
    subpaths
    |> map (
      subpath:
      installSkillsFromDir (src + (if base != null then "/${base}" else "") + "/${subpath}")
    )
    |> lib.concatStrings;
in
stdenvNoCC.mkDerivation {
  pname = "ai-skills";
  version = "0-unstable";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"

    ${installSkillsFromDir ./custom}
    ${installSkillsFromDir "${postplan.src}/skills"}
    ${installSkillsFromDir "${sources.nix-skills}/skills"}

    # Single skill directory (not a container of skills).
    ln -sfn ${sources.cursor-plugins}/pstack/skills/unslop "$out/unslop"

    ${installSkillsFrom {
      src = sources.mattpocock-skills;
      subpaths = [
        "skills/engineering"
        "skills/in-progress"
        "skills/misc"
        "skills/productivity"
      ];
    }}

    ${installSkillsFrom {
      src = sources.humanlayer-skills;
      base = "plugins";
      subpaths = [
        "show-me/skills"
        "visual-pr/skills"
      ];
    }}

    runHook postInstall
  '';

  passthru = {
    inherit sources;
    updateScript = ./update.sh;
  };

  meta = {
    description = "Bundled AI agent skills from configured upstream sources";
    platforms = lib.platforms.all;
  };
}
