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
  cfg = config.modules.dev.kubernetes;
in
{
  options.modules.dev.kubernetes = {
    enable = mkEnableOption "kubernetes tools";
  };

  config = mkIf (cfg.enable) {
    home-manager.users.${username} = {
      home.packages = with pkgs; [
        kubectl
        kubectx
        kustomize
        kubernetes-helm
        kubectl-tree
      ];

      catppuccin.k9s.enable = true;
      programs = {
        k9s = {
          enable = true;
        };
        fish.shellAliases = with pkgs; {
          k = "${getBin kubectl}/bin/kubectl";
          kc = "${getBin kubectx}/bin/kubectx";
          kn = "${getBin kubectx}/bin/kubens";
        };
      };
    };
  };
}
