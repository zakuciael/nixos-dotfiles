{
  config,
  lib,
  username,
  ...
}:
with lib;
let
  cfg = config.modules.dev.git;
in
{
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
      catppuccin.delta.enable = true;

      programs = {
        gpg.enable = true;

        git = {
          enable = true;
          delta = {
            enable = true;
          };
          userName = "Krzysztof Saczuk";
          userEmail = "me@krzysztofsaczuk.pl";
          aliases = {
            "ffp" = ''
              !git diff -p -R --no-ext-diff --no-color --diff-filter=M | \
                grep -E "^(diff|(old|new) mode)" --color=never | \
                git apply
            '';
          };
          extraConfig = {
            core = {
              fileMode = false;
              editor = "nvim";
            };
            init.defaultBranch = "main";
          };
        };
      };
    };
  };
}
