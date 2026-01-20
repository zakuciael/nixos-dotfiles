{
  config,
  lib,
  username,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.modules.dev.zed;

  font_family = "JetBrains Mono";
  font_fallbacks = [
    "icomoon-feather"
    "Symbols Nerd Font Mono"
  ];
  font_size = 14.0;
in
{
  config = mkIf cfg.enable {
    home-manager.users.${username}.programs.zed-editor = {
      userSettings = {
        # Font
        ui_font_size = font_size;
        ui_font_family = font_family;
        ui_font_fallbacks = font_fallbacks;
        buffer_font_size = font_size;
        buffer_font_family = font_family;
        buffer_font_fallbacks = font_fallbacks;
        buffer_line_height = "comfortable";
        terminal = {
          inherit font_size font_family font_fallbacks;
        };

        # Themes
        icon_theme = "Colored Zed Icons Theme Dark";
        theme = "Catppuccin Mocha (Blue Blur+)";

        # AI
        disable_ai = true;

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
        git_panel.sort_by_path = false;
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
        when_closing_with_no_tabs = "close_window";
        confirm_quit = false;

        # Language settings
        languages = {
          Nix = {
            language_servers = [
              "nixd"
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
        };

      };
    };
  };
}
