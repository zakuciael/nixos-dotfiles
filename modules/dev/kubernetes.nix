{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.dev.kubernetes;
in {
  options.modules.dev.kubernetes = {
    enable = mkEnableOption "kubernetes tools";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      home.packages = with pkgs; [kubectl];

      programs = {
        k9s = {
          enable = true;
          catppuccin.enable = true;
        };
        fish.shellAliases = {
          k = "kubectl";
          kn = "kubectl config set-context --current --namespace";
          kc = "kubectl config use-context";
          kcr = "kubectl config unset current-context";
        };
      };
    };
  };
}
