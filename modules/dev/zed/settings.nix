{
  config,
  lib,
  username,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.modules.dev.zed;

  font_family = "JetBrainsMono Nerd Font Propo";
  font_size = 14.0;
in
{
  config = mkIf cfg.enable {
    home-manager.users.${username}.programs.zed-editor = {
      userSettings = {
        # Font
        ui_font_size = font_size;
        ui_font_family = font_family;
        ui_font_fallbacks = [ "Noto Emoji" ];
        buffer_font_size = font_size;
        buffer_font_family = font_family;
        buffer_font_fallbacks = [ "Noto Emoji" ];
        line_height = "standard";
        terminal = {
          font_family = "JetBrainsMono Nerd Font Mono";
          font_fallbacks = [ "Noto Emoji" ];
          inherit font_size;
        };

        # Themes
        icon_theme = "Colored Zed Icons Theme Dark";
        theme = "Catppuccin Mocha (Blue Blur+)";

        # AI
        disable_ai = false;
        show_edit_predictions = false;
        agent_servers.claude-acp.type = "registry";

        agent = {
          show_merge_conflict_indicator = true;
          show_turn_stats = true;
          message_editor_min_lines = 4;
          use_modifier_to_send = false;
          cancel_generation_on_terminal_stop = true;
          thinking_display = "auto";
          expand_terminal_card = true;
          enable_feedback = true;
          single_file_review = false;
          expand_edit_card = true;
          play_sound_when_agent_done = "when_hidden";
          notify_when_agent_waiting = "primary_screen";
          new_thread_location = "new_worktree";
          default_model = {
            provider = "anthropic";
            model = "claude-sonnet-4-6-latest";
            enable_thinking = true;
            effort = "high";
          };
          dock = "right";
          sidebar_side = "right";
          favorite_models = [ ];
          model_parameters = [ ];
        };

        # Keymaps
        base_keymap = "None";

        # Editor settings
        tab_size = 2;
        auto_indent_on_paste = true;
        autosave = "on_focus_change";
        load_direnv = "shell_hook";
        use_autoclose = true;
        format_on_save = "on";
        hard_tabs = false;
        jsx_tag_auto_close.enabled = true;
        file_scan_inclusions = [
          ".env*"
          "docker-compose.*.yml"
        ];
        file_scan_exclusions = [
          "**/.git"
          "**/.svn"
          "**/.hg"
          "**/.jj"
          "**/CVS"
          "**/.DS_Store"
          "**/Thumbs.db"
          "**/.classpath"
          "**/.settings"
          "**/.direnv"
        ];

        # Autocompletion
        auto_signature_help = true;

        # UI
        toolbar.breadcrumbs = true;
        inlay_hints.enabled = true;
        colorize_brackets = true;
        use_system_prompts = false;
        use_system_path_prompts = false;
        redact_private_values = true;
        private_files = [
          "**/.env*"
          "**/*.pem"
          "**/*.key"
          "**/*.cert"
          "**/*.crt"
          "**/secrets.yml"
        ];
        terminal.dock = "bottom";
        debugger.dock = "bottom";
        collaboration_panel.dock = "bottom";
        outline_panel.dock = "left";
        project_panel.dock = "left";
        git_panel = {
          dock = "left";
          tree_view = true;
          sort_by_path = false;
        };

        when_closing_with_no_tabs = "close_window";
        confirm_quit = false;

        # Language settings
        languages = {
          Nix = {
            language_servers = [
              "nixd"
              "statix" # Currently only supported on my fork
              "deadnix" # Currently only supported on my fork
              "!nil"
              "!codebook"
              "..."
            ];
            formatter = {
              external = {
                command = "nixfmt";
                arguments = [
                  "--quiet"
                  "--"
                ];
              };
            };
          };
        };

        # LSP settings
        lsp = {
          rust-analyzer = {
            enable_lsp_tasks = true;
            initialization_options = {
              cargo = {
                allTargets = false;
              };
              check = {
                workspace = false;
                command = "clippy";
              };
            };
          };
          discord_presence = {
            initialization_options = {
              state = "Working on {folder_and_file}";
              details = "In {workspace}";
              git_integration = true;
            };
          };
        };

      };
    };
  };
}
