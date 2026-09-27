---
name: nixos-operations
description: Operate NixOS systems by choosing rebuild modes, managing generations and rollback, upgrading, cleaning the store, and diagnosing boot and service problems.
---

# NixOS operations

## Establish the setup first

Read the repository instructions and find out how the system is built:

- a flake with `nixosConfigurations.<host>`, or channels with
  `/etc/nixos/configuration.nix`;
- the NixOS release (`nixos-version`) and `system.stateVersion`;
- the host being changed.

The bundled [operations reference](references/operations.md) quotes the NixOS
manual at the Nixpkgs master snapshot in [sources.json](sources.json), not
necessarily the user's release. Check version-sensitive behaviour against the
user's release. Never treat the manual's examples as a reason to move a
system between channels and flakes.

## Rebuild modes

`nixos-rebuild` builds a configuration and optionally activates it. Add
`--flake .#HOST` for flake systems.

| Mode | Effect | Changes the running system |
|---|---|---|
| `dry-build` | Show what would be built or fetched | No |
| `build` | Build into `./result` | No |
| `dry-activate` | Build and show what activation would change | No |
| `test` | Activate now, but keep the previous boot default | Yes |
| `boot` | Make it the boot default, activating on next boot | Yes, at reboot |
| `switch` | Activate now and make it the boot default | Yes |

Start with `build` or `dry-activate` to validate a change. `test`, `boot`,
`switch`, `--rollback`, `--upgrade` and `--target-host` deployments change a
system. Propose them with the exact command, and run them only with the
user's authorization. The same applies to restarting services, deleting
generations, collecting garbage and changing boot entries.

## Generations, rollback and upgrades

`nixos-rebuild list-generations` lists system generations. For rollback and
boot-menu recovery, read *Rolling Back Configuration Changes*. For channel
upgrades and flake input updates, read *Upgrading NixOS*. Treat an upgrade as
a deliberate, reviewable change: update inputs separately from configuration
edits, and build before switching.

## Store cleaning, boot and services

- *Cleaning the Nix Store* explains garbage collection, and how deleting old
  generations removes rollback targets. Confirm which generations the user
  still needs first.
- *Boot Problems* covers kernel parameters and emergency shells.
- *Service Management* covers `systemctl` and `journalctl`. Reading status and
  logs is safe. Starting, stopping, restarting and enabling services change
  the system.

## Related skills

Use `home-manager` for user environments, `nixpkgs-development` for packaging,
`nixos-wiki` for community guidance, and `nix-workflow` for general Nix
command-line practice, if they are installed. Otherwise use the
[NixOS manual](https://nixos.org/manual/nixos/stable/).

Modified excerpts from the Nixpkgs contributors are covered by
[COPYING](COPYING).

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
