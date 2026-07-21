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
    ;

  cfg = config.modules.dev.ai;
in
{
  options.modules.dev.ai = {
    enable = mkEnableOption "AI tooling";
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = with pkgs; [
        # Coding Agents
        opencode

        (t3code.override {
          enableCursor = true;
          enableCursorCli = true;
          enableOpencode = true;
          enableGitHub = true;
          enableGit = true;
        })
        cursor-cli
        code-cursor-fhs

        # Agent skills
        skills
      ];
    };
  };
}
