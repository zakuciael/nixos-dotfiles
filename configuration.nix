{
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
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
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
    };
    shells = with pkgs; [bash];
  };

  # Linux Kernel settings
  boot = {
    supportedFilesystems = ["ntfs"];

    initrd.availableKernelModules = ["ehci_pci" "ahci" "nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod"];
    loader.efi.canTouchEfiVariables = true;

    tmp = {
      cleanOnBoot = true;
      useTmpfs = true;
      tmpfsSize = "25%";
    };

    plymouth = {
      enable = true;
      themePackages = with pkgs; [nixos-blur-plymouth];
      theme = "nixos-blur";
    };
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
    sharedModules = [
      inputs.nix-colors.homeManagerModules.default
      inputs.hyprland.homeManagerModules.default
    ];
    useUserPackages = true;
    useGlobalPkgs = true;
    users.${username}.home = {
      inherit username;
      stateVersion = "23.11";
      homeDirectory = "/home/${username}";
      packages = scripts.shellExports;
    };
  };

  # Internal modules
  modules = {
    dev.git.enable = true;
    services.xdg.enable = true;
    hardware.grub.enable = true;
    shell = {
      tmux.enable = true;
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
