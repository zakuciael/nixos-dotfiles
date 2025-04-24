[private]
@default:
  just --list --list-heading $'Usage: just <command> [args]\nCommands:\n' --list-prefix $' - '

@update:
  nix flake update
  overlays/jetbrains/ides/update_bin.py

@apply:
  nh os switch

@check:
  nix flake check
