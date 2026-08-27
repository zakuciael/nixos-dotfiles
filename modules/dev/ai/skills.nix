{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    ;
  inherit (lib.my) dotfiles;

  cfg = config.modules.dev.ai.skills;

  skillsDir = dotfiles.skills.source;
in
{
  options.modules.dev.ai.skills = {
    enable = mkEnableOption "declarative AI skills";
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      programs = {
        opencode.skills = skillsDir;
        codex.skills = skillsDir;
        claude-code.skills = skillsDir;
        cursor-agent.skillsDir = skillsDir;
      };
    };
  };
}
