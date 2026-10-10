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

  # Cursor's agent harness injects Co-authored-by even when attribution is disabled
  # in cli-config; strip it (and the Made-with trailer) in commit-msg.
  stripCursorAttribution = pkgs.writeShellScript "git-commit-msg-strip-cursor-attribution" ''
    set -euo pipefail
    msg_file="$1"
    ${pkgs.gnused}/bin/sed -i \
      -e '/^Co-authored-by: Cursor <cursoragent@cursor\.com>$/d' \
      -e '/^Made-with: Cursor$/d' \
      "$msg_file"
  '';
in
{
  options.modules.dev.ai = {
    enable = mkEnableOption "AI tooling";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 3773 ];

    home-manager.users.${username} =
      { config, ... }:
      {
        home = {
          packages = with pkgs; [
            opencode-desktop
            skills
            postplan
            imhex-mcp-server
          ];

          # New Project always writes under ~/.t3/projects; point that at Projects.
          file.".t3/projects".source =
            config.lib.file.mkOutOfStoreSymlink "/run/media/${username}/Shared/Projects";
        };

        programs = {
          mcp = {
            enable = true;
            servers.imhex = {
              command = lib.getExe pkgs.imhex-mcp-server;
            };
          };

          git.hooks.commit-msg = stripCursorAttribution;

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
            settings = {
              attribution = {
                attributeCommitsToAgent = false;
                attributePRsToAgent = false;
              };
            };
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
              notificationMode = "notifications";
              inAppNotificationsEnabled = true;
              confirmThreadArchive = true;
              confirmThreadDelete = true;
              diffFilesCollapsed = false;
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
              continueThreadsAfterServerUpdate = true;
              defaultAutoPull = true;
              removeAgentCreditsOnMerge = true;
              branchNamingMode = "semantic";
              environmentIcon = "linux";
              addProjectBaseDirectory = "/run/media/${username}/Shared/Projects";
              worktreesDirectory = "/run/media/${username}/Shared/Worktrees";
              defaultModelSelection = {
                instanceId = "cursor";
                model = "default";
              };
              textGenerationModelSelection = {
                instanceId = "cursor";
                model = "default";
              };
              storageCleanup = {
                worktreeAfterDays = 8;
                worktreeOnMerge = true;
                worktreeOnDelete = true;
                worktreeUnchanged = true;
                browserArtifactsAfterDays = 3;
                logsAfterDays = 3;
              };
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
