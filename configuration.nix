{
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  # NixOS configuration
  nix = {
    settings = {
      max-jobs = 6;
      cores = 6;
      experimental-features = ["nix-command" "flakes"];
    };
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
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
  ];

  # Global packages
  environment = {
    systemPackages = with pkgs; [neovim git bash];
    variables = {
      EDITOR = "nvim";
      NIXOS_CONFIG = "/home/${username}/nixos";
    };
    shells = with pkgs; [bash];
  };

  # Linux Kernel settings
  boot = {
    supportedFilesystems = ["ntfs"];

    initrd.availableKernelModules = ["ehci_pci" "ahci" "nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod"];
    loader.efi.canTouchEfiVariables = true;
  };

  # User settings
  users.users.${username} = {
    isNormalUser = true;
    description = "Krzysztof Saczuk";
    extraGroups = ["wheel"];
  };

  # Home-manager
  home-manager = {
    extraSpecialArgs = {inherit pkgs lib;};
    useUserPackages = true;
    useGlobalPkgs = true;
    users.${username}.home = {
      inherit username;
      stateVersion = "23.11";
      homeDirectory = "/home/${username}";
      # TODO: Dynamic custom scripts
      packages = with pkgs; [
        (import ./scripts/fix_elgato.nix {inherit pkgs;})
      ];
    };
  };

  # Internal modules
  modules = {
    dev.git.enable = true;
    shell = {
      tmux.enable = true;
      fish = {
        enable = true;
        enableDirenv = true;
        default = true;
      };
    };
  };

  # System
  system.stateVersion = "23.11";
}
