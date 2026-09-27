---
name: nix-workflow
description: Choose Nix commands, locate store paths and libraries, use development shells, debug builds, configure Nix and navigate ecosystem tools.
---

# Nix workflow

Establish the context before advising. Read the repository's own instructions.
Check `nix --version`, since Nix, Lix and Determinate Nix differ. Check whether
`nix-command` and `flakes` are enabled (`nix config show experimental-features`),
and whether the project pins inputs with a flake, npins, niv or channels.
Advice that fits one of these can be wrong for another.

## Rules

1. **Never search `/nix/store` by brute force.** A `find` or `ls` over the store
   only sees what happens to be built locally. It misses everything else, and a
   path copied from it breaks as soon as the store changes. Use `nix-locate` to
   find which package provides a file. Use store queries (`nix path-info`,
   `nix why-depends`) for dependencies. Refer to libraries through Nix
   expressions such as `${pkgs.openssl.out}/lib` or `lib.makeLibraryPath`,
   never through literal store paths.
2. **Use the right environment.**
   - For a project, use its `devShells` output with `nix develop`.
   - For a tool the user needs for a moment, use `nix shell nixpkgs#tool`.
   - For one program, use `nix run`.
   - Do not install into the user's profile or system to satisfy one project.
3. **Search before inventing.** When a build or package fails:
   - Read the full log with `nix log`.
   - Search NixOS/nixpkgs issues and pull requests for the distinctive error
     text.
   - Report what you found, with numbers, before proposing a workaround.

   Do not disable the sandbox, checks or hardening to make an error disappear.
4. **Use the smallest adequate tool.** Inspect and transform data with `jq`,
   `awk`, `sed`, `grep` and `nix` subcommands such as `nix eval --json` and
   `nix derivation show`. Write Python or another script only when the logic
   needs it.
5. **Know where a setting lives.** Nix settings belong to the client, the
   daemon or a remote builder. Some take effect only for trusted users. On
   NixOS, nix-darwin and Home Manager, Nix configuration is declarative, and
   generated files are not edited by hand. Do not edit `nix.conf`, add trusted
   users or substituters, collect garbage, or switch a system without the
   user's explicit authorization. Propose the change instead.
6. **Treat ecosystem facts as perishable.** Tools and lang2nix projects are
   archived, renamed or replaced often. Before recommending one, check its
   upstream repository for its status and any successor. Prefer the Nixpkgs
   language builders first.

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

## References

- [Finding things](references/finding-things.md): which package provides a
  file, store and dependency queries, and referring to libraries from Nix.
- [Shells](references/shells.md): `nix develop`, `nix shell`, `nix run`,
  defining devShells, direnv, and project versus host tools.
- [Troubleshooting](references/troubleshooting.md): evaluation versus build
  errors, reading logs, and searching Nixpkgs issues, pull requests and Hydra.
- [Configuration](references/configuration.md): settings precedence, the
  client and daemon, trusted users, caches, remote builders and declarative
  owners.
- [Ecosystem](references/ecosystem.md): helper tools, pinning, flake
  frameworks, Nix implementations and lang2nix status.

## Other skills by role

These skills belong to the same collection, but may not all be installed. If
one is missing, use the linked upstream documentation instead.

| Role | Typical need | Use |
|---|---|---|
| Developer | Project environment, expressions | This skill for shells; `devenv-project` for devenv ([devenv.sh](https://devenv.sh/)); `nix-language` for the language ([Nix manual](https://nix.dev/manual/nix/latest/language/)) |
| Packager | Derivations, overrides, overlays | `nixpkgs-development` ([Nixpkgs manual](https://nixos.org/manual/nixpkgs/unstable/)) |
| Home Manager user, including darwin | User configuration | `home-manager` ([Home Manager manual](https://nix-community.github.io/home-manager/)) |
| macOS system administrator | nix-darwin system configuration | `nix-darwin` ([nix-darwin](https://github.com/nix-darwin/nix-darwin)) |
| NixOS administrator | System configuration and rebuilds | `nixos-operations` for rebuilds, generations, upgrades, store cleaning, boot and services; `nixos-wiki` for community guidance ([NixOS manual](https://nixos.org/manual/nixos/stable/), [NixOS Wiki](https://wiki.nixos.org/)) |
| AI coding agent user | Choosing, installing and sandboxing coding agents | `nixos-coding-agents` ([llm-agents.nix](https://github.com/numtide/llm-agents.nix), [agent-images](https://github.com/nothingnesses/agent-images), [agent-box](https://github.com/0xferrous/agent-box)) |
| VM user | Declarative microVMs | `microvm-nix` ([microvm.nix](https://microvm-nix.github.io/microvm.nix/)) |

Report what you actually ran, which commands only evaluated and which built
or changed anything, and which advice you could not verify on the user's
version.
