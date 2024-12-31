{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my;
let
  cfg = config.modules.shell.tools;
  terminfoScript = pkgs.writeShellApplication {
    name = "copy-terminfo";
    text = ''
      if [ $# -eq 0 ]; then
        echo "Usage: copy-terminfo <destination> [options]"
      else
        infocmp -x | ssh "$@" -- "tic -x - 1>&2 2>/dev/null"
      fi
    '';
  };

in
{
  options.modules.shell.tools = {
    enable = mkEnableOption "shell utility packages";
  };

  config = mkIf (cfg.enable) {
    programs.nix-ld.enable = true;

    home-manager.users.${username} = {
      home.packages = with pkgs; [
        terminfoScript # A bash script for coping the terminfo of the current terminal emulator
        duf # Disk Usage/Free Utility - a better 'df' alternative
        entr # Run arbitrary commands when files change
        exiftool # ExifTool meta information reader/writer
        just # Just a command runner
        jq # Command-line JSON processor
        tre-command # Tree command, improved.
        lazydocker # The lazier way to manage everything docker
        lazygit # simple terminal UI for git commands
        sd # Intuitive find & replace CLI (sed alternative)
        ripgrep # ripgrep recursively searches directories for a regex pattern while respecting your gitignore
      ];

      catppuccin = {
        btop.enable = true;
        fzf.enable = true;
        cava.enable = true;
      };

      programs = {
        fish = {
          shellAliases = with pkgs; {
            lzd = "${getExe lazydocker}";
            lg = "${getExe lazygit}";
            tree = "${getExe tre-command}";

            # On-demand tools
            dig = "nix run nixpkgs#dogdns"; # A command-line DNS client.
            dua = "nix run nixpkgs#dua -- i"; # View disk space usage and delete unwanted data, fast.
            procs = "nix run nixpkgs#procs"; # A modern replacement for ps written in Rust
            gping = "nix run nixpkgs#gping"; # Ping, but with a graph

            tokei = "nix run nixpkgs#tokei"; # Count your code, quickly.
            cloc = "nix run nixpkgs#tokei";
            sloc = "nix run nixpkgs#tokei";

            neofetch = "nix run nixpkgs#neofetch";
            onefetch = "nix run nixpkgs#onefetch";
            nix-prefetch = "nix run nixpkgs#nix-prefetch -- --option extra-experimental-features flakes";
          };
        };

        btop.enable = true;
        fzf.enable = true;
        cava.enable = true;
      };
    };
  };
}
