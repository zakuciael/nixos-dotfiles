{
  config,
  lib,
  pkgs,
  inputs,
  username,
  hostname,
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
      ];
      trusted-public-keys = [
        "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
        "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      ];
      trusted-users = [ "@wheel" ];
    };
    extraOptions = ''
      experimental-features = nix-command flakes pipe-operators
      !include ${config.sops.templates."nix/access_tokens.conf".path}
    '';
    package = pkgs.nixVersions.latest;
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
    ];
    shells = with pkgs; [ bash ];
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
      base = "nix/access-tokens";
      secretNames = utils.recursiveReadSecretNames { inherit config base; };
      secrets = utils.readSecrets { inherit config base; };
    in
    {
      templates = {
        "nix/access_tokens.conf" = {
          mode = "0440";
          group = config.users.groups.keys.name;
          content = ''
            access-tokens = ${
              lib.concatStringsSep " " (
                builtins.map (
                  entry:
                  "${entry}=${
                    utils.mkSecretPlaceholder config [
                      base
                      entry
                    ]
                  }"
                ) (builtins.attrNames secrets)
              )
            }
          '';
        };
      };
      secrets = {
        "users/${username}/password".neededForUsers = true;
      } // lib.listToAttrs (builtins.map (v: lib.nameValuePair v { }) secretNames);
    };

  # User settings
  users.users.${username} = {
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
      inputs.ghostty-hm.homeManagerModule
    ];
    useUserPackages = true;
    useGlobalPkgs = true;
    users.${username}.home = {
      inherit username;
      stateVersion = "24.05";
      homeDirectory = "/home/${username}";
      packages = scripts.mkShellExports config;
    };
  };

  # Internal modules
  modules = {
    dev.git.enable = true;
    services.xdg.enable = true;
    hardware.grub.enable = true;
    shell = {
      neovim = {
        enable = true;
        lspPackages = with pkgs; [
          # Lua
          lua-language-server
          stylua

          # Nix
          deadnix
          statix
          nixd
          inputs.nixfmt.default
        ];
        treesitterGrammars = [
          "lua"
          "luap"
          "nix"
        ];
      };
      fish = {
        enable = true;
        default = true;
      };
    };
  };

  # System
  system = {
    stateVersion = "24.05";
    autoUpgrade = {
      enable = true;
      flake = "github:zakuciael/nixos-dotfiles#${hostname}";
      dates = "daily";
    };
  };
}
