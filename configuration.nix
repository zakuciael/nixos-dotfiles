{
  config,
  lib,
  pkgs,
  inputs,
  username,
  scripts,
  ...
}:
with lib;
with lib.my;
{
  # NixOS configuration
  nix = {
    settings = {
      auto-optimise-store = true;
      substituters = [
        "https://cache.thalheim.io"
        "https://ezkea.cachix.org"
        "https://ghostty.cachix.org"
        "https://attic.zakku.eu/rofi-jetbrains"
        "https://attic.zakku.eu/nostale-dev-env"
        "https://attic.zakku.eu/system"
        "https://install.determinate.systems"
      ];
      trusted-public-keys = [
        "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
        "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
        "rofi-jetbrains:grO4wlkucWElNgkCaFREHgbsrn9jeoHZqyqEMRtcgxI="
        "nostale-dev-env:ppvIiWL1k+xB8hIYFbWh0QceKpc/H8JX5MmJQFveMzE="
        "system:3zQYNe2TDLsBhgQobQLmcnJrc0k5XdkXqvyVz5xyS+o="
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      ];
      trusted-users = [ "@wheel" ];
    };
    extraOptions = ''
      experimental-features = nix-command flakes pipe-operators
      netrc-file = ${config.sops.templates."nix/netrc".path}
      !include ${config.sops.templates."nix/access_tokens.conf".path}
    '';
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  nixpkgs.pkgs = pkgs;

  # System time
  time.timeZone = "Europe/Warsaw";
  time.hardwareClockInLocalTime = true;

  # System locale
  i18n = {
    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "pl_PL.UTF-8";
      LC_IDENTIFICATION = "pl_PL.UTF-8";
      LC_MEASUREMENT = "pl_PL.UTF-8";
      LC_MONETARY = "pl_PL.UTF-8";
      LC_NAME = "pl_PL.UTF-8";
      LC_NUMERIC = "pl_PL.UTF-8";
      LC_PAPER = "pl_PL.UTF-8";
      LC_TELEPHONE = "pl_PL.UTF-8";
      LC_TIME = "pl_PL.UTF-8";
    };
  };

  console.keyMap = "pl";
  services.xserver.xkb.layout = "pl";

  # Fonts
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-extra
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji-blob-bin
      jetbrains-mono
      icomoon-feather
      nerd-fonts.symbols-only
    ];
    fontconfig = {
      enable = true;
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <alias>
            <family>JetBrains Mono</family>
            <prefer>
              <family>JetBrains Mono</family>
              <family>icomoon-feather</family>
              <family>Symbols Nerd Font Mono</family>
            </prefer>
          </alias>
        </fontconfig>
      '';
    };
  };

  # Global packages
  environment = {
    systemPackages = with pkgs; [
      git
      bash
      killall
    ];
    shells = with pkgs; [ bash ];
    variables = {
      NH_FLAKE = "/run/media/${username}/Shared/Projects/nixos-dotfiles";
    };
  };

  # Linux Kernel settings
  boot = {
    supportedFilesystems = [ "ntfs" ];

    initrd.availableKernelModules = [
      "ehci_pci"
      "ahci"
      "nvme"
      "xhci_pci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    loader.efi.canTouchEfiVariables = true;

    tmp.cleanOnBoot = true;

    plymouth = {
      enable = true;
      themePackages = with pkgs; [ nixos-blur-plymouth ];
      theme = "nixos-blur";
    };
  };

  # SOPS
  sops =
    let
      secretNames = utils.recursiveReadSecretNames {
        inherit config;
        base = "nix";
      };
    in
    {
      templates = {
        "nix/access_tokens.conf" =
          let
            base = "nix/access-tokens";
            secrets = utils.readSecrets {
              inherit config base;
            };
          in
          {
            mode = "0440";
            group = config.users.groups.keys.name;
            content = ''
              access-tokens = ${
                builtins.attrNames secrets
                |> builtins.map (
                  entry:
                  "${entry}=${
                    utils.mkSecretPlaceholder config [
                      base
                      entry
                    ]
                  }"
                )
                |> lib.concatStringsSep " "
              }
            '';
          };
        "nix/netrc" =
          let
            base = "nix/cache_auth";
            secrets = utils.readSecrets {
              inherit config base;
            };
          in
          {
            mode = "0440";
            group = config.users.groups.keys.name;
            path = "/etc/nix/netrc";
            content =
              builtins.attrNames secrets
              |> builtins.map (
                key:
                "machine ${key} password ${
                  utils.mkSecretPlaceholder config [
                    base
                    key
                  ]
                }"
              )
              |> lib.concatStringsSep "\n";
          };
      };
      secrets = {
        "users/${username}/password".neededForUsers = true;
      }
      // lib.listToAttrs (builtins.map (v: lib.nameValuePair v { }) secretNames);
    };

  # User settings
  users.users.${username} = {
    uid = 1000;
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets."users/${username}/password".path;
    description = "Krzysztof Saczuk";
    extraGroups = [
      "wheel"
      config.users.groups.keys.name
    ];
  };

  # Home-manager
  home-manager = {
    extraSpecialArgs = { inherit pkgs lib; };
    sharedModules = [
      inputs.nix-colors.homeManagerModule
      inputs.sops-nix.homeManagerModule
      inputs.catppuccin.homeManagerModule
      inputs.vscode-server.homeManagerModule
    ];
    useUserPackages = true;
    useGlobalPkgs = true;
    users.${username} = {
      home = {
        inherit username;
        stateVersion = "25.11";
        homeDirectory = "/home/${username}";
        packages = scripts.mkShellExports config;
      };

      # Custom bookmarks
      gtk.gtk3.bookmarks = [
        (utils.mkGtkBookmark {
          name = "Projects";
          path = "/run/media/${username}/Shared/Projects";
        })
        (utils.mkGtkBookmark {
          name = "NixOS Config";
          path = "/run/media/${username}/Shared/Projects/nixos-dotfiles";
        })
      ];

    };
  };

  # Internal modules
  modules = {
    dev.git.enable = true;
    services = {
      xdg.enable = true;
      thumbnail.enable = true;
    };
    hardware.grub.enable = true;
    shell = {
      neovim = {
        enable = true;
        lspPackages = with pkgs; [
          # Common
          prettierd

          # Lua
          lua-language-server
          stylua

          # JSON
          nodePackages.vscode-json-languageserver

          # YAML
          yaml-language-server
          docker-compose-language-service # docker-compose.yml
          actionlint # .github/workflows/*.yml

          # Dockerfile
          dockerfile-language-server-nodejs
          hadolint

          # Nix
          inputs.deadnix.default
          inputs.statix.default
          nixd
          nixfmt-rfc-style

          # SOPS
          sops
          age
        ];
        treesitterGrammars = [
          "lua"
          "luap"
          "nix"
          "yaml"
          "bash"
          "typescript"
          "javascript"
          "jq"
          "css"
          "json"
          "jsonc"
          "json5"
          "just"
          "dockerfile"
          "editorconfig"
          "gitignore"
          "go"
          "graphql"
          "hcl"
          "helm"
          "hyprlang"
          "html"
          "ini"
          "java"
          "jsdoc"
          "markdown"
          "markdown_inline"
          "make"
          "nginx"
          "proto"
          "python"
          "regex"
          "rust"
          "scss"
          "sql"
          "terraform"
          "tmux"
          "tsx"
          "udev"
          "vim"
        ];
      };
      fish = {
        enable = true;
        default = true;
      };
      neofetch.enable = true;
    };
  };

  # System
  system.stateVersion = "25.11";
}
