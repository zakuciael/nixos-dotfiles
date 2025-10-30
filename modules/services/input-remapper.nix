{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.services.input-remapper;
in
{
  options.modules.services.input-remapper = {
    enable = mkEnableOption "input-remapper, an easy to use tool to change the mapping of your input device buttons";
  };

  config = mkIf cfg.enable {
    services.input-remapper = {
      enable = true;
      enableUdevRules = true;
    };
  };
}
