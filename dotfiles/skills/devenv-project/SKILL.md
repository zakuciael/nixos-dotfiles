---
name: devenv-project
description: Create, explain, review, and debug devenv project environments, including devenv.nix, devenv.yaml, lockfiles, languages, tasks, services, and shell activation.
---

# devenv project environments

Read the project's `devenv.nix`, `devenv.yaml`, `devenv.lock`, applicable local
configuration, and repository instructions before editing. Preserve existing
conventions and overrides. For a new project, use `devenv init` when available;
inspect its output before adding the smallest configuration needed.

Check `devenv version`, the locked devenv modules and nixpkgs revisions, and
`require_version` when present. These versions can differ independently. The
bundled references describe the release in [sources.json](sources.json), not
necessarily the user's project. Verify version-sensitive options against its
actual modules. `devenv info` evaluates configuration; `devenv search NAME` uses
the project's package input. Evaluation can fetch or build dependencies.

Read only the references needed for the task:

- [Configuration](references/configuration.md): files, packages, inputs, pins,
  imports, profiles, and YAML version requirements.
- [Workflows](references/workflows.md): native activation versus direnv, scripts,
  task dependencies, processes, tests, and git hooks.
- [Options](references/options.md): selected option types, defaults, declarations,
  and Python/JavaScript/Rust/Go/PostgreSQL examples. For other options, consult
  the target revision's modules or documentation; this is not a full catalogue.

Keep project dependencies in project configuration. Host installation follows
local platform policy. Update locks deliberately (`devenv update NAME` for one
input), inspect the diff, and preserve the lock in version control as appropriate.
Do not delete it to hide evaluation failures. Package versions come from project
inputs; changing the host toolchain does not change those pins.

Distinguish native `devenv hook` directory trust (`devenv allow`) from direnv's
`.envrc` approval (`direnv allow`). Inspect the active integration and shell setup
before changing either. Do not silently grant trust, edit startup files, execute
unknown hooks, or start services merely to inspect a project. Respect task
authorization already granted; do not repeatedly request the same consent.

Choose validation according to side effects: `devenv info` evaluates;
`devenv shell -- COMMAND` also runs shell initialization; tasks execute their
dependencies; `devenv up` starts processes; `devenv test` runs `enterTest` and can
start and stop configured processes. Inspect hooks/tasks first and report what
was actually run. Keep secrets out of committed configuration and the Nix store.

Guidance was informed by upstream's [setup skill](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/public/.well-known/agent-skills/devenv-setup/SKILL.md).
References contain modified upstream excerpts under [Apache-2.0](LICENSE).
This portable skill does not replace a machine-specific `devenv` policy skill.

## Nix style

- Never search `/nix/store` (for example `find /nix/store/*foo-* -name libfoo.so`)
  and never copy a literal store path. Find the providing package with
  `nix-locate`, and refer to it through Nix: `${pkgs.foo}/lib` or
  `lib.makeLibraryPath [ pkgs.foo ]`.
- Do not quote attribute names that are valid identifiers
  (`[A-Za-z_][A-Za-z0-9_'-]*`, dashes included). Write `pkgs.foo-bar` and
  `packages.x86_64-linux`, not `pkgs."foo-bar"`. Quote only other names
  (`".config/foo"`, `"2.0"`), the keywords
  `assert else if in inherit let or rec then with`, and interpolations
  (`"${name}"`). Upstream examples in references sometimes quote needlessly;
  do not copy that style.
