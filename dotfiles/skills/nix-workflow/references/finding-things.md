# Finding packages, files and dependencies

## Why not search the store

A command like this is the wrong tool:

<!-- nix-style: counterexample -->
```sh
find /nix/store/*something-* -iname libsomething.so
```

- It only sees paths that happen to exist on this machine. A package that was
  never built or downloaded is invisible, and garbage collection removes
  paths at any time.
- It cannot tell which of several matching paths belongs to the user's
  configuration or pin.
- A store path copied into a script or configuration breaks the next time the
  dependency changes.
- On a large store it is slow.

Ask the question Nix can answer instead: "which package provides this file?"
or "what does this path depend on?".

## Which package provides a file

`nix-locate` (from nix-index) searches an index of files in Nixpkgs, including
packages that are not installed:

```sh
nix-locate -w libssl.so.3          # match the whole file name
nix-locate --minimal -w libssl.so.3 # print only attribute names
nix-locate -r 'bin/rg$'            # regular expression over paths
```

It needs a database. If none exists, a prebuilt one from
[nix-index-database](https://github.com/nix-community/nix-index-database)
avoids indexing Nixpkgs locally. Running `nix-index` to build a database
downloads and processes a lot of data, so ask the user before starting it.
[comma](https://github.com/nix-community/comma) (`, command`) uses the same
database to run a program without installing it.

To find packages by name or description, use `nix search nixpkgs QUERY`, or
[search.nixos.org](https://search.nixos.org/packages), which also searches
NixOS options.

## Querying what exists

Once you have a store path or installable, these are read-only:

| Question | Command |
|---|---|
| Full runtime closure | `nix path-info -r INSTALLABLE` |
| Closure size | `nix path-info -S INSTALLABLE` |
| Direct references of a path | `nix-store -q --references PATH` |
| What refers to a path | `nix-store -q --referrers PATH` |
| Dependency tree | `nix-store -q --tree PATH` |
| Why A depends on B | `nix why-depends A B` (add `--precise` for the file and location) |
| The derivation behind an output | `nix-store -q --deriver PATH`, then `nix derivation show PATH` |
| GC roots keeping a path alive | `nix-store -q --roots PATH` |
| An attribute's value | `nix eval --json INSTALLABLE` |

## Referring to a library from Nix

Write the dependency into the expression, and let Nix supply the path:

```nix
{ lib, pkgs, ... }:
{
  # A directory inside a package output; lib.getLib picks the output with libraries.
  environment.variables.SSL_LIB_DIR = "${lib.getLib pkgs.openssl}/lib";
  # A search path for several libraries.
  environment.variables.LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.openssl pkgs.zlib ];
}
```

The example only shows how interpolation works. Setting `LD_LIBRARY_PATH`
globally is rarely the right fix. For packaging, use the build helpers in the
`nixpkgs-development` skill, for example `autoPatchelfHook` or
`makeWrapper`. To run a foreign prebuilt binary, follow the user's local
policy (for example `nix-ld`) instead of pointing it at a store path by hand.

## Worked example

The request: "The binary needs `libsomething.so`. Where is it?"

1. Run `nix-locate -w libsomething.so` to find the attribute, say
   `pkgs.something`.
2. Confirm the file is in the output you will reference:
   `nix path-info nixpkgs#something` and list its `lib/` directory.
3. Put `pkgs.something` in the expression that needs it (`buildInputs`, a
   wrapper, or a devShell `packages` list), not a copied `/nix/store/...`
   path.
4. If `nix-locate` is not available, say so, and propose installing the
   database or running `nix search`. Do not fall back to searching the store.
