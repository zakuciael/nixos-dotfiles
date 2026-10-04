{
  config,
  lib,
  pkgs,
  hostname,
  username,
  ...
}:
with lib;
let
  cfg = config.modules.shell.fish;
in
{
  options.modules.shell.fish = {
    enable = mkEnableOption "fish shell";
    default = mkOption {
      description = "Whether to set fish as a default shell for the user";
      example = true;
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    users.users."${username}".shell = mkIf cfg.default pkgs.fish;
    environment.shells = mkIf cfg.default (with pkgs; [ fish ]);
    programs.fish.enable = true;

    home-manager.users.${username} = {
      catppuccin.fish.enable = true;

      home.shellAliases = {
        re = "nh os switch -H ${hostname} && echo -e '\\033[32m>\\033[0m Done!'";
        nfu = "nix flake update";
        repl = "nix repl -f '<nixpkgs>'";
      };

      programs = {
        fish = {
          enable = true;
          plugins = [
            # Keep fish_complete_path in sync when direnv changes XDG_DATA_DIRS
            # (nix/direnv packages otherwise get no tab completions).
            # https://github.com/direnv/direnv/issues/1539
            {
              name = "completion-sync";
              src = pkgs.fetchFromGitHub {
                owner = "iynaix";
                repo = "fish-completion-sync";
                rev = "4f058ad2986727a5f510e757bc82cbbfca4596f0";
                hash = "sha256-kHpdCQdYcpvi9EFM/uZXv93mZqlk1zCi2DRhWaDyK5g=";
              };
            }
          ];
          functions = {
            fish_greeting = ''
              ${pkgs.krabby}/bin/krabby random --no-title
            '';
          };
        };
      };
    };
  };
}
