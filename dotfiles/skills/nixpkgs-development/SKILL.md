---
name: nixpkgs-development
description: Write, explain, review, and debug Nixpkgs package expressions, build helpers, overrides, overlays, and library APIs against the project's pinned package set.
---

# Nixpkgs development

Read the repository instructions, existing package expressions, and actual Nixpkgs
input/lock before editing. Keep its package layout, overlays, and development
environment conventions. Distinguish the Nix evaluator version, Nixpkgs revision,
and build/host/target platforms. The bundled references describe the master
snapshot in [sources.json](sources.json); they are not a stable-release claim or
proof that an API exists in an older consumer pin.

Read only the relevant reference:

- [Packaging](references/packaging.md): stdenv, dependency roles, phases/hooks,
  metadata, and package tests.
- [Customization](references/customization.md): argument overrides, attribute
  overrides, overlays, and generic module composition.
- [Helpers](references/helpers.md): fetchers/hashes, small builders, mkShell,
  and entry points for Python, JavaScript, Go, and Rust packaging.
- [Library](references/library.md): selected generated API descriptions, types,
  arguments, and examples with pinned declarations.
- [Contributing](references/contributing.md): Nixpkgs' own contributor rules.
  These cover pull requests and review, target branches and mass rebuilds,
  commit messages, `pkgs/by-name` placement, package naming, versioning,
  patches and automatic updates. Read it for any change intended for Nixpkgs
  itself.

For library and NixOS module contributions, also read upstream's
[lib/README.md](https://github.com/NixOS/nixpkgs/blob/master/lib/README.md)
and [nixos/README.md](https://github.com/NixOS/nixpkgs/blob/master/nixos/README.md).
These links follow the master branch; they are not pinned.

Choose the mechanism that matches the change: `override` changes recipe arguments;
`overrideAttrs` changes mkDerivation inputs; overlays compose package sets;
module options merge configuration. In overlays, use the previous package for
its original recipe and the final set for dependencies; inspect self-reference
when diagnosing recursion. Inspect the target recipe before assuming every
language helper has the same override behavior.

Prefer an existing appropriate build helper. Preserve pre/post hooks when replacing
phases, keep native build tools distinct from host dependencies, and inspect
platform assumptions. A temporary fake hash is a discovery aid: finish with the
verified hash for the selected fetcher/source. Preserve upstream lockfiles and
update consumer inputs deliberately, not merely to match these references.
Do not disable checks, sandboxing, or hardening to hide an unexplained failure.

Start validation with the target package set and bounded checks for the change.
Report evaluation, actual builds, and runtime tests separately. Documentation
examples can use historical versions or illustrative values; inspect them before
adapting or running them. Do not execute arbitrary snippets merely to read docs.
Respect existing task authorization and keep secrets out of the Nix store.

Before working around a build or packaging failure, read the full build log,
then search NixOS/nixpkgs issues and pull requests for the distinctive error
and the package name, for example
`gh search issues --repo NixOS/nixpkgs "<error>"` and
`gh search prs --repo NixOS/nixpkgs "<package>"`. Cite what you found, and
whether a fix has reached the user's pin, before proposing a local workaround.

Use [nixpkgs-review](https://github.com/Mic92/nixpkgs-review) to build what a
Nixpkgs change affects:

- `nixpkgs-review wip` for uncommitted changes;
- `nixpkgs-review rev HEAD` for a commit;
- `nixpkgs-review pr NUMBER` for a pull request.

It builds every affected package, which can be many and slow, so check the
scope and ask before running it on a large change. Read its report of failed,
broken and skipped packages before stating a result. Never use `post-result`,
`approve`, `merge`, `--post-result` or `--approve-pr` without the user's
explicit authorization: they act on GitHub under the user's identity.

Version-bump pull requests from `r-ryantm` come from
[nixpkgs-update](https://nix-community.github.io/nixpkgs-update/). Review them
like any update: read the upstream changelog, build with `nixpkgs-review pr`,
and check the linked [update logs](https://nixpkgs-update-logs.nix-community.org/).

This skill does not supply a complete package/API catalogue or NixOS/Home Manager
option reference. Host installation and deployment follow local policy. Public
manual links can move; packaged excerpts and source citations are revision-pinned.
Modified upstream material is covered by [COPYING](COPYING).

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
