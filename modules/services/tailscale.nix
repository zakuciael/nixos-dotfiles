{
  lib,
  config,
  pkgs,
  username,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  tailscale = config.services.tailscale.package;
  cfg = config.modules.services.tailscale;
in
{
  options.modules.services.tailscale = {
    enable = mkEnableOption "tailscale vpn";
  };

  config = mkIf cfg.enable {

    sops.secrets."tailscale/auth_key" = { };

    services = {
      resolved = {
        enable = true;
        dnssec = "false";
      };
      tailscale = {
        enable = true;
        authKeyFile = config.sops.secrets."tailscale/auth_key".path;
        useRoutingFeatures = "both";
      };
    };

    networking.interfaces."tailscale0".useDHCP = false;

    systemd.services.tailscaled-cert = {
      description = "Automatic TLS certificate renewal";
      after = [ "tailscaled.service" ];
      requires = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.Type = "oneshot";

      script = ''
        ${tailscale}/bin/tailscale cert "$(${tailscale}/bin/tailscale status --json | ${pkgs.jq}/bin/jq '.Self.DNSName | .[:-1]' -r)"
      '';
    };

    home-manager.users.${username} = {
      services.trayscale.enable = true;
    };
  };
}
