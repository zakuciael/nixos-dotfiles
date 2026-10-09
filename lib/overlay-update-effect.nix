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

  baseBranch = "main";
  # Heads created by update-overlay-* schedule effects.
  overlayPrHeadPrefix = "chore/deps-overlay-";

  ghInputs = with pkgs; [
    gh
    git
    cacert
  ];

  # Shared by schedule updates and the onPush rebase effect.
  # Expects: $baseBranch, $GH_TOKEN, a git checkout with origin.
  # Optional: $overlayPrHeadPrefix for bulk rebase.
  prHelpers = ''
    open_pr_number() {
      local head="$1"
      gh pr list --head "$head" --base "$baseBranch" --state open \
        --json number --jq '.[0].number // empty'
    }

    # True when origin/$baseBranch has commits not reachable from the PR head.
    pr_behind_count() {
      local head="$1"
      git fetch --quiet origin \
        "refs/heads/$baseBranch:refs/remotes/origin/$baseBranch" \
        "refs/heads/$head:refs/remotes/origin/$head"
      git rev-list --count "origin/$head..origin/$baseBranch"
    }

    # Auto-merge requires the head to include the latest base commits.
    rebase_pr_if_behind() {
      local pr_number="$1" head="$2" behind
      behind=$(pr_behind_count "$head")
      if [[ "$behind" -gt 0 ]]; then
        echo "PR #$pr_number ($head) is $behind commit(s) behind $baseBranch; rebasing"
        gh pr update-branch "$pr_number" --rebase
      else
        echo "PR #$pr_number ($head) is up to date with $baseBranch"
      fi
    }

    ensure_auto_merge() {
      local pr_ref="$1"
      gh pr merge --squash --auto "$pr_ref"
    }

    # Rebase every open overlay-update PR that is behind the base branch.
    rebase_open_overlay_prs() {
      local pr_number head failed=0
      while IFS=$'\t' read -r pr_number head; do
        [[ -n "$pr_number" ]] || continue
        echo "Checking overlay update PR #$pr_number ($head)"
        if ! rebase_pr_if_behind "$pr_number" "$head"; then
          echo "Failed to rebase PR #$pr_number" >&2
          failed=1
          continue
        fi
        if ! ensure_auto_merge "$pr_number"; then
          echo "Failed to enable auto-merge on PR #$pr_number" >&2
          failed=1
        fi
      done < <(
        gh pr list --base "$baseBranch" --state open --limit 100 \
          --json number,headRefName \
          --jq '
            .[]
            | select(.headRefName | startswith(env.overlayPrHeadPrefix))
            | "\(.number)\t\(.headRefName)"
          '
      )
      return "$failed"
    }
  '';

  mkOverlayUpdateEffect =
    name: script:
    mkEffect {
      name = "update-overlay-${name}";
      checkout = true;
      inputs = ghInputs ++ [ pkgs.nix ];

      secretsMap = {
        git-author = "git-author";
        github.type = "GitToken";
      };

      NIX_PATH = "nixpkgs=${pkgs.path}";
      NIX_CONFIG = "experimental-features = nix-command flakes pipe-operators";
      overlayName = name;
      updateScript = script;
      inherit baseBranch;

      effectScript = ''
        set -euo pipefail

        git config --global user.name "$(readSecretString git-author .username)"
        git config --global user.email "$(readSecretString git-author .email)"
        git config --global safe.directory '*'

        export GH_TOKEN
        GH_TOKEN=$(readSecretString github .token)

        if [[ ! -f "$updateScript" ]]; then
          echo "update script missing: $updateScript" >&2
          exit 1
        fi

        branch="chore/deps-overlay-$overlayName"

        ${prHelpers}

        ensure_pr() {
          if [[ -z "$(open_pr_number "$branch")" ]]; then
            gh pr create \
              --base "$baseBranch" \
              --head "$branch" \
              --title "chore(deps): update $overlayName overlay" \
              --label "type: deps" \
              --body "Automated overlay update for \`$overlayName\` via nixbot schedule effect."
          fi
        }

        # Git often stores updater scripts as 100644; helpers (e.g. update-sources.py) too.
        find "$(dirname "$updateScript")" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' \) \
          -exec chmod +x {} +
        "$updateScript"

        if git diff --quiet && git diff --cached --quiet; then
          pr_number=$(open_pr_number "$branch")
          if [[ -n "$pr_number" ]]; then
            rebase_pr_if_behind "$pr_number" "$branch"
            ensure_auto_merge "$pr_number"
          else
            echo "No changes for overlay $overlayName"
          fi
          exit 0
        fi

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

        ensure_pr
        pr_number=$(open_pr_number "$branch")
        # Fresh push from the checked-out base tip is usually current, but if the
        # effect checkout lagged origin/$baseBranch the PR can still be behind.
        rebase_pr_if_behind "$pr_number" "$branch"
        ensure_auto_merge "$pr_number"
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

  # Runs after a successful default-branch build so open overlay update PRs are
  # rebased as soon as main moves (required for GitHub auto-merge).
  onPush.default.outputs.effects.rebase-overlay-update-prs = mkEffect {
    name = "rebase-overlay-update-prs";
    checkout = true;
    inputs = ghInputs;
    secretsMap.github.type = "GitToken";
    inherit baseBranch overlayPrHeadPrefix;

    effectScript = ''
      set -euo pipefail

      git config --global safe.directory '*'

      export GH_TOKEN
      GH_TOKEN=$(readSecretString github .token)

      ${prHelpers}

      rebase_open_overlay_prs
    '';
  };
}
