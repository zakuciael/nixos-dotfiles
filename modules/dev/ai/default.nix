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

  # Store path to the npm package root (dist + node_modules) so OpenCode can
  # resolve package exports and runtime deps without fetching from npm at startup.
  cursorOpencodeProvider = "${pkgs.cursor-opencode-provider}/lib/node_modules/cursor-opencode-provider";
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
        imhex-mcp-server
      ];

      programs = {
        mcp = {
          enable = true;
          servers.imhex = {
            command = lib.getExe pkgs.imhex-mcp-server;
          };
        };

        opencode = {
          enable = true;
          enableMcpIntegration = true;
          settings = {
            # Package-dir load uses exports["./server"], which dual-exports the
            # classic 1.x plugin (auth + tools). Do not add V2-only "plugins".
            plugin = [ "file://${cursorOpencodeProvider}" ];
            provider.cursor = {
              npm = "file://${cursorOpencodeProvider}";
              name = "Cursor";
              models = { };
            };
          };
        };
        claude-code = {
          enable = true;
          enableMcpIntegration = true;
          configDir = "${configHome}/claude";
        };
        codex = {
          enable = true;
          enableMcpIntegration = true;
        };
        cursor = {
          enable = true;
          profiles.default.enableMcpIntegration = true;
        };
        cursor-agent = {
          enable = true;
          enableMcpIntegration = true;
        };
        t3code = {
          enable = true;
          package = pkgs.t3code-nightly.override {
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

            favorites =
              let
                sharedModels = [
                  "cursor/gpt-5.6-sol"
                  "cursor/gpt-5.6-luna"
                  "cursor/kimi-k3"
                  "cursor/default"
                  "cursor/composer-2.5"
                  "cursor/claude-fable-5"
                  "cursor/claude-sonnet-5"
                  "cursor/grok-4.6"
                  "cursor/claude-opus-5"
                ];

                mkProviderSharedModels =
                  provider: stripPrefix:
                  sharedModels
                  |> map (model: {
                    inherit provider;
                    model = if stripPrefix then lib.removePrefix "${provider}/" model else model;
                  });
              in
              (mkProviderSharedModels "opencode" false)
              ++ (mkProviderSharedModels "cursor" true)
              ++ [
                {
                  provider = "opencode";
                  model = "opencode/deepseek-v4-flash-free";
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
      };
    };
  };
}
