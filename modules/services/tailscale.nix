{
  config,
  pkgs,
  username,
  ...
}:
let
  tailscale = config.services.tailscale.package;
in
{
  sops.secrets."tailscale/auth_key" = { };

  services = {
    resolved = {
      enable = true;
      dnssec = "false";
    };
    tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets."tailscale/auth_key".path;
    };
  };

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
}
