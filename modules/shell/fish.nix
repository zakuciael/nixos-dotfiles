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
    environment.shells = mkIf cfg.default (with pkgs; [fish]);
    programs.fish.enable = true;

    home-manager.users.${username} = {
      home.sessionVariables = {
        DIRENV_LOG_FORMAT = "";
      };

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

        starship = {
          enable = true;
          catppuccin.enable = true;
          settings = {
            add_newline = true;

            directory.read_only = " 󰌾";
            docker_context.symbol = " ";
            nix_shell.symbol = " ";
            git_branch.symbol = " ";
            hostname.ssh_symbol = "󰖟 ";
            kubernetes = {
              symbol = "󱃾 ";
              detect_env_vars = ["KUBECONFIG"];
            };

            package.symbol = "󰏗 ";
            c.symbol = " ";
            cmake.symbol = " ";
            golang.symbol = " ";
            java.symbol = " ";
            kotlin.symbol = " ";
            lua.symbol = " ";
            nodejs.symbol = "󰎙 ";
            python.symbol = " ";
            php.symbol = " ";
            ruby.symbol = " ";
            rust.symbol = " ";
            dotnet.symbol = "󰪮 ";
            gradle.symbol = " ";

            os.symbols = {
              Alpaquita = " ";
              Alpine = " ";
              Amazon = " ";
              Android = " ";
              Arch = " ";
              Artix = " ";
              CentOS = " ";
              Debian = " ";
              DragonFly = " ";
              Emscripten = " ";
              EndeavourOS = " ";
              Fedora = " ";
              FreeBSD = " ";
              Garuda = "󰛓 ";
              Gentoo = " ";
              HardenedBSD = "󰞌 ";
              Illumos = "󰈸 ";
              Linux = " ";
              Mabox = " ";
              Macos = " ";
              Manjaro = " ";
              Mariner = " ";
              MidnightBSD = " ";
              Mint = " ";
              NetBSD = " ";
              NixOS = " ";
              OpenBSD = "󰈺 ";
              openSUSE = " ";
              OracleLinux = "󰌷 ";
              Pop = " ";
              Raspbian = " ";
              Redhat = " ";
              RedHatEnterprise = " ";
              Redox = "󰀘 ";
              Solus = "󰠳 ";
              SUSE = " ";
              Ubuntu = " ";
              Unknown = " ";
              Windows = "󰍲 ";
            };
          };
        };

        fish = {
          enable = true;
          catppuccin.enable = true;
          shellAliases = {
            re = "nh os switch -H ${hostname} && echo -e '\\033[32m>\\033[0m Done!";
            nfu = "nix flake update";
            repl = "nix repl -f '<nixpkgs>";
            vim = "nvim";

            # Programs
            neofetch = "nix run nixpkgs#neofetch";
            onefetch = "nix run nixpkgs#onefetch";
            nix-prefetch = "nix run nixpkgs#nix-prefetch";
          };
        };
      };
    };
  };
}
