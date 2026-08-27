{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.modules.dev.ai;
  configHome = config.home-manager.users.${username}.xdg.configHome;
in
{
  options.modules.dev.ai = {
    enable = mkEnableOption "AI tooling";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 3773 ];

    home-manager.users.${username} = {
      home.packages = with pkgs; [
        opencode-desktop
        skills
        postplan
      ];

      programs = {
        opencode.enable = true;
        t3code = {
          enable = true;
          package = pkgs.t3code.override {
            enableClaude = true;
            enableCodex = true;
            enableCursor = true;
            enableCursorCli = true;
            enableGitHub = true;
            enableGit = true;
            enableOpencode = true;
            enableResourceMonitor = true;
          };

          mutableClientSettings = true;
          mutableKeybindings = true;
          mutableUserSettings = true;

          clientSettings = {
            confirmThreadArchive = true;
            confirmThreadDelete = true;
            diffIgnoreWhitespace = true;
            environmentIdentificationMode = "artwork";
            glassOpacity = 80;
            fontSizeInterface = 17;
            fontSizePrompt = 14;
            fontSizeCode = 14;
            fontSizeTerminal = 12;
            fontFamilyCode = "JetBrainsMono Nerd Font Mono";
            fontFamilyComposer = "";
            fontFamilySans = "";
            fontFamilyTerminal = "";
            fontSmoothing = true;

            sidebarAutoSettleAfterDays = 3;
            sidebarProjectGroupingMode = "repository";
            timestampFormat = "24-hour";
            wordWrap = true;

            favorites = [
              {
                provider = "opencode";
                model = "opencode/deepseek-v4-flash-free";
              }
              {
                provider = "cursor";
                model = "gpt-5.6-sol";
              }
              {
                provider = "cursor";
                model = "gpt-5.6-luna";
              }
              {
                provider = "cursor";
                model = "kimi-k3";
              }
              {
                provider = "cursor";
                model = "default";
              }
              {
                provider = "cursor";
                model = "composer-2.5";
              }
              {
                provider = "cursor";
                model = "claude-fable-5";
              }
              {
                provider = "cursor";
                model = "claude-sonnet-5";
              }
              {
                provider = "cursor";
                model = "grok-4.6";
              }
              {
                provider = "cursor";
                model = "claude-opus-5";
              }
            ];
            providerModelPreferences = {
              claudeAgent = {
                hiddenModels = [
                  "claude-opus-4-6"
                  "claude-opus-4-5"
                ];
                modelOrder = [ ];
              };
              opencode = {
                hiddenModels = [
                  "opencode/big-pickle"
                  "anthropic/claude-fable-5"
                  "anthropic/claude-haiku-4-5-20251001"
                  "anthropic/claude-haiku-4-5"
                  "anthropic/claude-opus-4-5-20251101"
                  "anthropic/claude-opus-4-5"
                  "anthropic/claude-opus-4-6"
                  "anthropic/claude-opus-4-7"
                  "anthropic/claude-opus-4-8"
                  "anthropic/claude-opus-4-8-fast"
                  "anthropic/claude-opus-5"
                  "anthropic/claude-opus-5-fast"
                  "anthropic/claude-sonnet-4-5-20250929"
                  "anthropic/claude-sonnet-4-5"
                  "anthropic/claude-sonnet-4-6"
                  "anthropic/claude-sonnet-5"
                  "opencode/hy3-free"
                  "opencode/mimo-v2.5-free"
                  "opencode/muse-spark-1.2-contributor-free"
                  "opencode/nemotron-3-ultra-free"
                  "opencode/nemotron-3.5-lightning-free"
                ];
                modelOrder = [ ];
              };
            };
          };

          userSettings = {
            enableProviderUpdateChecks = false;
            addProjectBaseDirectory = "/run/media/${username}/Shared/Projects";
            sourceControlWritingStyle.mode = "conventional_commits";
            providerInstances = {
              codex.enabled = false;
              claudeAgent.enabled = false;
              grok.enabled = false;
              cursor = {
                enabled = true;
                config.binaryPath = "cursor-agent";
                accentColor = "#dc2626";
              };
              opencode = {
                enabled = true;
                accentColor = "#16a34a";
              };
            };
          };
        };
        codex.enable = true;
        claude-code = {
          enable = true;
          configDir = "${configHome}/claude";
        };
        cursor.enable = true;
        cursor-agent.enable = true;
      };
    };
  };
}
