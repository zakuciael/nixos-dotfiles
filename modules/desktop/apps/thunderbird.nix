{
  config,
  lib,
  pkgs,
  unstable,
  username,
  ...
}:
with lib;
with lib.my;
with lib.my.utils; let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  hmConfig = config.home-manager.users.${username};
  homeDirectory = hmConfig.home.homeDirectory;

  thunderbirdProfiles = hmConfig.programs.thunderbird.profiles;
  thunderbirdConfigPath =
    if isDarwin
    then "Library/Thunderbird"
    else ".thunderbird";
  thunderbirdProfilesPath =
    if isDarwin
    then "${thunderbirdConfigPath}/Profiles"
    else thunderbirdConfigPath;

  base = "email";
  secretNames = utils.recursiveReadSecretNames {inherit config base;};
  secrets = utils.readSecrets {inherit config base;};

  accounts = builtins.map (secret: secret.value // {inherit (secret) name;}) (lib.attrsToList secrets);
  accountsWithId = map (acc: acc // {id = builtins.hashString "sha256" acc.name;}) accounts;

  mkImapAddressString = account: let
    userName = mkSecretPlaceholder config [base account.name "userName"];
    host = mkSecretPlaceholder config [base account.name "imap" "host"];
  in ''"imap://" + encodeURIComponent("${userName}") + "@${host}"'';

  mkImapFolderAddressString = account: folder: let
    folderName = mkSecretPlaceholder config [base account.name "folders" folder];
  in ''${mkImapAddressString account} + "/${folderName}"'';

  toThunderbirdIdentity = {
    account,
    address_name,
    isPrimaryAddress ? false,
  }:
  # For backwards compatibility, the primary address reuses the account ID.
  let
    id =
      if isPrimaryAddress
      then account.id
      else builtins.hashString "sha256" address_name;
  in
    {
      "mail.identity.id_${id}.fullName" = mkSecretPlaceholder config [base account.name "realName"];
      "mail.identity.id_${id}.useremail" = (
        if isPrimaryAddress
        then mkSecretPlaceholder config [base account.name "address"]
        else mkSecretPlaceholder config [base account.name "aliases" address_name]
      );
      "mail.identity.id_${id}.valid" = mkLiteral true;
      "mail.identity.id_${id}.htmlSigText" = (
        if ((hasAttrByPath ["signature" "showSignature"] account) && (hasAttrByPath ["signature" "text"] account))
        then mkSecretPlaceholder config [base account.name "signature" "text"]
        else ""
      );
    }
    // optionalAttrs (hasAttrByPath ["folders" "sent"] account) {
      "mail.identity.id_${id}.fcc_folder_picker_mode" = "1";
      "mail.identity.id_${id}.fcc_folder" = mkLiteral (mkImapFolderAddressString account "sent");
    }
    // optionalAttrs (hasAttrByPath ["folders" "drafts"] account) {
      "mail.identity.id_${id}.drafts_folder_picker_mode" = "1";
      "mail.identity.id_${id}.draft_folder" = mkLiteral (mkImapFolderAddressString account "drafts");
    }
    // optionalAttrs (hasAttrByPath ["folders" "archive"] account) {
      "mail.identity.id_${id}.archive_enabled" = mkLiteral true;
      "mail.identity.id_${id}.draft_folder" = mkLiteral (mkImapFolderAddressString account "archive");
    };

  toThunderbirdAccount = account: profile: let
    id = account.id;
  in
    {
      "mail.account.account_${id}.identities" = "id_${id}";
      "mail.account.account_${id}.server" = "server_${id}";
    }
    // optionalAttrs (hasAttrByPath ["primary"] account) {
      "mail.accountmanager.defaultaccount" = "account_${id}";
    }
    // optionalAttrs (hasAttrByPath ["imap"] account) {
      "mail.server.server_${id}.directory" = "${thunderbirdProfilesPath}/${profile}/ImapMail/${id}";
      "mail.server.server_${id}.directory-rel" = "[ProfD]ImapMail/${id}";
      "mail.server.server_${id}.hostname" = mkSecretPlaceholder config [base account.name "imap" "host"];
      "mail.server.server_${id}.login_at_startup" = mkLiteral true;
      "mail.server.server_${id}.name" =
        if (hasAttrByPath ["displayName"] account)
        then mkSecretPlaceholder config [base account.name "displayName"]
        else account.name;
      "mail.server.server_${id}.port" = mkLiteral (
        if (hasAttrByPath ["imap" "port"] account)
        then mkSecretPlaceholder config [base account.name "imap" "port"]
        else 143
      );
      "mail.server.server_${id}.socketType" = mkLiteral (
        if !(hasAttrByPath ["imap" "tls" "enable"] account)
        then 0
        else if (hasAttrByPath ["imap" "tls" "useStartTls"] account)
        then 2
        else 3
      );
      "mail.server.server_${id}.type" = "imap";
      "mail.server.server_${id}.userName" = mkSecretPlaceholder config [base account.name "userName"];
    }
    // optionalAttrs (hasAttrByPath ["folders" "trash"] account) {
      "mail.server.server_${id}.trash_folder_name" = mkLiteral (mkImapFolderAddressString account "trash");
    }
    // optionalAttrs (hasAttrByPath ["folders" "spam"] account) {
      "mail.server.server_${id}.spamActionTargetAccount" = mkLiteral (mkImapAddressString account);
      "mail.server.server_${id}.moveOnSpam" = mkLiteral true;
      "mail.server.server_${id}.spamActionTargetFolder" = mkLiteral (mkImapFolderAddressString account "spam");
    }
    // optionalAttrs (hasAttrByPath ["smtp"] account) {
      "mail.identity.id_${id}.smtpServer" = "smtp_${id}";
      "mail.smtpserver.smtp_${id}.authMethod" = mkLiteral 3;
      "mail.smtpserver.smtp_${id}.hostname" = mkSecretPlaceholder config [base account.name "smtp" "host"];
      "mail.smtpserver.smtp_${id}.port" = mkLiteral (
        if (hasAttrByPath ["smtp" "port"] account)
        then mkSecretPlaceholder config [base account.name "smtp" "port"]
        else 587
      );
      "mail.smtpserver.smtp_${id}.try_ssl" = mkLiteral (
        if !(hasAttrByPath ["smtp" "tls" "enable"] account)
        then 0
        else if (hasAttrByPath ["smtp" "tls" "useStartTls"] account)
        then 2
        else 3
      );
      "mail.smtpserver.smtp_${id}.username" = mkSecretPlaceholder config [base account.name "userName"];
    }
    // optionalAttrs ((hasAttrByPath ["smtp"] account) && (hasAttrByPath ["primary"] account)) {
      "mail.smtp.defaultserver" = "smtp_${id}";
    }
    // (builtins.foldl' (a: b: a // b) {} (
      builtins.map
      (address_name: toThunderbirdIdentity {inherit account address_name;})
      (builtins.attrNames (attrByPath ["aliases"] {} account))
    ))
    // (toThunderbirdIdentity {
      inherit account;
      address_name = "";
      isPrimaryAddress = true;
    });

  mkUserJs = prefs: ''
    ${concatStrings (mapAttrsToList (name: value: ''
        user_pref("${name}", ${
          if isLiteral value
          then mapper.toString value.data
          else ''"${value}"''
        });
      '')
      prefs)}
  '';
