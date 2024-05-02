{
  config,
  lib,
  pkgs,
  hostname,
  username,
  ...
}:
with lib; let
  cfg = config.modules.shell.fish;
in {
  options.modules.shell.fish = {
    enable = mkEnableOption "fish shell";
    direnv.enable = mkEnableOption "direnv integration";
    default = mkOption {
      description = "Whether to set fish as a default shell for the user";
      example = true;
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    users.users."${username}".shell = mkIf cfg.default pkgs.fish;
    programs.fish.enable = cfg.enable;
    environment.shells = mkIf cfg.default (with pkgs; [fish]);

    home-manager.users.${username} = {
      programs = {
        direnv = {
          enable = cfg.direnv.enable;
          nix-direnv.enable = cfg.direnv.enable;
          config = {
            global = {
              load_dotenv = true;
              disable_stdin = true;
            };
            whitelist.prefix = ["/home/${username}/dev"];
          };
        };

        starship.enable = true;

        fish = {
          enable = true;
          shellAliases = {
            re = "nh os switch -H ${hostname} && echo -e '\\033[32m>\\033[0m Done!'";
            nfu = "nix flake update";
            repl = "nix repl -f '<nixpkgs>'";
            vim = "nvim";

            # Programs
            neofetch = "nix run nixpkgs#neofetch";
            btop = "nix run nixpkgs#btop";
            onefetch = "nix run nixpkgs#onefetch";
          };
        };
      };
    };
  };
}
