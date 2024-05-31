{
  config,
  lib,
  username,
  ...
}:
with lib; let
  cfg = config.modules.dev.git;
in {
  options.modules.dev.git = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable git";
    };
  };

  config = mkIf (cfg.enable) {
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    home-manager.users.${username} = {
      programs = {
        gpg.enable = true;

        git = {
          enable = true;
          delta = {
            enable = true;
            catppuccin.enable = true;
          };
          userName = "Krzysztof Saczuk";
          userEmail = "me@krzysztofsaczuk.pl";
          extraConfig = {
            core.editor = "nvim";
            init.defaultBranch = "main";
          };
        };
      };
    };
  };
}
