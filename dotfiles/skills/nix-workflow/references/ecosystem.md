# Ecosystem map

Status was checked on 2026-09-23 against each project's repository. Verify it
again before recommending a tool: projects are archived, change maintainers or
gain successors. Tools the user already uses take precedence over this list.

## Build, rebuild and inspection helpers

| Tool | Use it for |
|---|---|
| [nh](https://github.com/nix-community/nh) | Friendlier rebuild, Home Manager and clean commands with a diff of changes (`nh os`, `nh home`, `nh clean`) |
| [nix-output-monitor](https://github.com/maralorn/nix-output-monitor) | Readable build progress: `nom build …`, or pipe logs to `nom` |
| [nvd](https://git.sr.ht/~khumba/nvd) | Package-version diff between two system generations or closures |
| [nix-diff](https://github.com/Gabriella439/nix-diff) | Why two derivations differ |
| [nix-tree](https://github.com/utdemir/nix-tree) | Browse a closure interactively and find what makes it large |
| [nix-eval-jobs](https://github.com/nix-community/nix-eval-jobs) | Evaluate many attributes in parallel, as CI does |
| [nix-fast-build](https://github.com/Mic92/nix-fast-build) | nix-eval-jobs and nom combined, for building all flake checks quickly |
| [nix-index](https://github.com/nix-community/nix-index), [nix-index-database](https://github.com/nix-community/nix-index-database), [comma](https://github.com/nix-community/comma) | Find the package that provides a file, and run it without installing |
| [nix-direnv](https://github.com/nix-community/nix-direnv) | Cached `use flake` for direnv |

## Pinning and project structure

| Approach | Use it for |
|---|---|
| Flakes (built into Nix, still an experimental feature) | Locked inputs and a standard output schema. Requires `flakes` and `nix-command` to be enabled |
| [npins](https://github.com/andir/npins) | Pinning without flakes. A newer alternative to niv |
| [niv](https://github.com/nmattia/niv) | Pinning without flakes, common in older projects |
| [flake-parts](https://github.com/hercules-ci/flake-parts) | Structuring a flake with the module system, for larger flakes |
| [flake-utils](https://github.com/numtide/flake-utils) | Small helpers such as `eachDefaultSystem`. Little recent activity (last push 2024-11); a plain `genAttrs` over systems needs no dependency |

Match the project's existing choice. Do not convert a project between flakes
and npins or niv, or add a framework, unless the user asks.

## Nix implementations

[Nix](https://github.com/NixOS/nix), [Lix](https://lix.systems/) and
[Determinate Nix](https://github.com/DeterminateSystems/nix-src) share the
language and most commands, but differ in defaults, enabled features and
some commands. Check `nix --version` before relying on a newer command or
setting.

## Language tooling (lang2nix)

Prefer the Nixpkgs builders for a language first (`buildGoModule`,
`buildRustPackage`, `buildPythonPackage`, `buildNpmPackage` and others). See
the `nixpkgs-development` skill, or the Nixpkgs manual. Use an external tool
when the project's lockfile or scale needs it.

| Ecosystem | Tool | Status on 2026-09-23 |
|---|---|---|
| Python | [uv2nix](https://github.com/pyproject-nix/uv2nix) | Active; builds from `uv.lock` |
| Python | [poetry2nix](https://github.com/nix-community/poetry2nix) | **Unmaintained** per its README; its author recommends uv and uv2nix |
| Rust | [crane](https://github.com/ipetkov/crane) | Active; incremental Cargo builds |
| Rust | [naersk](https://github.com/nix-community/naersk) | Maintained; simpler, fewer options |
| Go | [gomod2nix](https://github.com/nix-community/gomod2nix) | Maintained; consider `buildGoModule` first |
| JavaScript | [dream2nix](https://github.com/nix-community/dream2nix) | Active; multi-language framework |
| JavaScript | [node2nix](https://github.com/svanderburg/node2nix) | Little recent activity (last push 2024-11); prefer `buildNpmPackage` |
| Haskell | [haskell.nix](https://github.com/input-output-hk/haskell.nix) | Active; an alternative to the Nixpkgs Haskell infrastructure |
| Ruby | [bundix](https://github.com/nix-community/bundix) | Little recent activity (last push 2024-07); used with `bundlerEnv` |
| JVM | [gradle2nix](https://github.com/tadfisher/gradle2nix) | Last push 2025-08 |

"Active" means recent commits and no deprecation notice. It says nothing about
fitness for a particular project. Before recommending a tool, read its README
for a maintenance notice, and check its latest release or commit.
