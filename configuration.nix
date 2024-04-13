{
  config,
  pkgs,
  lib,
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

  # Timezone
  time.timeZone = "Europe/Warsaw";

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

  # Boot configuration
  boot = {
    supportedFilesystems = ["ntfs"];

    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      grub = {
        configurationLimit = 5;
        efiSupport = true;
        device = "nodev";
        useOSProber = true;
      };
    };
  };

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Configure user / user applications (TODO: Home-Manager, cuz we ain't pussies here)
  users.users."zakuciael" = {
    isNormalUser = true;
    description = "Krzysztof Saczuk";
    extraGroups = ["networkmanager" "wheel"];
  };

  # Configure home-manager
  home-manager = {
    extraSpecialArgs = {inherit pkgs lib;};
    useUserPackages = true;
    useGlobalPkgs = true;
  };

  # Configure environment
  environment = {
    systemPackages = with pkgs; [neovim git bash];
    variables = {
      EDITOR = "nvim";
      NIXOS_CONFIG = "/home/zakuciael/nixos";
    };
    shells = with pkgs; [bash];
  };

  # Configure modules
  modules = {
    shell = {
      tmux.enable = true;
      fish = {
        enable = true;
        default = true;
      };
    };
  };

  # Configure programs (system-wide)
  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = ["zakuciael"];
    };
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
