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
        opencode-desktop

        (t3code.override {
          enableClaude = true;
          enableCodex = true;
          enableCursor = true;
          enableCursorCli = true;
          enableGitHub = true;
          enableGit = true;
          enableOpencode = true;
          enableResourceMonitor = true;
        })
        cursor-cli
        code-cursor-fhs

        # Agent skills
        skills
      ];
    };
  };
}
