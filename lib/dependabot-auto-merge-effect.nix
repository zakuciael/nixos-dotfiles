{
  pkgs,
  nixbot,
}:
let
  inherit (nixbot.lib.effects { inherit pkgs; }) mkEffect;
in
{
  onEvent.pull_request.dependabot-auto-merge = mkEffect {
    name = "dependabot-auto-merge";
    checkout = true;
    inputs = with pkgs; [
      gh
      git
    ];
    secretsMap.github = {
      type = "GitToken";
    };
    effectScript = ''
      set -euo pipefail

      author=$(jq -r '.pullRequest.author.name // empty' "$NIXBOT_EVENT_JSON")
      if [[ "$author" != "github:dependabot[bot]" ]]; then
        echo "skip: author is ''${author:-unknown}"
        exit 0
      fi

      export GH_TOKEN
      GH_TOKEN=$(readSecretString github .token)

      pr_url=$(jq -r '.pullRequest.url' "$NIXBOT_EVENT_JSON")
      gh pr merge --auto --squash "$pr_url"
    '';
  };
}
