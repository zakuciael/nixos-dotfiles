{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.modules.shell.tmux;
in
{
  options.modules.shell.tmux = {
    enable = mkEnableOption "Tmux shell multiplexer";
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      catppuccin.tmux = {
        enable = true;
        extraConfig = ''
          set -g @catppuccin_window_default_text "#W"
          set -g @catppuccin_window_current_text " #(echo '#{pane_current_path}' | rev | cut -d'/' -f-2 | rev)"
        '';
      };

      programs.tmux = {
        enable = true;
        mouse = true;
        newSession = false;
        plugins = with pkgs.tmuxPlugins; [
          sensible
          yank
        ];
        shell = "${pkgs.fish}/bin/fish";
        prefix = "C-Space";
        baseIndex = 1;
        keyMode = "vi";
        extraConfig = ''
          # Fix vim colors
          set-option -sa terminal-overrides ",xterm*:Tc"

          # Set split pane keybinds to "<prefix> + {h/v}"
          bind h split-window -h -c "#{pane_current_path}"
          bind v split-window -v -c "#{pane_current_path}"

          # Set kill window to "<prefix> + x"
          bind x kill-window

          # Set kill pane to "<prefix> + w"
          bind w kill-pane

          # Set copy mode to "<prefix> + ctrl + v"
          bind C-v copy-mode

          # Set window rename to "<prefix> + shift + n"
          bind N command-prompt -I "#W" { rename-window "%%" }

          # Set session rename to "<prefix> + shift + m"
          bind M command-prompt -I "#S" { rename-session "%%" }

          # Better copy mode control
          bind -T copy-mode-vi v send-keys -X begin-selection
          bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
          bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel

          # Quick window switching (alows for holding ctrl key)
          bind -r C-Left previous-window
          bind -r C-Right next-window

          # Quick pane switching
          bind -r -n C-Left select-pane -L
          bind -r -n C-Right select-pane -R
          bind -r -n C-Up select-pane -U
          bind -r -n C-Down select-pane -D
        '';
      };
    };
  };
}
