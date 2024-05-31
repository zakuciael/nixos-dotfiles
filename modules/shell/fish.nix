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
    default = mkOption {
      description = "Whether to set fish as a default shell for the user";
      example = true;
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    users.users."${username}".shell = mkIf cfg.default pkgs.fish;
    environment.shells = mkIf cfg.default (with pkgs; [fish]);
    programs.fish.enable = true;

    home-manager.users.${username} = {
      programs = {
        fish = {
          enable = true;
          catppuccin.enable = true;
          functions = {
            fish_greeting = ''
              ${pkgs.krabby}/bin/krabby random --no-title
            '';
          };
          shellAliases = {
            re = "nh os switch -H ${hostname} && echo -e '\\033[32m>\\033[0m Done!'";
            nfu = "nix flake update";
            repl = "nix repl -f '<nixpkgs>'";
            vim = "nvim";
          };
        };
      };
    };
  };
}
