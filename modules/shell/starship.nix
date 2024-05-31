{
  config,
  lib,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.shell.starship;
in {
  options.modules.shell.starship = {
    enable = mkEnableOption "starship shell prompt";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      programs.starship = {
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
            disabled = false;
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
    };
  };
}
