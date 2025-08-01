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

  config = mkIf cfg.enable {
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
        dogdns # A command-line DNS client.
        dua # View disk space usage and delete unwanted data, fast.
        procs # A modern replacement for ps written in Rust
        gping # Ping, but with a graph
        tokei # Count your code, quickly.
        nix-prefetch-github # Prefetch sources from github for nix build tool
        nix-prefetch-git # Script used to obtain source hashes for fetchgit
        unrar # Utility for RAR archives
        unzip # Extraction utility for archives compressed in .zip format
        p7zip # Command line version of 7-Zip for Linux
        motrix # A full-featured download manager
        marktext # Simple and elegant markdown editor
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
            dig = "${getExe dogdns}";
            dua = "${getExe dua} i";
            procs = "${getExe procs}";
            gping = "${getExe gping}";

            tokei = "${getExe tokei}";
            cloc = "${getExe tokei}";
            sloc = "${getExe tokei}";

            nix-prefetch-github = "${nix-prefetch-github}/bin/nix-prefetch-github --nix";
            nix-prefetch-git = "${nix-prefetch-git}/bin/nix-prefetch-git";
          };
        };

        btop.enable = true;
        fzf.enable = true;
        cava.enable = true;
      };
    };
  };
}
