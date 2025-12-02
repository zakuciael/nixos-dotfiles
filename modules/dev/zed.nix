{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib.types) bool;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  cfg = config.modules.dev.zed;
in
{
  options.modules.dev.zed = {
    enable = mkEnableOption "Zed Editor";
    remote-server = mkOption {
      type = bool;
      description = "This allows remotely connecting to this system from a distant Zed client.";
      default = false;
    };
    mutable = mkOption {
      type = bool;
      description = "Whether the configuration files can be updated by Zed.";
      default = false;
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${username}.programs.zed-editor = {
      enable = true;
      installRemoteServer = cfg.remote-server;

      mutableUserDebug = cfg.mutable;
      mutableUserKeymaps = cfg.mutable;
      mutableUserSettings = cfg.mutable;
      mutableUserTasks = cfg.mutable;

      extensions = [
        "nix"
        "wakatime"
        "discord-presence"
        "catppuccin"
        "catppuccin-blur-plus"
        "colored-zed-icons-theme"
        "material-icon-theme"
      ];

      extraPackages = with pkgs; [
        nixd
        nixfmt-rfc-style
      ];

      userSettings = {
        # AI settings
        disable_ai = true;

        # UI settings
        toolbar = {
          breadcrumbs = false;
        };
        use_system_prompts = false;
        use_system_path_prompts = false;
        when_closing_with_no_tabs = "close_window";
        redact_private_values = true;

        # Indentation settings
        tab_size = 2;

        # Theme settings
        icon_theme = "Colored Zed Icons Theme Dark";
        theme = "Catppuccin Mocha (Blue Blur+)";

        # Font settings
        buffer_line_height = "comfortable";
        buffer_font_size = 14.0;
        buffer_font_family = "JetBrains Mono";

        # Keymaps
        base_keymap = "JetBrains";

        # TODO: Categorazie those settings
        auto_signature_help = true;
        autosave = "on_focus_change";
        load_direnv = "direct";
        languages = {
          Nix = {
            language_servers = [
              "nixd"
              "!nil"
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
      };
    };
  };
}
