{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.hm) dag;

  cfg = config.modules.shell.atuin;
  user = config.users.users.${username};
  hmConfig = config.home-manager.users.${username};

  keySecret = "atuin/key";
  sessionSecret = "atuin/session";
  keySecretPath = config.sops.secrets.${keySecret}.path;
  sessionSecretPath = config.sops.secrets.${sessionSecret}.path;

  configDir = "${hmConfig.xdg.configHome}/atuin";
  dataDir = "${hmConfig.xdg.dataHome}/atuin";

  seedAtuinSession = pkgs.writers.writePython3Bin "seed-atuin-session" { } ''
    import sqlite3
    import sys
    from pathlib import Path

    meta_db = Path(sys.argv[1])
    token = Path(sys.argv[2]).read_text().strip()
    if not token:
        raise SystemExit("atuin session secret is empty")

    key = "hub_session" if token.startswith("atapi_") else "session"
    meta_db.parent.mkdir(parents=True, exist_ok=True)

    con = sqlite3.connect(meta_db)
    try:
        con.execute(
            """
            CREATE TABLE IF NOT EXISTS meta (
                key text not null primary key,
                value text not null,
                updated_at integer not null default (strftime('%s', 'now'))
            )
            """
        )
        con.execute(
            """
            INSERT INTO meta (key, value, updated_at)
            VALUES (?, ?, strftime('%s', 'now'))
            ON CONFLICT(key) DO UPDATE SET
              value = excluded.value,
              updated_at = excluded.updated_at
            """,
            (key, token),
        )
        con.commit()
    finally:
        con.close()
  '';
in
{
  options.modules.shell.atuin = {
    enable = mkEnableOption "Atuin shell history";
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      ${keySecret} = {
        owner = user.name;
        inherit (user) group;
      };
      ${sessionSecret} = {
        owner = user.name;
        inherit (user) group;
      };
    };

    home-manager.users.${username} = {
      home.sessionVariables.ATUIN_CONFIG_DIR = configDir;

      programs.atuin = {
        enable = true;
        daemon.enable = true;
        settings = {
          auto_sync = true;
          update_check = false;
          sync_frequency = "5m";
          sync_address = "https://api.atuin.sh";
          search_mode = "fuzzy";
          data_dir = dataDir;
          key_path = keySecretPath;
          filter_mode_shell_up_key_binding = "session-preload";
        };
      };

      # Atuin 18.24+ stores session tokens in meta.db (session_path is gone).
      home.activation.atuinSession = dag.entryAfter [ "writeBoundary" ] ''
        meta_db="${dataDir}/meta.db"
        session_file="${sessionSecretPath}"

        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${dataDir}"

        if [[ ! -f "$session_file" ]]; then
          echo "atuin: session secret missing at $session_file; skip login seed"
        else
          $DRY_RUN_CMD ${seedAtuinSession}/bin/seed-atuin-session "$meta_db" "$session_file"
        fi
      '';
    };
  };
}
