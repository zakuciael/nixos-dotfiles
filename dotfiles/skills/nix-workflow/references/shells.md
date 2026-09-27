# Development shells and one-off tools

## Choose the command

| Need | Command | What you get |
|---|---|---|
| The project's environment | `nix develop` | The `devShells.<system>.default` output: its packages, environment variables and `shellHook` |
| A named project shell | `nix develop .#name` | `devShells.<system>.name` |
| Run one command in the project environment | `nix develop --command make test` | The same environment, without an interactive shell |
| A tool for a moment | `nix shell nixpkgs#jq nixpkgs#yq-go` | Those packages' programs on `PATH`, nothing else |
| Run one program | `nix run nixpkgs#hello -- ARGS` | The package's main program, run once |
| A package's build environment | `nix develop nixpkgs#hello` | The environment its builder sees, for debugging a build |

`nix shell` only extends `PATH`. `nix develop` reproduces a derivation's build
environment, including variables set by setup hooks. That is why compilers
find headers and libraries in a `nix develop` shell, but not after
`nix shell`.

Add `--ignore-env` to either command to start from an empty environment. That
is a useful check that the shell does not depend on the host.

## Defining a devShell

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = [ pkgs.go pkgs.gopls ];
        # Reuse the build inputs of a package defined by this flake:
        # inputsFrom = [ self.packages.x86_64-linux.default ];
        shellHook = ''
          export GOFLAGS=-mod=mod
        '';
      };
    };
}
```

Read the existing flake before adding one. Many projects already define shells
for several systems, or through a framework such as flake-parts. Extend what
is there instead of replacing it.

## Projects without flakes

- A `shell.nix` or `default.nix` is entered with `nix-shell`.
- `nix-shell -p pkg` is the legacy form of `nix shell`.
- Projects pinned with npins or niv import their pinned Nixpkgs in these
  files, so do not replace that import with `<nixpkgs>`.

## Automatic activation

- **direnv:** runs `use flake` from `.envrc`. The
  [nix-direnv](https://github.com/nix-community/nix-direnv) extension caches
  the environment. Allowing a directory with `direnv allow` is the user's
  trust decision, so never run it for them.
- **devenv:** has its own `devenv.nix` files and activation, with separate
  trust. Use the `devenv-project` skill, or the
  [devenv documentation](https://devenv.sh/) if that skill is not installed.

## Project versus host

A project shell's tools come from the project's pinned inputs. Installing a
tool into the user profile (`nix profile add`, or `nix profile install` on
older versions) or into the system does not change what the project uses, and
it leaves state behind. Add the tool to the devShell instead. For a one-off
use, run `nix shell`.
