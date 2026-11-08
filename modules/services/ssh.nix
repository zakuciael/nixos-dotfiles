{
  config,
  options,
  lib,
  username,
  ...
}:
with lib;
with lib.my;
let
  cfg = config.modules.services.ssh;
  base = "ssh_servers/";
  secretNames = utils.recursiveReadSecretNames { inherit config base; };
  secrets = utils.readSecrets { inherit config base; };

  mkKeyValue =
    key: value:
    if builtins.isList value then
      value |> concatMapStringsSep "\n" (v: "${key} ${v}")
    else
      "${key} ${value}";
  mkSecretSettings =
    secret:
    if hasSuffix "/public_key" secret then
      {
        mode = "0600";
        owner = username;
      }
    else
      { };

  mkPublicKeySettings =
    host:
    if (hasAttrByPath [ host "public_key" ] secrets) then
      if (builtins.isAttrs (getAttrFromPath [ host "public_key" ] secrets)) then
        {
          IdentityFile =
            getAttrFromPath [ host "public_key" ] secrets
            |> attrNames
            |> map (
              name:
              utils.mkSecretPath config [
                base
                host
                "public_key"
                name
              ]
            );
        }
      else
        {
          IdentityFile = utils.mkSecretPath config [
            base
            host
            "public_key"
          ];
          IdentitiesOnly = "yes";
        }
    else
      { };

  mkHostSettings =
    host:
    let
      settings =
        if (hasAttrByPath [ host "settings" ] secrets) then
          listToAttrs (
            map (v: {
              name = v;
              value = utils.mkSecretPlaceholder config [
                base
                host
                "settings"
                v
              ];
            }) (builtins.attrNames (attrByPath [ host "settings" ] { } secrets))
          )
        else
          { };
    in
    settings // (mkPublicKeySettings host);

  mkHost = host: settings: ''
    Host ${
      utils.mkSecretPlaceholder config [
        base
        host
        "host"
      ]
    }
    ${utils.indentLines "  " (
      concatLines (map (v: mkKeyValue v.name v.value) (attrsToList settings))
    )}'';
in
{
  options.modules.services.ssh = with types; {
    enable = mkEnableOption "my ssh configuration";
    server = {
      enable = mkEnableOption "openssh server";
      listenAddresses = mkOption {
        inherit (options.services.openssh.listenAddresses) description example type;
        default = [ ];
      };
    };
  };

  config = mkIf cfg.enable {
    sops = {
      templates = {
        "ssh/hosts.conf" = {
          mode = "600";
          owner = username;
          content = lib.concatLines (
            map (host: mkHost host (mkHostSettings host)) (builtins.attrNames secrets)
          );
        };
      };
      secrets = lib.listToAttrs (map (v: lib.nameValuePair v (mkSecretSettings v)) secretNames);
    };

    services.openssh = mkIf cfg.server.enable {
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
      enableDefaultConfig = false;

      settings."*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };

      includes = singleton config.sops.templates."ssh/hosts.conf".path;
    };
  };
}
