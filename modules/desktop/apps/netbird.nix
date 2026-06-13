{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mapAttrs';
in
{
  services = {
    # Required for Netbird's client-side DNS resolution
    resolved.enable = true;

    netbird = {
      enable = true; # for netbird service & CLI
      ui.enable = true;

      clients.default = {
        name = "netbird";
        interface = "wt0";
        port = 51821;

        openFirewall = true;
        openInternalFirewall = true;
        autoStart = true;
      };

      useRoutingFeatures = "both";
    };
  };

  # TODO: Remove when https://github.com/NixOS/nixpkgs/pull/520740 is pulled by the `flake.lock` file.
  systemd.services =
    config.services.netbird.clients
    |> mapAttrs' (
      _: val: {
        name = val.service.name;
        value = {
          path = [ pkgs.shadow ];
        };
      }
    );
}
