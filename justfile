[private]
@default:
  just --list --list-heading $'Usage: just <command> [args]\nCommands:\n' --list-prefix $' - '

@update:
  nix flake update
  overlays/jetbrains/ides/update_bin.py
  git add \
    ./overlays/jetbrains/ides/versions.json \
    ./overlays/jetbrains/plugins/plugins.json \
    ./flake.lock
  nix flake check
  git commit -m "chore(deps): update \`flake.lock\` and JetBrains IDEs"

@apply:
  nh os switch .

@check:
  nix flake check
