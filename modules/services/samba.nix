{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    mapAttrs'
    mapAttrs
    listToAttrs
    flatten
    optionalString
    ;
  inherit (lib.my.utils) recursiveReadSecretNames readSecrets mkSecretPlaceholder;
  cfg = config.modules.services.samba;
  base = "samba";
  shareMountOptions = [
    "x-gvfs-show"
    "x-systemd.automount"
    "noauto"
    "x-systemd.idle-timeout=60"
    "x-systemd.device-timeout=5s"
    "x-systemd.mount-timeout=5s"
  ];
  user = config.users.users.${username};
  inherit (user) uid group;
  inherit (config.users.groups.${group}) gid;
in
{
  options.modules.services.samba = {
    enable = mkEnableOption "samba network shares";
    shares = mkOption {
      description = "An attribute set of the network shares to mount";
      type = types.attrsOf (
        types.submodule {
          options = {
            url = mkOption {
              description = "The url of the samba share";
              type = types.str;
            };
            secret = mkOption {
              description = "The name of the secret containing credentials for the samba shere";
              type = types.nullOr types.str;
              default = null;
            };
          };
        }
      );
      default = { };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.cifs-utils ];

    sops = {
      templates =
        cfg.shares
        |> mapAttrs' (
          _: value:
          let
            secretName = "${base}/${value.secret}";
            secretValue = readSecrets {
              inherit config;
              base = secretName;
            };
          in
          {
            name = secretName;
            value = {
              mode = "600";
              owner = username;
              content = ''
                username=${
                  mkSecretPlaceholder config [
                    secretName
                    "username"
                  ]
                }
                password=${
                  mkSecretPlaceholder config [
                    secretName
                    "password"
                  ]
                }
                ${optionalString (secretValue ? "domain")
                  "domain=${
                    mkSecretPlaceholder config [
                      secretName
                      "domain"
                    ]
                  }"
                }
              '';
            };
          }
        );

      secrets =
        cfg.shares
        |> builtins.attrValues
        |> builtins.map (
          val:
          recursiveReadSecretNames {
            inherit config;
            base = "${base}/${val.secret}";
          }
        )
        |> flatten
        |> builtins.map (name: {
          inherit name;
          value = { };
        })
        |> listToAttrs;
    };

    fileSystems =
      cfg.shares
      |> mapAttrs (
        _: value: {
          device = value.url;
          fsType = "cifs";
          options = shareMountOptions ++ [
            "credentials=${config.sops.templates."${base}/${value.secret}".path}"
            "user"
            "users"
            "uid=${builtins.toString uid}"
            "gid=${builtins.toString gid}"
          ];
        }
      );
  };
}
