{
  config,
  options,
  lib,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.services.ssh;
  base = "ssh_servers/";
  secretNames = utils.recursiveReadSecretNames {inherit config base;};
  secrets = utils.readSecrets {inherit config base;};

  mkKeyValue = key: value: "${key} ${value}";
  mkSecretSettings = secret:
    if hasSuffix "/public_key" secret
    then {
      mode = "0600";
      owner = username;
    }
    else {};

  mkPublicKeySettings = host:
    if (hasAttrByPath [host "public_key"] secrets)
    then {
      IdentityFile = utils.mkSecretPath config [base host "public_key"];
      IdentitiesOnly = "yes";
    }
    else {};

  mkHostSettings = host: let
    settings =
      if (hasAttrByPath [host "settings"] secrets)
      then
        listToAttrs (
          builtins.map
          (v: {
            name = v;
            value = utils.mkSecretPlaceholder config [base host "settings" v];
          })
          (builtins.attrNames (attrByPath [host "settings"] {} secrets))
        )
      else {};
  in
    settings // (mkPublicKeySettings host);

  mkHost = host: settings: ''
    Host ${utils.mkSecretPlaceholder config [base host "host"]}
    ${utils.indentLines "  " (concatLines (builtins.map (v: mkKeyValue v.name v.value) (attrsToList settings)))}'';
in {
  options.modules.services.ssh = with types; {
    enable = mkEnableOption "my ssh configuration";
    server = {
      enable = mkEnableOption "openssh server";
      listenAddresses = mkOption {
        inherit (options.services.openssh.listenAddresses) description example type;
        default = [];
      };
    };
  };

  config = mkIf (cfg.enable) {
    sops = {
      templates = {
        "ssh/hosts.conf" = {
          mode = "600";
          owner = username;
          content =
            lib.concatLines
            (builtins.map (host: mkHost host (mkHostSettings host))
              (builtins.attrNames secrets));
        };
      };
      secrets = lib.listToAttrs (builtins.map (v:
        lib.nameValuePair v (mkSecretSettings v))
      secretNames);
    };

    services.openssh = mkIf (cfg.server.enable) {
      enable = true;
      openFirewall = true;
      allowSFTP = true;
      listenAddresses = cfg.server.listenAddresses;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    home-manager.users.${username}.programs.ssh = {
      enable = true;
      includes = singleton config.sops.templates."ssh/hosts.conf".path;
    };
  };
}
