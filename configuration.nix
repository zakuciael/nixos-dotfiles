{
  config,
  lib,
  pkgs,
  inputs,
  username,
  scripts,
  ...
}: {
  # NixOS configuration
  nix = {
    settings = {
      max-jobs = 6;
      cores = 6;
      auto-optimise-store = true;
      substituters = [
        "https://cache.thalheim.io"
      ];
      trusted-public-keys = [
        "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
      ];
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      !include ${config.sops.secrets."nix/access-tokens".path}
    '';
    package = pkgs.nixFlakes;
  };

  nixpkgs.config = {
    allowBroken = false;
    allowUnfree = true;
  };

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
  services.xserver.layout = "pl";

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-extra
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji-blob-bin
    nerdfonts
  ];

  # Global packages
  environment = {
    systemPackages = with pkgs; [neovim git bash];
    variables = {
      EDITOR = "nvim";
    };
    shells = with pkgs; [bash];
  };

  # Linux Kernel settings
  boot = {
    supportedFilesystems = ["ntfs"];

    initrd.availableKernelModules = ["ehci_pci" "ahci" "nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod"];
    loader.efi.canTouchEfiVariables = true;

    tmp.cleanOnBoot = true;

    plymouth = {
      enable = true;
      themePackages = with pkgs; [nixos-blur-plymouth];
      theme = "nixos-blur";
    };
  };

  # SOPS
  sops.secrets = {
    "users/${username}/password".neededForUsers = true;
    "nix/access-tokens" = {
      mode = "0440";
      group = config.users.groups.keys.name;
    };
  };

  # User settings
  users.users.${username} = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets."users/${username}/password".path;
    description = "Krzysztof Saczuk";
    extraGroups = ["wheel" config.users.groups.keys.name];
  };

  # Home-manager
  home-manager = {
    extraSpecialArgs = {inherit pkgs lib;};
    sharedModules = [
      inputs.nix-colors.homeManagerModule
      inputs.sops-nix.homeManagerModule
      inputs.catppuccin.homeManagerModule
    ];
    useUserPackages = true;
    useGlobalPkgs = true;
    users.${username}.home = {
      inherit username;
      stateVersion = "23.11";
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
      tmux.enable = true;
      direnv.enable = true;
      starship.enable = true;
      fish = {
        enable = true;
        direnv.enable = true;
        default = true;
      };
    };
  };

  # System
  system.stateVersion = "23.11";
}
