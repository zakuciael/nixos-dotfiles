---
name: home-manager
description: Configure and troubleshoot Home Manager user environments on NixOS, nix-darwin or standalone Linux and macOS installations.
---

# Home Manager

Read the repository instructions, flake inputs, target host, imports, and
existing Home Manager modules before editing. Preserve the project's module
and feature-flag conventions.

## Find the installation mode first

How Home Manager is installed decides which instructions apply and how
changes take effect:

| Mode | Signs | Reference | Changes are applied by |
|---|---|---|---|
| NixOS module | `home-manager.nixosModules` imported and `home-manager.users.<name>` in a NixOS configuration | [NixOS module](references/nixos.md) | The host's NixOS rebuild workflow |
| nix-darwin module | `home-manager.darwinModules` imported and `home-manager.users.<name>` in a `darwinConfigurations` entry | [installation](references/install-nix-darwin.md), [flakes](references/flake-nix-darwin.md) | `darwin-rebuild` |
| Standalone | A `homeConfigurations` flake output, or `~/.config/home-manager/home.nix`, and the `home-manager` command | [installation](references/install-standalone.md), [flakes](references/flake-standalone.md) | `home-manager switch` |

If the signs are ambiguous, ask rather than guess. A standalone example is not
a reason to change a module-based setup, or the reverse. For nix-darwin
itself, use the `nix-darwin` skill if it is installed, or the
[nix-darwin documentation](https://github.com/nix-darwin/nix-darwin).

## Configure

Use [configuration](references/configuration.md) for user settings and
package placement, [dotfiles](references/dotfiles.md) for managed files,
[modular services](references/modular-services.md) for service modules, and
[writing modules](references/writing-modules.md) when extending Home Manager.

Keep `home.stateVersion` stable unless deliberately performing a migration.
Prefer existing `programs`, `services`, `home.packages`, `home.file`, and
`xdg.configFile` options over custom generation.

## Apply, update and roll back

Apply changes through the system manager that owns Home Manager in this mode.
That is the NixOS or nix-darwin rebuild for module installs, and never
`home-manager switch` for them. See [updating](references/updating.md) and
[rollbacks](references/rollbacks.md).

Switching, rolling back, expiring generations and updating inputs change the
user's environment. Propose them with the exact command, and run them only
with the user's authorization.

Check the user's actual Home Manager revision before relying on version-
specific options. Validate the flake and use a dry build before deployment.

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
