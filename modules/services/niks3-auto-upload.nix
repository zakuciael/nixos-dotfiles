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
  options.modules.services.niks3-auto-upload = {
    enable = mkEnableOption "niks3 auto-upload hooks";
  };

  config = mkIf cfg.enable {
    sops.secrets.niks3-auth-token = { };

    services.niks3-auto-upload = {
      enable = true;
      serverUrl = "https://cache.zakku.eu";
      authTokenFile = config.sops.secrets.niks3-auth-token.path;
    };
  };
}
