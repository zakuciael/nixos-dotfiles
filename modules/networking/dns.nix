{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.my.utils) mkSecretPlaceholder;
  inherit (pkgs) writeText;
in
{
  sops.secrets."dns" = { };

  networking.hostFiles = [
    (writeText "secret-hosts" "${mkSecretPlaceholder config [ "dns" ]}")
  ];
}
