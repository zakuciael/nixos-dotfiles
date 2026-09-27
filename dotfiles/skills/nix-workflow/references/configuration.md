# Nix configuration: client, daemon and remote builders

## See the effective configuration first

```sh
nix config show                 # every setting as this client sees it
nix config show substituters    # one setting
nix store info                  # which store, its version, and whether you are trusted
```

`nix store info` is the current name. Older versions call it `nix store ping`,
which is now a deprecated alias.

Settings come from, in increasing priority:

1. the system file `/etc/nix/nix.conf`;
2. user files such as `~/.config/nix/nix.conf`;
3. the `NIX_CONFIG` environment variable;
4. command-line flags (`--option NAME VALUE`, or `--NAME VALUE` for many
   settings).

Some installers manage `/etc/nix/nix.conf` themselves and read local additions
from another file. Check the installer's documentation before editing.

## Client and daemon

On a multi-user installation, builds run in the Nix daemon, not in the
client that the user starts. A setting in the user's configuration reaches
the daemon only if the daemon accepts it:

- Users listed in the daemon's `trusted-users` can pass most settings,
  including new substituters. Being trusted is close to root access to the
  store, so treat adding a user as a security decision for the user or
  administrator.
- Untrusted users can only enable substituters that the daemon lists in
  `trusted-substituters`.
- A binary cache needs its signing key in `trusted-public-keys`. Otherwise
  paths from it are rejected. A missing key is a common reason why a cache
  seems to be ignored.

`nix store info` reports `Trusted: 1` or `0` for the current user.

## Remote builders

The `builders` setting, or the file `/etc/nix/machines`, lists remote
machines. Each entry gives a store URI (for example `ssh-ng://builder`), the
systems it builds for, an SSH key, the maximum number of jobs, a speed factor
and supported features. The daemon, not the user, connects to them, so it
needs its own SSH access. `builders-use-substitutes = true` lets builders
download dependencies from caches themselves.

Check that a builder is reachable with `nix store info --store ssh-ng://builder`.

## Declarative configuration

On these systems, the Nix configuration file is generated. Change the option
and apply the configuration, rather than editing the file:

- NixOS: `nix.settings` (for example `nix.settings.trusted-users`),
  `nix.buildMachines` and `nix.distributedBuilds`.
- nix-darwin: `nix.settings`, with the same shape.
- Home Manager: `nix.settings` writes the user's `nix.conf`.

Only apply them with the user's authorization. Applying a system
configuration, restarting the daemon, adding trusted users or substituters,
and collecting garbage all change shared state. Present them as a proposal
with the exact option or command.
