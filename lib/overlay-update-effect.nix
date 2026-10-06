{
  lib,
  pkgs,
  nixbot,
}:
let
  inherit (nixbot.lib.effects { inherit pkgs; }) mkEffect;

  weeklyWhen = {
    dayOfWeek = [ "Sun" ];
    hour = [ 0 ];
    # minute intentionally unset — nixbot hash-staggers by schedule name
  };

  mkOverlayUpdateEffect =
    name: script:
    mkEffect {
      name = "update-overlay-${name}";
      checkout = true;
      secretsMap.git-author = "git-author";
      inputs = with pkgs; [
        git
        gh
        cacert
        nix
      ];
      effectScript = ''
        set -euo pipefail

        cd "$NIXBOT_EFFECT_CHECKOUT"

        git config --global user.name "$(readSecretString git-author .username)"
        git config --global user.email "$(readSecretString git-author .email)"
        git config --global safe.directory '*'

        script=${lib.escapeShellArg script}
        name=${lib.escapeShellArg name}

        if [[ ! -f "$script" ]]; then
          echo "update script missing: $script" >&2
          exit 1
        fi
        chmod +x "$script"
        "$script"

        if git diff --quiet && git diff --cached --quiet; then
          echo "No changes for overlay $name"
          exit 0
        fi

        branch="chore/deps-overlay-$name"
        git checkout -B "$branch"
        # Only stage this overlay's tree so flake.lock / unrelated dirt cannot hitchhike.
        git add -- "overlays/$name"
        if git diff --cached --quiet; then
          echo "Updater touched files outside overlays/$name; aborting" >&2
          git status --short >&2
          exit 1
        fi
        git commit -m "chore(deps): update $name overlay"
        git push -u origin "HEAD:refs/heads/$branch" --force-with-lease

        if [[ -z "$(gh pr list --head "$branch" --json number --jq '.[0].number // empty')" ]]; then
          gh pr create \
            --base main \
            --head "$branch" \
            --title "chore(deps): update $name overlay" \
            --label "type: deps" \
            --body "Automated overlay update for \`$name\` via nixbot schedule effect."
        fi

        gh pr merge --squash --auto "$branch"
      '';
    };
in
{
  mkOnSchedule =
    updaters:
    lib.mapAttrs (name: script: {
      when = weeklyWhen;
      outputs.effects.default = mkOverlayUpdateEffect name script;
    }) updaters;
}
