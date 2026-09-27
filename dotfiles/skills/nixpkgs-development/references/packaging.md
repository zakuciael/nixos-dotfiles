# Packaging

Nixpkgs master snapshot `4593931c855e7cf2ab412b659dd2841030f753df`; development series 26.11.

Modified excerpts from the Nixpkgs contributors; see [COPYING](../COPYING). Source citations are pinned; public manual links may move.

- [Using `stdenv`](#sec-using-stdenv)
- [Overview](#ssec-stdenv-dependencies-overview)
- [Fixed-point arguments of `mkDerivation`](#mkderivation-recursive-attributes)
- [`phases`](#var-stdenv-phases)
- [The check phase](#ssec-check-phase)
- [`doCheck`](#var-stdenv-doCheck)
- [The install phase](#ssec-install-phase)
- [`runHook` \<hook\>](#fun-runHook)
- [`substitute` \<infile\> \<outfile\> \<subs\>](#fun-substitute)
- [`substituteInPlace` \<multiple files\> \<subs\>](#fun-substituteInPlace)
- [Package setup hooks](#ssec-setup-hooks)
- [`description`](#var-meta-description)
- [`license`](#var-meta-license)
- [`maintainers`](#var-meta-maintainers)
- [`mainProgram`](#var-meta-mainProgram)
- [`platforms`](#var-meta-platforms)
- [Package tests](#var-passthru-tests-packages)


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md)


## Using `stdenv`

<a id="sec-using-stdenv"></a>

To build a package with the standard environment, you use the function `stdenv.mkDerivation`, instead of the primitive built-in function `derivation`, e.g.

```nix
stdenv.mkDerivation {
  name = "libfoo-1.2.3";
  src = fetchurl {
    url = "http://example.org/libfoo-1.2.3.tar.bz2";
    hash = "sha256-tWxU/LANbQE32my+9AXyt3nCT7NBVfJ45CX757EMT3Q=";
  };
}
```

(`stdenv` needs to be in scope, so if you write this in a separate Nix expression from `pkgs/all-packages.nix`, you need to pass it as a function argument.) Specifying a `name` and a `src` is the absolute minimum Nix requires. For convenience, you can also use `pname` and `version` attributes and `mkDerivation` will automatically set `name` to `"${pname}-${version}"` by default.
**Since [RFC 0035](https://github.com/NixOS/rfcs/pull/35), this is preferred for packages in Nixpkgs**, as it allows us to reuse the version easily:

```nix
stdenv.mkDerivation (finalAttrs: {
  pname = "libfoo";
  version = "1.2.3";
  src = fetchurl {
    url = "http://example.org/libfoo-source-${finalAttrs.version}.tar.bz2";
    hash = "sha256-tWxU/LANbQE32my+9AXyt3nCT7NBVfJ45CX757EMT3Q=";
  };
})
```

Many packages have dependencies that are not provided in the standard environment. It’s usually sufficient to specify those dependencies in the `buildInputs` attribute:

```nix
stdenv.mkDerivation {
  pname = "libfoo";
  version = "1.2.3";
  # ...
  buildInputs = [
    libbar
    perl
    ncurses
  ];
}
```

This attribute ensures that the `bin` subdirectories of these packages appear in the `PATH` environment variable during the build, that their `include` subdirectories are searched by the C compiler, and so on. (See [Package setup hooks](packaging.md#ssec-setup-hooks) for details.)

Often it is necessary to override or modify some aspect of the build. To make this easier, the standard environment breaks the package build into a number of *phases*, all of which can be overridden or modified individually: unpacking the sources, applying patches, configuring, building, and installing. (There are some others; see [Phases](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md) (source section: Phases).) For instance, a package that doesn’t supply a makefile but instead has to be compiled "manually" could be handled like this:

```nix
stdenv.mkDerivation {
  pname = "fnord";
  version = "4.5";

  # ...

  buildPhase = ''
    runHook preBuild

    gcc foo.c -o foo

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp foo $out/bin

    runHook postInstall
  '';
}
```

(Note the use of `''`-style string literals, which are very convenient for large multi-line script fragments because they don’t need escaping of `"` and `\`, and because indentation is intelligently removed.)

There are many other attributes to customise the build. These are listed in [Attributes](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md) (source section: Attributes).

While the standard environment provides a generic builder, you can still supply your own build script:

```nix
stdenv.mkDerivation {
  pname = "libfoo";
  version = "1.2.3";
  # ...
  builder = ./builder.sh;
}
```

where `stdenv` sets up the environment automatically (e.g. by resetting `PATH` and populating it from build inputs). If you want, you can use `stdenv`’s generic builder:

```bash
buildPhase() {
  echo "... this is my custom build phase ..."
  gcc foo.c -o foo
}

installPhase() {
  mkdir -p $out/bin
  cp foo $out/bin
}

genericBuild
```


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md)


### Overview

<a id="ssec-stdenv-dependencies-overview"></a>

A full reference of the different kinds of dependencies is provided in [Reference](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md) (source section: Reference), but here is an overview of the most common ones.
It should cover most use cases.

Add dependencies to `nativeBuildInputs` if they are executed during the build:
- those which are needed on `$PATH` during the build, for example `cmake` and `pkg-config`
- [setup hooks](packaging.md#ssec-setup-hooks), for example [`makeWrapper`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md) (source section: `makeWrapper` \<executable\> \<wrapperfile\> \<args\>)
- interpreters needed by [`patchShebangs`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md) (source section: `patch-shebangs.sh`) for build scripts (with the `--build` flag), which can be the case for e.g. `perl`

Add dependencies to `buildInputs` if they will end up copied or linked into the final output or otherwise used at runtime:
- libraries used by compilers, for example `zlib`,
- interpreters needed by [`patchShebangs`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md) (source section: `patch-shebangs.sh`) for scripts which are installed, which can be the case for e.g. `perl`

**Note**

These criteria are independent.

For example, software using Wayland usually needs the `wayland` library at runtime, so `wayland` should be added to `buildInputs`.
But it also executes the `wayland-scanner` program as part of the build to generate code, so `wayland` should also be added to `nativeBuildInputs`.

**End note.**


Dependencies needed only to run tests are similarly classified between native (executed during build) and non-native (executed at runtime):
- `nativeCheckInputs` for test tools needed on `$PATH` (such as `ctest`) and [setup hooks](packaging.md#ssec-setup-hooks) (for example [`pytestCheckHook`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/languages-frameworks/python.section.md) (source section: Python))
- `checkInputs` for libraries linked into test executables (for example the `qcheck` OCaml package)

These dependencies are only injected when [`doCheck`](packaging.md#var-stdenv-doCheck) is set to `true`.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md)


### Fixed-point arguments of `mkDerivation`

<a id="mkderivation-recursive-attributes"></a>

If you pass a function to `mkDerivation`, it will call the function with an argument that represents the final state of the package: the return value of the function itself, with any overrides applied, as the function is reinvoked by any `overrideAttrs` calls. For example:

```nix
mkDerivation (finalAttrs: {
  pname = "hello";
  withFeature = true;
  configureFlags = lib.optionals finalAttrs.withFeature [ "--with-feature" ];
})
```

Note that this does not use the `rec` keyword to reuse `withFeature` in `configureFlags`.
The `rec` keyword works at the syntax level and is unaware of overriding.

Instead, the definition references `finalAttrs`, allowing users to change `withFeature`
consistently with `overrideAttrs`.

`finalAttrs` also contains the attribute `finalPackage`, which includes the output paths, etc.

Let's look at a more elaborate example to understand the differences between
various bindings:

```nix
# `pkg` is the _original_ definition (for illustration purposes)
let
  pkg = mkDerivation (finalAttrs: {
    # ...

    # An example attribute
    packages = [ ];

    # `passthru.tests` is a commonly defined attribute.
    passthru.tests.simple = f finalAttrs.finalPackage;

    # An example of an attribute containing a function
    passthru.appendPackages =
      packages':
      finalAttrs.finalPackage.overrideAttrs (newSelf: super: { packages = super.packages ++ packages'; });

    # For illustration purposes; referenced as
    # `(pkg.overrideAttrs(x)).finalAttrs` etc in the text below.
    passthru.finalAttrs = finalAttrs;
    passthru.original = pkg;
  });
in
pkg
```

Unlike the `pkg` binding in the above example, the `finalAttrs` parameter always references the final attributes. For instance `(pkg.overrideAttrs(x)).finalAttrs.finalPackage` is identical to `pkg.overrideAttrs(x)`, whereas `(pkg.overrideAttrs(x)).original` is the same as the original `pkg`.

See also the section about [`passthru.tests`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/passthru.chapter.md) (source section: `passthru.tests`).


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md)


##### `phases`

<a id="var-stdenv-phases"></a>

Specifies the phases. You can change the order in which phases are executed, or add new phases, by setting this variable. If it’s not set, the default value is used, which is `$prePhases unpackPhase patchPhase $preConfigurePhases configurePhase $preBuildPhases buildPhase checkPhase $preInstallPhases installPhase fixupPhase installCheckPhase $preDistPhases distPhase $postPhases`.

The elements of `phases` must not contain spaces. If `phases` is specified as a Nix Language attribute, it should be specified as lists instead of strings. The same rules apply to the `*Phases` variables.

It is discouraged to set this variable, as it is easy to miss some important functionality hidden in some of the less obviously needed phases (like `fixupPhase` which patches the shebang of scripts).
Usually, if you just want to add a few phases, it’s more convenient to set one of the `*Phases` variables below.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md)


### The check phase

<a id="ssec-check-phase"></a>

The check phase checks whether the package was built correctly by running its test suite. The default `checkPhase` calls `make $checkTarget`, but only if the [`doCheck` variable](packaging.md#var-stdenv-doCheck) is enabled.

It is highly recommended, for packages' sources that are not distributed with any tests, to at least use [`versionCheckHook`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/hooks/versionCheckHook.section.md) (source section: versionCheckHook) to test that the resulting executable is basically functional.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md)


##### `doCheck`

<a id="var-stdenv-doCheck"></a>

Controls whether the check phase is executed. By default it is skipped, but if `doCheck` is set to true, the check phase is usually executed. Thus you should set

```nix
{ doCheck = true; }
```

in the derivation to enable checks. The exception is cross compilation. Cross compiled builds never run tests, no matter how `doCheck` is set, as the newly-built program won’t run on the platform used to build it.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md)


### The install phase

<a id="ssec-install-phase"></a>

The install phase is responsible for installing the package in the Nix store under `out`. The default `installPhase` creates the directory `$out` and calls `make install`.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md)


### `runHook` \<hook\>

<a id="fun-runHook"></a>

Execute \<hook\> and the values in the array associated with it. The array's name is determined by removing `Hook` from the end of \<hook\> and appending `Hooks`.

For example, `runHook postHook` would run the hook `postHook` and all of the values contained in the `postHooks` array, if it exists.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md)


### `substitute` \<infile\> \<outfile\> \<subs\>

<a id="fun-substitute"></a>

Performs string substitution on the contents of \<infile\>, writing the result to \<outfile\>. The substitutions in \<subs\> are of the following form:


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md)


### `substituteInPlace` \<multiple files\> \<subs\>

<a id="fun-substituteInPlace"></a>

Like `substitute`, but performs the substitutions in place on the files passed.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md)


## Package setup hooks

<a id="ssec-setup-hooks"></a>

Nix itself considers a build-time dependency as merely something that should previously be built and accessible at build time—packages themselves are on their own to perform any additional setup. In most cases, that is fine, and the downstream derivation can deal with its own dependencies. But for a few common tasks, that would result in almost every package doing the same sort of setup work—depending not on the package itself, but entirely on which dependencies were used.

To alleviate this burden, the setup hook mechanism was written, where any package can include a shell script that \[by convention rather than enforcement by Nix\], any downstream reverse-dependency will source as part of its build process. That allows the downstream dependency to merely specify its dependencies, and lets those dependencies effectively initialize themselves. No boilerplate mirroring the list of dependencies is needed.

The setup hook mechanism is a bit of a sledgehammer though: a powerful feature with a broad and indiscriminate area of effect. The combination of its power and implicit use may be expedient, but isn’t without costs. Nix itself is unchanged, but the spirit of added dependencies being effect-free is violated even if the latter isn’t. For example, if a derivation path is mentioned more than once, Nix itself doesn’t care and makes sure the dependency derivation is already built just the same—depending is just needing something to exist, and needing is idempotent. However, a dependency specified twice will have its setup hook run twice, and that could easily change the build environment (though a well-written setup hook will therefore strive to be idempotent so this is in fact not observable). More broadly, setup hooks are anti-modular in that multiple dependencies, whether the same or different, should not interfere and yet their setup hooks may well do so.

The most typical use of the setup hook is actually to add other hooks which are then run (i.e. after all the setup hooks) on each dependency. For example, the C compiler wrapper’s setup hook feeds itself flags for each dependency that contains relevant libraries and headers. This is done by defining a bash function, and appending its name to one of `envBuildBuildHooks`, `envBuildHostHooks`, `envBuildTargetHooks`, `envHostHostHooks`, `envHostTargetHooks`, or `envTargetTargetHooks`. These 6 bash variables correspond to the 6 sorts of dependencies by platform (there’s 12 total but we ignore the propagated/non-propagated axis).

Packages adding a hook should not hard code a specific hook, but rather choose a variable *relative* to how they are included. Returning to the C compiler wrapper example, if the wrapper itself is an `n` dependency, then it only wants to accumulate flags from `n + 1` dependencies, as only those ones match the compiler’s target platform. The `hostOffset` variable is defined with the current dependency’s host offset `targetOffset` with its target offset, before its setup hook is sourced. Additionally, since most environment hooks don’t care about the target platform, that means the setup hook can append to the right bash array by doing something like

```bash
addEnvHooks "$hostOffset" myBashFunction
```

The *existence* of setups hooks has long been documented and packages inside Nixpkgs are free to use this mechanism. Other packages, however, should not rely on these mechanisms not changing between Nixpkgs versions. Because of the existing issues with this system, there’s little benefit from mandating it be stable for any period of time.

First, let’s cover some setup hooks that are part of Nixpkgs default `stdenv`. This means that they are run for every package built using `stdenv.mkDerivation`, even with custom builders. Some of these are platform specific, so they may run on Linux but not Darwin or vice-versa.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/meta.chapter.md)


### `description`

<a id="var-meta-description"></a>

A short (one-line) description of the package.
This is displayed on [search.nixos.org](https://search.nixos.org/packages).

The general requirements of a description are:

- Be short, just one sentence.
- Be capitalized.
- Not start with definite ("The") or indefinite ("A"/"An") article.
- Not start with the package name.
  - More generally, it should not refer to the package name.
- Not end with a period (or any punctuation for that matter).
- Provide factual information.
  - Avoid subjective language.


Wrong: `"libpng is a library that allows you to decode PNG images."`

Right: `"Library for decoding PNG images"`


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/meta.chapter.md)


### `license`

<a id="var-meta-license"></a>

The license, or licenses, for the package. One from the attribute set defined in [`nixpkgs/lib/licenses/licenses.nix`](https://github.com/NixOS/nixpkgs/blob/master/lib/licenses/licenses.nix). At this moment using both a list of licenses and a single license is valid. If the license field is in the form of a list representation, then it means that parts of the package are licensed differently. Each license should preferably be referenced by their attribute. The non-list attribute value can also be a space delimited string representation of the contained attribute `shortNames` or `spdxIds`. The following are all valid examples:

- Single license referenced by attribute (preferred) `lib.licenses.gpl3Only`.
- Single license referenced by its attribute shortName (frowned upon) `"gpl3Only"`.
- Single license referenced by its attribute spdxId (frowned upon) `"GPL-3.0-only"`.
- Multiple licenses referenced by attribute (preferred) `with lib.licenses; [ asl20 free ofl ]`.
- Multiple licenses referenced as a space delimited string of attribute shortNames (frowned upon) `"asl20 free ofl"`.

For details, see [Licenses](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/meta.chapter.md) (source section: Licenses).


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/meta.chapter.md)


### `maintainers`

<a id="var-meta-maintainers"></a>

A list of the maintainers of this Nix expression. Maintainers are defined in [`nixpkgs/maintainers/maintainer-list.nix`](https://github.com/NixOS/nixpkgs/blob/master/maintainers/maintainer-list.nix). There is no restriction to becoming a maintainer, just add yourself to that list in a separate commit titled “maintainers: add alice” in the same pull request, and reference maintainers with `maintainers = with lib.maintainers; [ alice bob ]`.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/meta.chapter.md)


### `mainProgram`

<a id="var-meta-mainProgram"></a>

The name of the main binary for the package. This affects the binary `nix run` executes. Example: `"rg"`


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/meta.chapter.md)


### `platforms`

<a id="var-meta-platforms"></a>

The list of Nix platform types on which the package is supported. Hydra builds packages according to the platform specified. If no platform is specified, the package does not have prebuilt binaries. An example is:

```nix
{ meta.platforms = lib.platforms.linux; }
```

Attribute Set `lib.platforms` defines [various common lists](https://github.com/NixOS/nixpkgs/blob/master/lib/systems/doubles.nix) of platforms types.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/passthru.chapter.md)

**Note**

`passthru` attributes follow no particular schema, but there are a few [conventional patterns](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/passthru.chapter.md) (source section: Common `passthru`-attributes).

**End note.**


**Note**

The Nixpkgs systems for continuous integration [Hydra](https://hydra.nixos.org/) and [`nixpkgs-review`](https://github.com/Mic92/nixpkgs-review) don't build these derivations by default, and ([`@ofborg`](https://github.com/NixOS/ofborg)) only builds them when evaluating pull requests for that particular package, or when manually instructed.

**End note.**


#### Package tests

<a id="var-passthru-tests-packages"></a>
<a id="var-meta-tests-packages"></a>

Besides tests provided by upstream, that you run in the [`checkPhase`](packaging.md#ssec-check-phase), you may want to define tests derivations in the `passthru.tests` attribute, which won't change the build. `passthru.tests` have several advantages over running tests during any of the [standard phases](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md) (source section: Phases):

- They access the package as consumers would, independently from the environment in which it was built
- They can be run and debugged without rebuilding the package, which is useful if that takes a long time
- They don't add overhead to each build, as opposed checks added to the [`installCheckPhase`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md) (source section: The installCheck phase), such as [`versionCheckHook`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/hooks/versionCheckHook.section.md) (source section: versionCheckHook).

It is also possible to use `passthru.tests` to test the version with [`testVersion`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/testers.chapter.md) (source section: `testVersion`), but since that is a pretty trivial and recommended thing to do, we recommend using [`versionCheckHook`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/hooks/versionCheckHook.section.md) (source section: versionCheckHook) for that, which has the following advantages over `passthru.tests`:

- If the `versionCheckPhase` (the phase defined by [`versionCheckHook`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/hooks/versionCheckHook.section.md) (source section: versionCheckHook)) fails, it triggers a failure which can't be ignored if you use the package, or if you find out about it in a [`nixpkgs-review`](https://github.com/Mic92/nixpkgs-review) report.
- Sometimes packages become silently broken - meaning they fail to launch but their build passes because they don't perform any tests in the `checkPhase`. If you use this tool infrequently, such a silent breakage may rot in your system / profile configuration, and you will not notice the failure until you will want to use this package. Testing such basic functionality ensures you have to deal with the failure when you update your system / profile.
- When you open a PR, [ofborg](https://github.com/NixOS/ofborg)'s CI _will_ run `passthru.tests` of [packages that are directly changed by your PR (according to your commits' messages)](https://github.com/NixOS/ofborg?tab=readme-ov-file#automatic-building), but if you'd want to use the [`@ofborg build`](https://github.com/NixOS/ofborg?tab=readme-ov-file#build) command for dependent packages, you won't have to specify in addition the `.tests` attribute of the packages you want to build, and nobody will be able to avoid these tests.


For more on how to write and run package tests for Nixpkgs, see the [testing section in the package contributor guide](https://github.com/NixOS/nixpkgs/blob/master/pkgs/README.md#package-tests).
