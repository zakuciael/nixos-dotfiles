{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.shell.tools;
in {
  options.modules.shell.tools = {
    enable = mkEnableOption "shell utility packages";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      home.packages = with pkgs; [
        duf # Disk Usage/Free Utility - a better 'df' alternative
        entr # Run arbitrary commands when files change
        exiftool # ExifTool meta information reader/writer
        just # Just a command runner
        jq # Command-line JSON processor
        tre-command # Tree command, improved.
        lazydocker # The lazier way to manage everything docker
        sd # Intuitive find & replace CLI (sed alternative)
        ripgrep # ripgrep recursively searches directories for a regex pattern while respecting your gitignore
      ];

      programs = {
        fish = {
          shellAliases = {
            lzd = "lazydocker";
            tree = "tre";

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
            nix-prefetch = "nix run nixpkgs#nix-prefetch";
          };
        };
        btop = {
          enable = true;
          catppuccin.enable = true;
        };
        fzf = {
          enable = true;
          catppuccin.enable = true;
        };
        cava = {
          enable = true;
          catppuccin.enable = true;
        };
      };
    };
  };
}
