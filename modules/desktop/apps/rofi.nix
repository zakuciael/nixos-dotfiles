{
  config,
  lib,
  pkgs,
  username,
  desktop,
  ...
}:
with lib;
let
  inherit (lib.my.mapper) toRasi;
in
{
  home-manager.users.${username} = {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
    };

    xdg.configFile."rofi/config.rasi".text = toRasi { } {
      configuration = {
        # Basic config
        font = "JetBrains Mono 10";
        terminal = "${getExe config.modules.desktop.wm.${desktop}.terminalPackage}";
        show-icons = true;
        icon-theme = "WhiteSur-dark";

        # Match settings
        tokenize = true;
        normalize-match = true;
        case-sensitive = false;
        matching = "normal";

        # History & Sorting settings
        disable-history = false;
        sorting-method = "normal";
        max-history-size = 25;

        # Display settings
        cycle = true;
        scroll-method = 0;
        steal-focus = false;

        # Misc settings
        sort = false;
        threads = 0;
        click-to-exit = true;

        # Other
        timeout = {
          action = "kb-cancel";
          delay = 0;
        };

        # Keybindings
        kb-mode-next = "Shift+Right,Control+Tab";
        kb-mode-previous = "Shift+Left,Control+ISO_Left_Tab";
        kb-mode-complete = "Control+l";
        kb-remove-word-back = "Control+Alt+h,Control+BackSpace";
        kb-remove-word-forward = "Control+Alt+d";
        kb-clear-line = "Control+w";
        kb-move-front = "Control+a";
        kb-move-end = "Control+e";
        kb-move-word-back = "Alt+b,Control+Left";
        kb-move-word-forward = "Alt+f,Control+Right";
      };
    };
  };
}
