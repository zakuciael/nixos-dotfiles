# Customization

Nixpkgs master snapshot `4593931c855e7cf2ab412b659dd2841030f753df`; development series 26.11.

Modified excerpts from the Nixpkgs contributors; see [COPYING](../COPYING). Source citations are pinned; public manual links may move.

- [&lt;pkg&gt;.override](#sec-pkg-override)
- [&lt;pkg&gt;.overrideAttrs](#sec-pkg-overrideAttrs)
- [&lt;pkg&gt;.overrideDerivation](#sec-pkg-overrideDerivation)
- [Set overlays in NixOS or Nix expressions](#sec-overlays-argument)
- [Defining overlays](#sec-overlays-definition)
- [Introduction](#module-system-introduction)
- [`lib.evalModules`](#module-system-lib-evalModules)
- [`modules`](#module-system-lib-evalModules-param-modules)
- [`specialArgs`](#module-system-lib-evalModules-param-specialArgs)
- [`options`](#module-system-lib-evalModules-return-value-options)
- [`config`](#module-system-lib-evalModules-return-value-config)


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/using/overrides.chapter.md)


## &lt;pkg&gt;.override

<a id="sec-pkg-override"></a>

The function `override` is usually available for all the derivations in the nixpkgs expression (`pkgs`).

It is used to override the arguments passed to a function.

Example usages:

```nix
pkgs.foo.override {
  arg1 = val1;
  arg2 = val2; # ...
}
```

It's also possible to access the previous arguments.

```nix
pkgs.foo.override (previous: {
  arg1 = previous.arg1; # ...
})
```



```nix
import pkgs.path {
  overlays = [ (self: super: { foo = super.foo.override { barSupport = true; }; }) ];
}
```

```nix
{
  mypkg = pkgs.callPackage ./mypkg.nix {
    mydep = pkgs.mydep.override {
      # ...
    };
  };
}
```

In the first example, `pkgs.foo` is the result of a function call with some default arguments, usually a derivation. Using `pkgs.foo.override` will call the same function with the given new arguments.

Many packages, like the `foo` example above, provide package options with default values in their arguments, to facilitate overriding.
Because it's not usually feasible to test that packages build with all combinations of options, you might find that a package doesn't build if you override options to non-default values.

Package maintainers are not expected to fix arbitrary combinations of options.
If you find that something doesn't work, please submit a fix, ideally with a regression test.
If you want to ensure that things keep working, consider [becoming a maintainer](https://github.com/NixOS/nixpkgs/tree/master/maintainers) for the package.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/using/overrides.chapter.md)


## &lt;pkg&gt;.overrideAttrs

<a id="sec-pkg-overrideAttrs"></a>

The function `overrideAttrs` allows overriding the attribute set passed to a `stdenv.mkDerivation` call, producing a new derivation based on the original one. This function is available on all derivations produced by the `stdenv.mkDerivation` function, which is most packages in the Nixpkgs expression `pkgs`.

Example usages:

```nix
{
  helloBar = pkgs.hello.overrideAttrs (
    finalAttrs: previousAttrs: { pname = previousAttrs.pname + "-bar"; }
  );
}
```

In the above example, "-bar" is appended to the pname attribute, while all other attributes will be retained from the original `hello` package.

The argument `previousAttrs` is conventionally used to refer to the attr set originally passed to `stdenv.mkDerivation`.

The argument `finalAttrs` refers to the final attributes passed to `mkDerivation`, plus the `finalPackage` attribute which is equal to the result of `mkDerivation` or subsequent `overrideAttrs` calls.

If only a one-argument function is written, the argument has the meaning of `previousAttrs`.

Function arguments can be omitted entirely if there is no need to access `previousAttrs` or `finalAttrs`.

```nix
{ helloWithDebug = pkgs.hello.overrideAttrs { separateDebugInfo = true; }; }
```

In the above example, the `separateDebugInfo` attribute is overridden to be true, thus building debug info for `helloWithDebug`.

**Note**

Note that `separateDebugInfo` is processed only by the `stdenv.mkDerivation` function, not the generated, raw Nix derivation. Thus, using `overrideDerivation` will not work in this case, as it overrides only the attributes of the final derivation. It is for this reason that `overrideAttrs` should be preferred in (almost) all cases to `overrideDerivation`, i.e. to allow using `stdenv.mkDerivation` to process input arguments, as well as the fact that it is easier to use (you can use the same attribute names you see in your Nix code, instead of the ones generated (e.g. `buildInputs` vs `nativeBuildInputs`), and it involves less typing).

**End note.**



[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/using/overrides.chapter.md)


## &lt;pkg&gt;.overrideDerivation

<a id="sec-pkg-overrideDerivation"></a>

**Warning**

You should prefer `overrideAttrs` in almost all cases, see its documentation for the reasons why. `overrideDerivation` is not deprecated and will continue to work, but is less nice to use and does not have as many abilities as `overrideAttrs`.

**End warning.**


**Warning**

Do not use this function in Nixpkgs as it evaluates a derivation before modifying it, which breaks package abstraction. In addition, this evaluation-per-function application incurs a performance penalty, which can become a problem if many overrides are used. It is only intended for ad-hoc customisation, such as in `~/.config/nixpkgs/config.nix`.

**End warning.**


The function `overrideDerivation` creates a new derivation based on an existing one by overriding the original's attributes with the attribute set produced by the specified function. This function is available on all derivations defined using the `makeOverridable` function. Most standard derivation-producing functions, such as `stdenv.mkDerivation`, are defined using this function, which means most packages in the Nixpkgs expression, `pkgs`, have this function.

Example usage:

```nix
{
  mySed = pkgs.gnused.overrideDerivation (oldAttrs: {
    name = "sed-4.2.2-pre";
    src = fetchurl {
      url = "ftp://alpha.gnu.org/gnu/sed/sed-4.2.2-pre.tar.bz2";
      hash = "sha256-MxBJRcM2rYzQYwJ5XKxhXTQByvSg5jZc5cSHEZoB2IY=";
    };
    patches = [ ];
  });
}
```

In the above example, the `name`, `src`, and `patches` of the derivation will be overridden, while all other attributes will be retained from the original derivation.

The argument `oldAttrs` is used to refer to the attribute set of the original derivation.

**Note**

A package's attributes are evaluated *before* being modified by the `overrideDerivation` function. For example, the `name` attribute reference in `url = "mirror://gnu/hello/${name}.tar.gz";` is filled-in *before* the `overrideDerivation` function modifies the attribute set. This means that overriding the `name` attribute, in this example, *will not* change the value of the `url` attribute. Instead, we need to override both the `name` *and* `url` attributes.

**End note.**



[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/using/overlays.chapter.md)


### Set overlays in NixOS or Nix expressions

<a id="sec-overlays-argument"></a>

On a NixOS system the value of the `nixpkgs.overlays` option, if present, is passed to the system Nixpkgs directly as an argument. Note that this does not affect the overlays for non-NixOS operations (e.g.  `nix-env`), which are [looked up](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/using/overlays.chapter.md) (source section: Install overlays via configuration lookup) independently.

The list of overlays can be passed explicitly when importing nixpkgs, for example `import <nixpkgs> { overlays = [ overlay1 overlay2 ]; }`.

NOTE: DO NOT USE THIS in nixpkgs. Further overlays can be added by calling the `pkgs.extend` or `pkgs.appendOverlays`, although it is often preferable to avoid these functions, because they recompute the Nixpkgs fixpoint, which is somewhat expensive to do.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/using/overlays.chapter.md)


## Defining overlays

<a id="sec-overlays-definition"></a>

Overlays are Nix functions which accept two arguments, conventionally called either `final` and `prev` in newer code or `self` and `super` in older code, and return a set of packages. For example, the following is a valid overlay.

```nix
final: prev:

{
  boost = prev.boost.override { python = final.python3; };
  rr = prev.callPackage ./pkgs/rr { stdenv = final.stdenv_32bit; };
}
```

The first argument (`final`, `self`) corresponds to the final package set. You should use this set for the dependencies of all packages specified in your overlay. For example, all the dependencies of `rr` in the example above come from `final`, as well as the overridden dependencies used in the `boost` override.

The second argument (`prev`, `super`) corresponds to the result of the evaluation of the previous stages of Nixpkgs. It does not contain any of the packages added by the current overlay, nor any of the following overlays. This set should be used either to refer to packages you wish to override, or to access functions defined in Nixpkgs. For example, the original recipe of `boost` in the above example, comes from `prev`, as well as the `callPackage` function.

The value returned by this function should be a set similar to `pkgs/top-level/all-packages.nix`, containing overridden and/or new packages.

Overlays are similar to other methods for customizing Nixpkgs, in particular the `packageOverrides` attribute described in [Modify packages via `packageOverrides`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/using/configuration.chapter.md) (source section: Modify packages via `packageOverrides`). Indeed, `packageOverrides` acts as an overlay with only the `prev` argument. It is therefore appropriate for basic use, but overlays are more powerful and easier to distribute.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/module-system/module-system.chapter.md)


## Introduction

<a id="module-system-introduction"></a>

The module system is a language for handling configuration, implemented as a Nix library.

Compared to plain Nix, it adds documentation, type checking and composition or extensibility.

**Note**

This chapter is new and not complete yet.

See also:
- Introduction to the module system, in the context of NixOS, see [Writing NixOS Modules](https://nixos.org/manual/nixos/unstable/index.html#sec-writing-modules) in the NixOS manual.
- Generic guide to the module system on [nix.dev](https://nix.dev/tutorials/module-system/index.html).

**End note.**



[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/module-system/module-system.chapter.md)


## `lib.evalModules`

<a id="module-system-lib-evalModules"></a>

Evaluate a set of modules. This function is typically only used once per application (e.g. once in NixOS, once in Home Manager, ...).


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/module-system/module-system.chapter.md)


#### `modules`

<a id="module-system-lib-evalModules-param-modules"></a>

A list of modules. These are merged together to form the final configuration.



[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/module-system/module-system.chapter.md)


#### `specialArgs`

<a id="module-system-lib-evalModules-param-specialArgs"></a>

An attribute set of module arguments that can be used in `imports`.

This is in contrast to `config._module.args`, which is only available after all `imports` have been resolved.

**Warning**

You may be tempted to use `specialArgs.lib` to provide extra library functions. Doing so limits the interoperability of modules, as well as the interoperability of Module System applications.

`lib` is reserved for the Nixpkgs library, and should not be used for custom functions.

Instead, you may create a new attribute in `specialArgs` to provide custom functions.
This clarifies their origin and avoids incompatibilities.

**End warning.**



[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/module-system/module-system.chapter.md)


#### `options`

<a id="module-system-lib-evalModules-return-value-options"></a>

The nested attribute set of all option declarations.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/module-system/module-system.chapter.md)


#### `config`

<a id="module-system-lib-evalModules-return-value-config"></a>

The nested attribute set of all option values.
