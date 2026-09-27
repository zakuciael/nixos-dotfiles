# Debugging evaluation and build failures

## Evaluation or build

- **Evaluation errors** happen before anything is built: `error: attribute
  ... missing`, type errors, infinite recursion, assertion failures. Add
  `--show-trace` to see which expression caused them.
- **Build errors** come from a builder: a compiler error, a failing test phase,
  a missing file. The message ends with a pointer to the build log.

`--show-trace` and `--keep-failed` are global settings, so they work on any
`nix` command.

## Read the whole log

```sh
nix log INSTALLABLE_OR_DRV   # the stored log of a failed or finished build
nix build -L INSTALLABLE     # stream logs while building (--print-build-logs)
nix build --keep-failed INSTALLABLE   # keep the build directory to inspect
```

The first error in the log is usually the real one. Test failures often
follow from an earlier failure in the same phase. `nix build --rebuild`
checks whether a finished build is reproducible.

## Search before inventing a fix

Many failures have already been reported and fixed. Search with the most
distinctive part of the error, such as a missing symbol, a file name or a
test name, and the package name:

```sh
gh search issues --repo NixOS/nixpkgs "undefined reference to SSL_get1_peer_certificate"
gh search prs --repo NixOS/nixpkgs "python3Packages.foo" --state open
gh search prs --repo NixOS/nixpkgs "foo: fix build" --merged
```

Without `gh`, use the search on
[github.com/NixOS/nixpkgs](https://github.com/NixOS/nixpkgs/issues) and the
[NixOS Discourse](https://discourse.nixos.org/).

Also check whether upstream Nixpkgs builds the package at all:
[Hydra](https://hydra.nixos.org/) shows the job's status on each branch. A
package broken everywhere needs a different answer from one broken only in the
user's configuration.

When a pull request fixes the problem, find out whether it has reached the
user's branch. The [PR tracker](https://nixpk.gs/pr-tracker.html) shows which
channels contain a merged PR. Then compare with the user's pinned Nixpkgs
revision.

## Report, then propose

State what you found: issue and PR numbers, whether a fix is merged, and
whether it has reached the user's pin. Then propose options in order of
preference:

1. Update the pin, if the fix is already in a channel the user can move to.
2. Apply the upstream fix as an overlay or patch, citing the PR.
3. A local workaround, labelled as such, with the reason upstream's fix
   cannot be used.

Do not disable the sandbox, tests or hardening to make an error disappear.
Do not pin an arbitrary Nixpkgs commit without saying why that commit, and
what else it changes. For packaging changes, continue with the
`nixpkgs-development` skill, or the
[Nixpkgs manual](https://nixos.org/manual/nixpkgs/unstable/) if that skill is
not installed.
