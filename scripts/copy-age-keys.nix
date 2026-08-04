{ config, pkgs, ... }: {
  package = pkgs.writeShellApplication {
    name = "copy-age-keys";
    text = ''
      FILE_NAME=''${1:-~/.config/sops/age/keys.txt}

      echo "Writing age keys to file: $FILE_NAME"

      op signin
      KEYS=$(op item list --tags "AGE" --format=json | jq '.[]' -r --compact-output)

      function write_to_file {
        local VALUE=$1

        echo -e "$VALUE" >> "$FILE_NAME"
      }

      function read_json {
        local ITEM=$1
        local EXPR=$2

        eval "$(echo "$ITEM" | jq -r "$EXPR | to_entries | .[] | .key + \"=\" + (.value | @sh)")"
      }

      IFS=$'\n'
      for item in $KEYS; do
        read_json "$item" '{ NAME: .title, ID: .id, REF: "op://\(.vault.name)/\(.id)/", CREATED_AT: .created_at, UPDATED_AT: .updated_at }'

        write_to_file "#              Name: $NAME"
        write_to_file "# 1Password Item ID: $ID"
        write_to_file "#        Created At: $CREATED_AT"
        write_to_file "#        Updated At: $UPDATED_AT"
        write_to_file "#         Recipient: $(op read "$REF/public_key")"
        write_to_file "$(op read "$REF/private_key")\n"
      done
    '';
  };
  export = true;
}
