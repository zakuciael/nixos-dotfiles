{
  config,
  pkgs,
  lib,
  hostname,
  username,
  ...
}:
with lib; let
  cfg = config.modules.shell.fish;
in {
  options.modules.shell.fish = {
    enable = mkEnableOption "Enable fish shell";
    enableDirenv = mkEnableOption "Enable direnv";
    default = mkEnableOption "Enable fish shell as default shell for main user";
  };

  config = mkIf cfg.enable {
    users.users."${username}".shell = mkIf cfg.default pkgs.fish;
    programs.fish.enable = cfg.enable;
    environment.shells = mkIf cfg.default (with pkgs; [fish]);

    home-manager.users.${username} = {
      programs = {
        direnv = {
          enable = cfg.enableDirenv;
          nix-direnv.enable = cfg.enableDirenv;
          config = {
            global = {
              load_dotenv = true;
              disable_stdin = true;
            };
            whitelist.prefix = ["/home/${username}/dev" "/home/${username}/nixos"];
          };
        };

        starship.enable = true;

        fish = {
          enable = true;
          shellAliases = {
            re = "sudo nixos-rebuild switch --flake ${config.environment.variables.NIXOS_CONFIG}#${hostname}";
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
