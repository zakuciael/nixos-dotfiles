{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modules.dev.ai.skills;
in
{
  options.modules.dev.ai.skills = {
    enable = mkEnableOption "declarative AI skills";
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      programs = {
        opencode.skills = pkgs.ai-skills;
        codex.skills = pkgs.ai-skills;
        claude-code.skills = pkgs.ai-skills;
        cursor-agent.skillsDir = pkgs.ai-skills;
      };
    };
  };
}
