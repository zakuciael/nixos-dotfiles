{
  config,
  lib,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.shell.nix;
in {
  options.modules.shell.nix = {
    enable = mkEnableOption "nix shell integrations";
  };

  config = mkIf (cfg.enable) {
    programs = {
      command-not-found.enable = false;
      nix-index.enable = true;
    };
  };
}
