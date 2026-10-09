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

      # Passed through to mkDerivation as env (name is reserved for the drv).
      NIX_PATH = "nixpkgs=${pkgs.path}";
      overlayName = name;
      updateScript = script;

      effectScript = ''
        set -euo pipefail

        git config --global user.name "$(readSecretString git-author .username)"
        git config --global user.email "$(readSecretString git-author .email)"
        git config --global safe.directory '*'

        if [[ ! -f "$updateScript" ]]; then
          echo "update script missing: $updateScript" >&2
          exit 1
        fi
        chmod +x "$updateScript"
        "$updateScript"

        if git diff --quiet && git diff --cached --quiet; then
          echo "No changes for overlay $overlayName"
          exit 0
        fi

        branch="chore/deps-overlay-$overlayName"
        git checkout -B "$branch"
        # Only stage this overlay's tree so flake.lock / unrelated dirt cannot hitchhike.
        git add -- "overlays/$overlayName"
        if git diff --cached --quiet; then
          echo "Updater touched files outside overlays/$overlayName; aborting" >&2
          git status --short >&2
          exit 1
        fi
        git commit -m "chore(deps): update $overlayName overlay"
        git push -u origin "HEAD:refs/heads/$branch" --force-with-lease

        if [[ -z "$(gh pr list --head "$branch" --json number --jq '.[0].number // empty')" ]]; then
          gh pr create \
            --base main \
            --head "$branch" \
            --title "chore(deps): update $overlayName overlay" \
            --label "type: deps" \
            --body "Automated overlay update for \`$overlayName\` via nixbot schedule effect."
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
