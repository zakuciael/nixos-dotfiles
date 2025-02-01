{
  pkgs,
  inputs,
  system,
  ...
}:
{
  # Default modules to import
  imports = [
    ./hardware.nix
    ./networking.nix
  ];

  # Nix config
  nix = {
    settings = {
      auto-optimise-store = true;
      substituters = [ ];
      trusted-public-keys = [ ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 1w";
    };
    # TODO: Add access tokens from secrets
    extraOptions = ''
      experimental-features = nix-command flakes pipe-operators
    '';
    package = pkgs.nixVersions.latest;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  # Nixpkgs config
  nixpkgs = {
    hostPlatform = system;
    config.allowUnfree = true;
    overlays = [
      inputs.self.overlays.default
    ];
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

  # System version
  system.stateVersion = "24.11";
}
