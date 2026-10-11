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
    home-manager.users.${username} =
      let
        # Coerce to a store path string: a derivation is an attrset, so either(attrs, path)
        # types would otherwise try to merge drv internals into skills.
        skills = "${pkgs.ai-skills}";
      in
      {
        programs = {
          opencode.skills = skills;
          codex.skills = skills;
          claude-code.skills = skills;
          cursor-agent.skillsDir = skills;
        };
      };
  };
}
