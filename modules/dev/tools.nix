{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf getExe;

  cfg = config.modules.dev.tools;

  gtCli = lib.getExe pkgs.graphite-cli;
in
{
  options.modules.dev.tools = {
    enable = mkEnableOption "development tools";
  };

  config = mkIf cfg.enable {
    home-manager.users.${username} = {
      home.shellAliases = {
        "gti" = "${gtCli} init"; # gt init
        "gtsy" = "${gtCli} sync"; # gt sync
        "gts" = "${gtCli} submit --stack --draft"; # gt submit
        "gtsu" = "${gtCli} submit --stack --update-only"; # gt submit (but update-only)
        "gtcr" = "${gtCli} create"; # gt create
        "gtm" = "${gtCli} modify"; # gt modify
        "gtma" = "${gtCli} modify --all"; # gt modify (stage all)
        "gtr" = "${gtCli} restack"; # gt restack
        "gtc" = "${gtCli} checkout --all"; # gt checkout
        "gtl" = "${gtCli} log --reverse --all"; # gt log
        "gtu" = "${gtCli} up"; # gt up
        "gtd" = "${gtCli} down"; # gt down
      };

      home.packages = with pkgs; [
        # Git
        graphite-cli
        gh

        # Reverse Engineering
        ghidra-bin
        imhex

        # MongoDB
        mongosh
        mongodb-tools
        mongodb-compass

        # HTTP Clients
        httpie
        httpie-desktop
        bruno

        # Benchmarking
        hyperfine

        # FTP
        filezilla

        # Tracking
        wakatime-cli

        # Toolbox
        devtoolbox

        # Nix
        nixd
        nixfmt
        statix
        deadnix
        devenv
      ];
    };
  };
}
