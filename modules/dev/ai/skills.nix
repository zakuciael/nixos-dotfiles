{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mapAttrs
    filterAttrs
    mergeAttrsList
    ;

  cfg = config.modules.dev.ai.skills;

  sources =
    lib.importJSON ./skills/sources.json
    |> lib.mapAttrs (
      _: src:
      pkgs.fetchFromGitHub {
        inherit (src)
          owner
          repo
          rev
          hash
          ;
      }
    );

  # Directories that contain a SKILL.md become skills named after the directory.
  skillsFromDir =
    dir:
    if !(builtins.pathExists dir) then
      { }
    else
      builtins.readDir dir
      |> filterAttrs (name: type: type == "directory" && builtins.pathExists (dir + "/${name}/SKILL.md"))
      |> mapAttrs (name: _: dir + "/${name}");

  skillsFromSubpaths =
    {
      src,
      base ? null,
      subpaths ? [ ],
    }:
    subpaths
    |> map (subpath: skillsFromDir (src + (if base != null then "/${base}" else "") + "/${subpath}"))
    |> mergeAttrsList;

  skills =
    (skillsFromDir ./skills/custom)
    // (skillsFromDir "${pkgs.postplan.src}/skills")
    // (skillsFromDir (sources.nix-skills + "/skills"))
    // (skillsFromSubpaths {
      src = sources.cursor-plugins;
      base = "pstack";
      subpaths = [
        "skills/unslop"
      ];
    })
    // (skillsFromSubpaths {
      src = sources.mattpocock-skills;
      subpaths = [
        "skills/engineering"
        "skills/in-progress"
        "skills/misc"
        "skills/productivity"
      ];
    })
    // (skillsFromSubpaths {
      src = sources.humanlayer-skills;
      base = "plugins";
      subpaths = [
        "show-me"
        "visual-pr"
      ];
    });
in
{
  options.modules.dev.ai.skills = {
    enable = mkEnableOption "declarative AI skills";
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      programs = {
        opencode.skills = skills;
        codex.skills = skills;
        claude-code.skills = skills;
        cursor-agent.skills = skills;
      };
    };
  };
}
