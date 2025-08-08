# Colors
BLACK :=  '\e[30m'
RED :=  '\e[31m'
GREEN :=  '\e[32m'
YELLOW := '\e[33m'
BLUE := '\e[34m'
MAGENTA := '\e[35m'
CYAN := '\e[36m'
GRAY := '\e[90m'
WHITE := '\e[97m'

LIGHT_GRAY := '\e[37m'
LIGHT_RED := '\e[91m'
LIGHT_GREEN := '\e[92m'
LIGHT_YELLOW := '\e[93m'
LIGHT_BLUE := '\e[94m'
LIGHT_MAGENTA := '\e[95m'
LIGHT_CYAN := '\e[96m'

RESET:= '\e[0m'
BOLD := '\e[1m'
FAINT := '\e[2m'
ITALIC := '\e[3m'
UNDERLINE := '\e[4m'

[private]
@default:
  just --list --list-heading $'Usage: just <command> [args]\nCommands:\n' --list-prefix $' - '

[private]
@_info msg:
  echo -e "{{BOLD}}[{{RESET}}{{BLUE}}*{{RESET}}{{BOLD}}]{{RESET}} {{msg}}{{RESET}}"

[private]
@_success msg:
  echo -e "{{BOLD}}[{{RESET}}{{GREEN}}+{{RESET}}{{BOLD}}]{{RESET}} {{msg}}{{RESET}}"

[private]
_internal_update_flake:
  #!/usr/bin/env bash
  set -o errexit
  set -o nounset
  set -o pipefail

  just _info "Updating flake.lock file..."
  nix flake update && just _success "Updated flake.lock file successfully!"

[private]
_internal_update_ides:
  #!/usr/bin/env bash
  set -o errexit
  set -o nounset
  set -o pipefail

  just _info "Updating IDE versions..."
  overlays/jetbrains/update_bin.py && just _success "Updated IDE versions successfully!"

[private]
_internal_check_config:
  #!/usr/bin/env bash
  set -o errexit
  set -o nounset
  set -o pipefail

  just _info "Checking configuration..."
  nix flake check && just _success "Configuration checked successfully!"

[private]
_internal_commit_flake:
  #!/usr/bin/env bash
  set -o errexit
  set -o nounset
  set -o pipefail

  just _info "Commiting changes..."
  if ! git diff --quiet --exit-code ./flake.lock; then
    git commit -i ./flake.lock -m "chore(deps): update flake.lock file"
  fi

[private]
_internal_commit_ides:
  #!/usr/bin/env bash
  set -o errexit
  set -o nounset
  set -o pipefail

  if ! git diff --quiet --exit-code ./overlays/jetbrains/versions.json; then
    git commit -i ./overlays/jetbrains/versions.json -m "chore(overlays): update JetBrains IDEs"
  fi

[private]
@_internal_update_complete_msg:
  just _success "Update complete!"
  just _info "To save the changes run the 'git push' command"

update:
  #!/usr/bin/env bash
  set -o errexit
  set -o nounset
  set -o pipefail

  just _internal_update_flake
  just _internal_update_ides
  just _internal_check_config

  just _internal_commit_flake
  just _internal_commit_ides

  just _internal_update_complete_msg

update_flake:
  #!/usr/bin/env bash
  set -o errexit
  set -o nounset
  set -o pipefail

  just _internal_update_flake
  just _internal_check_config
  just _internal_commit_flake

  just _internal_update_complete_msg

update_ides:
  #!/usr/bin/env bash
  set -o errexit
  set -o nounset
  set -o pipefail

  just _internal_update_ides
  just _internal_check_config
  just _internal_commit_ides

  just _internal_update_complete_msg

@apply:
  nh os switch .

@check:
  nix flake check