in {
  sops = {
    templates = listToAttrs (
      builtins.map
      (profile: let
        accounts = filter (acc: !(hasAttrByPath ["thunderbird_profiles"] acc) || any (p: p == profile) (builtins.attrNames acc.thunderbird_profiles)) accountsWithId;
        smtp = filter (acc: hasAttrByPath ["smtp"] acc) accounts;
      in
        nameValuePair "thunderbird/${profile}/user.js" {
          mode = "0644";
          owner = username;
          path = "${homeDirectory}/${thunderbirdProfilesPath}/${profile}/user.js";
          content = mkUserJs (builtins.foldl' (a: b: a // b) {} ([
              (optionalAttrs (length accounts != 0) {
                "mail.accountmanager.accounts" = concatStringsSep "," (builtins.map (a: "account_${a.id}") accounts);
              })

              (optionalAttrs (length smtp != 0) {
                "mail.smtpservers" = concatStringsSep "," (builtins.map (a: "smtp_${a.id}") smtp);
              })

              {"mail.openpgp.allow_external_gnupg" = mkLiteral (attrByPath [profile "withExternalGnupg"] false thunderbirdProfiles);}
            ]
            ++ (builtins.map (acc: toThunderbirdAccount acc profile) accounts)));
        })
      (builtins.attrNames thunderbirdProfiles)
    );

    secrets = listToAttrs (builtins.map (v: nameValuePair v {}) secretNames);
  };

  home-manager.users.${username} = {
    programs.thunderbird = {
      enable = true;
      package = unstable.thunderbird;
      profiles = {
        "default" = {
          isDefault = true;
        };
      };
    };

    home.file = listToAttrs (
      builtins.map
      (
        profile:
          nameValuePair
          "${thunderbirdProfilesPath}/${profile}/user.js"
          {enable = false;}
      )
      (builtins.attrNames thunderbirdProfiles)
    );
  };
}
