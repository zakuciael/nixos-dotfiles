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
    mkOption
    getExe
    getExe'
    types
    ;
  inherit (lib.hm) dag;

  cfg = config.modules.dev.ai;
  configHome = config.home-manager.users.${username}.xdg.configHome;

  # Used when `projectsDirectory` is unavailable so ~/.t3/projects stays writable.
  projectsFallbackDir = "/home/${username}/Projects";

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

  linkT3Projects = pkgs.writeShellScript "link-t3-projects" ''
    set -euo pipefail
    projects=${lib.escapeShellArg cfg.projectsDirectory}
    fallback=${lib.escapeShellArg projectsFallbackDir}
    target="$HOME/.t3/projects"

    mkdir -p "$HOME/.t3" "$fallback"
    if [ -d "$projects" ]; then
      ln -sfn "$projects" "$target"
    else
      ln -sfn "$fallback" "$target"
    fi
  '';
in
{
  options.modules.dev.ai = {
    enable = mkEnableOption "AI tooling";

    projectsDirectory = mkOption {
      type = types.str;
      example = "/home/${username}/Projects";
      description = ''
        Absolute path used as t3code's project base (`addProjectBaseDirectory`)
        and as the preferred `~/.t3/projects` target when that directory exists.
      '';
    };

    worktreesDirectory = mkOption {
      type = types.str;
      example = "/home/${username}/Worktrees";
      description = ''
        Absolute path used as t3code's worktrees directory (`worktreesDirectory`).
      '';
    };
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
            claude-real-video
            imhex-mcp-server
          ];

          # Seed the local fallback directory for `linkT3Projects`.
          file."Projects/.keep".text = "";
        };

        # Point ~/.t3/projects at `projectsDirectory` when present, otherwise
        # at the local fallback so t3code can still write projects.
        home.activation.linkT3Projects = dag.entryAfter [ "writeBoundary" ] ''
          run ${linkT3Projects}
        '';

        systemd.user = {
          services.t3-projects-link = {
            Unit.Description = "Link ~/.t3/projects to modules.dev.ai.projectsDirectory or local fallback";
            Service = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${linkT3Projects}";
            };
            Install.WantedBy = [ "default.target" ];
          };

          paths.t3-projects-link = {
            Unit.Description = "Re-link ~/.t3/projects when projectsDirectory appears or media mounts change";
            Path = {
              PathExists = cfg.projectsDirectory;
              PathChanged = "/run/media/${username}";
            };
            Install.WantedBy = [ "default.target" ];
          };
        };

        # Global shortcut for `t3code` capture window
        wayland.windowManager.hyprland.settings.bind =
          let
            inherit (lib.my.utils.hypr)
              dsp
              mkBind
              ;
          in
          [
            (mkBind "CTRL + SHIFT + 2" (dsp.global "com.t3tools.T3Code:capture-window"))
          ];

        # Declarative `t3code://` handler so OAuth/Connect callbacks survive
        # home-manager mimeapps.list regeneration (runtime xdg-mime default does not).
        xdg.mimeApps = {
          defaultApplications = {
            "x-scheme-handler/t3code" = [ "t3code.desktop" ];
          };
          associations.added = {
            "x-scheme-handler/t3code" = [ "t3code.desktop" ];
          };
        };

        programs = {
          mcp = {
            enable = true;
            servers = {
              imhex = {
                command = getExe pkgs.imhex-mcp-server;
              };
              crv = {
                command = getExe' pkgs.claude-real-video "crv-mcp";
              };
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
              requireConnectDeviceApproval = true;
              defaultAutoPull = true;
              removeAgentCreditsOnMerge = true;
              branchNamingMode = "semantic";
              environmentIcon = "linux";
              linkedEnvironmentsEnabled = true;
              projectSettingsFolded = true;
              idleCompaction = "onReturn";
              pullRequestMergeMethod = "squash";
              addProjectBaseDirectory = cfg.projectsDirectory;
              worktreesDirectory = cfg.worktreesDirectory;
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
