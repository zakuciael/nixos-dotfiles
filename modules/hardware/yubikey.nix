{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my;
let
  cfg = config.modules.hardware.yubikey;
  hmConfig = config.home-manager.users.${username};
  configDirectory = hmConfig.xdg.configHome;
in
{
  options.modules.hardware.yubikey = {
    enable = mkEnableOption "YubiKey support";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      yubikey-manager
      yubioath-flutter
      cryptsetup
    ];

    programs.yubikey-touch-detector.enable = true;

    home-manager.users.${username} = {
      programs.gpg = {
        enable = true;

        # https://support.yubico.com/hc/en-us/articles/4819584884124-Resolving-GPG-s-CCID-conflicts
        scdaemonSettings = {
          disable-ccid = true;
        };

        # https://github.com/drduh/config/blob/master/gpg.conf
        settings = {
          personal-cipher-preferences = "AES256 AES192 AES";
          personal-digest-preferences = "SHA512 SHA384 SHA256";
          personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
          default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
          cert-digest-algo = "SHA512";
          s2k-digest-algo = "SHA512";
          s2k-cipher-algo = "AES256";
          charset = "utf-8";
          fixed-list-mode = true;
          no-comments = true;
          no-emit-version = true;
          keyid-format = "0xlong";
          list-options = "show-uid-validity";
          verify-options = "show-uid-validity";
          with-fingerprint = true;
          require-cross-certification = true;
          no-symkey-cache = true;
          use-agent = true;
          throw-keyids = true;
        };
      };

      services.gpg-agent = {
        enable = true;

        # https://github.com/drduh/config/blob/master/gpg-agent.conf
        defaultCacheTtl = 60;
        maxCacheTtl = 120;
        pinentry.package = pkgs.pinentry-curses;
        extraConfig = ''
          ttyname $GPG_TTY
        '';
      };
    };

    services = {
      pcscd.enable = true;
      udev = {
        packages = with pkgs; [ yubikey-manager ];
        extraRules = ''
          ACTION=="remove",\
           ENV{ID_BUS}=="usb",\
           ENV{ID_MODEL_ID}=="0407",\
           ENV{ID_VENDOR_ID}=="1050",\
           ENV{ID_VENDOR}=="Yubico",\
           RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
        '';
      };
    };

    sops.secrets = {
      "users/${username}/u2f_keys" = {
        mode = "0644";
        owner = username;
        path = "${configDirectory}/Yubico/u2f_keys";
      };
    };

    security.pam = {
      u2f = {
        enable = true;
        settings = {
          cue = true;
          interactive = false;
        };
        control = "sufficient";
      };

      services = {
        login.u2fAuth = false;
        sudo.u2fAuth = true;
      };
    };
  };
}
