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

  # Install skills from a directory into $out:
  # - If the directory itself contains SKILL.md, symlink it as one skill.
  # - Otherwise install every immediate subdirectory that contains SKILL.md.
  # Later calls overwrite earlier ones on name conflicts (same as attrset //).
  installSkillsFromDir =
    dir: # bash
    ''
      source=${lib.escapeShellArg dir}
      if [ -d "$source" ]; then
        if [ -f "$source/SKILL.md" ]; then
          ln -sfn "$source" "$out/$(basename "$source")"
        else
          for skill in "$source"/*; do
            [ -d "$skill" ] || continue
            [ -f "$skill/SKILL.md" ] || continue
            ln -sfn "$skill" "$out/$(basename "$skill")"
          done
        fi
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

    ${installSkillsFromDir "${sources.claude-code}/plugins/frontend-design/skills"}

    ${installSkillsFrom {
      src = sources.vercel-labs-agent-skills;
      base = "skills";
      subpaths = [
        "react-best-practices"
        "react-view-transitions"
        "web-design-guidelines"
        "writing-guidelines"
        "composition-patterns"
      ];
    }}

    ${installSkillsFromDir "${sources.ecc}/skills/react-patterns"}

    # Repo root is the skill; only SKILL.md + rules/ are needed.
    mkdir -p "$out/rust-skills"
    ln -sfn ${sources.rust-skills}/SKILL.md "$out/rust-skills/SKILL.md"
    ln -sfn ${sources.rust-skills}/rules "$out/rust-skills/rules"

    ${installSkillsFromDir "${sources.actionbook-rust-skills}/skills"}
    ${installSkillsFromDir "${sources.cnwzhu-gpui-skills}"}
    ${installSkillsFromDir "${sources.longbridge-gpui-kit}/skills"}

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
