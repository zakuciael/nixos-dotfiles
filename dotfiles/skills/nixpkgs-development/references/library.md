# Library

Nixpkgs master snapshot `4593931c855e7cf2ab412b659dd2841030f753df`; development series 26.11.

Modified excerpts from the Nixpkgs contributors; see [COPYING](../COPYING). Source citations are pinned; public manual links may move.

- [`lib.attrsets.attrByPath`](#function-library-lib.attrsets.attrByPath)
- [`lib.attrsets.mapAttrs`](#function-library-lib.attrsets.mapAttrs)
- [`lib.attrsets.mapAttrsToList`](#function-library-lib.attrsets.mapAttrsToList)
- [`lib.attrsets.optionalAttrs`](#function-library-lib.attrsets.optionalAttrs)
- [`lib.attrsets.recursiveUpdate`](#function-library-lib.attrsets.recursiveUpdate)
- [`lib.lists.optionals`](#function-library-lib.lists.optionals)
- [`lib.lists.unique`](#function-library-lib.lists.unique)
- [`lib.strings.escapeShellArg`](#function-library-lib.strings.escapeShellArg)
- [`lib.strings.concatMapStringsSep`](#function-library-lib.strings.concatMapStringsSep)
- [`lib.customisation.callPackageWith`](#function-library-lib.customisation.callPackageWith)
- [`lib.fixedPoints.composeExtensions`](#function-library-lib.fixedPoints.composeExtensions)
- [`lib.fileset.toSource`](#function-library-lib.fileset.toSource)


[Declaration](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/attrsets.nix#L88)


## `lib.attrsets.attrByPath`

<a id="function-library-lib.attrsets.attrByPath"></a>

Returns an attribute from nested attribute sets.

Nix has an [attribute selection operator `.`](https://nixos.org/manual/nix/stable/language/operators#attribute-selection) which is sufficient for such queries, as long as the number of attributes is static. For example:

```nix
(x.a.b or 6) == attrByPath ["a" "b"] 6 x
# and
(x.${f p}."example.com" or 6) == attrByPath [ (f p) "example.com" ] 6 x
```

# Inputs

`attrPath`

Definition: A list of strings representing the attribute path to return from `set`

`default`

Definition: Default value if `attrPath` does not resolve to an existing value

`set`

Definition: The nested attribute set to select values from

# Type

```
attrByPath :: [String] -> Any -> AttrSet -> Any
```

# Examples
**Example**

## `lib.attrsets.attrByPath` usage example

```nix
x = { a = { b = 3; }; }
# ["a" "b"] is equivalent to x.a.b
# 6 is a default value to return if the path does not exist in attrset
attrByPath ["a" "b"] 6 x
=> 3
attrByPath ["z" "z"] 6 x
=> 6
```


**End example.**



[Declaration](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/attrsets.nix#L1023)


## `lib.attrsets.mapAttrs`

<a id="function-library-lib.attrsets.mapAttrs"></a>

Apply a function to each element in an attribute set, creating a new attribute set.

# Inputs

`f`

Definition: A function that takes an attribute name and its value, and returns the new value for the attribute.

`attrset`

Definition: The attribute set to iterate through.

# Type

```
mapAttrs :: (String -> a -> b) -> { [String] :: a } -> { [String] :: b }
```

# Examples
**Example**

## `lib.attrsets.mapAttrs` usage example

```nix
mapAttrs (name: value: name + "-" + value)
   { x = "foo"; y = "bar"; }
=> { x = "x-foo"; y = "y-bar"; }
```


**End example.**



[Declaration](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/attrsets.nix#L1092)


## `lib.attrsets.mapAttrsToList`

<a id="function-library-lib.attrsets.mapAttrsToList"></a>

Call a function for each attribute in the given set and return
the result in a list.

# Inputs

`f`

Definition: A function, given an attribute's name and value, returns a new value.

`attrs`

Definition: Attribute set to map over.

# Type

```
mapAttrsToList :: (String -> a -> b) -> { [String] :: a } -> [b]
```

# Examples
**Example**

## `lib.attrsets.mapAttrsToList` usage example

```nix
mapAttrsToList (name: value: name + value)
   { x = "a"; y = "b"; }
=> [ "xa" "yb" ]
```


**End example.**



[Declaration](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/attrsets.nix#L1492)


## `lib.attrsets.optionalAttrs`

<a id="function-library-lib.attrsets.optionalAttrs"></a>

If `cond` is true, return the attribute set `as`,
otherwise an empty attribute set.

# Inputs

`cond`

Definition: Condition under which the `as` attribute set is returned.

`as`

Definition: The attribute set to return if `cond` is `true`.

# Type

```
optionalAttrs :: Bool -> AttrSet -> AttrSet
```

# Examples
**Example**

## `lib.attrsets.optionalAttrs` usage example

```nix
optionalAttrs (true) { my = "set"; }
=> { my = "set"; }
optionalAttrs (false) { my = "set"; }
=> { }
```


**End example.**



[Declaration](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/attrsets.nix#L1778)


## `lib.attrsets.recursiveUpdate`

<a id="function-library-lib.attrsets.recursiveUpdate"></a>

A recursive variant of the update operator `//`.  The recursion
stops when one of the attribute values is not an attribute set,
in which case the right hand side value takes precedence over the
left hand side value.

# Inputs

`lhs`

Definition: Left attribute set of the merge.

`rhs`

Definition: Right attribute set of the merge.

# Type

```
recursiveUpdate :: AttrSet -> AttrSet -> AttrSet
```

# Examples
**Example**

## `lib.attrsets.recursiveUpdate` usage example

```nix
recursiveUpdate {
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/hda";
} {
  boot.loader.grub.device = "";
}

returns: {
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "";
}
```


**End example.**



[Declaration](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/lists.nix#L839)


## `lib.lists.optionals`

<a id="function-library-lib.lists.optionals"></a>

Returns a list or an empty list, depending on a boolean value.

# Inputs

`cond`

Definition: Condition

`elems`

Definition: List to return if condition is true

# Type

```
optionals :: Bool -> [a] -> [a]
```

# Examples
**Example**

## `lib.lists.optionals` usage example

```nix
optionals true [ 2 3 ]
=> [ 2 3 ]
optionals false [ 2 3 ]
=> [ ]
```


**End example.**



[Declaration](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/lists.nix#L1985)


## `lib.lists.unique`

<a id="function-library-lib.lists.unique"></a>

Remove duplicate elements from the `list`. O(n^2) complexity.

**Note**

If the list only contains strings and order is not important, the complexity can be reduced to O(n log n) by using [`lib.lists.uniqueStrings`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/lists.nix) (source section: lib.lists.uniqueStrings) instead.

**End note.**


# Inputs

`list`

Definition: Input list

# Type

```
unique :: [a] -> [a]
```

# Examples
**Example**

## `lib.lists.unique` usage example

```nix
unique [ 3 2 3 4 ]
=> [ 3 2 4 ]
```


**End example.**



[Declaration](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/strings.nix#L1219)


## `lib.strings.escapeShellArg`

<a id="function-library-lib.strings.escapeShellArg"></a>

Quote `string` to be used safely within the Bourne shell if it has any
special characters. Prior to escaping, if `string` is a path literal, copy
it into the store; otherwise, coerce `string` to a string via `toString` if
it is not one.

# Inputs

`string`
Definition: 1\. Function argument

# Type

```
escapeShellArg :: a -> String
```

# Examples
**Example**

## `lib.strings.escapeShellArg` usage example

```nix
escapeShellArg "esc'ape\nme"
=> "'esc'\\''ape\nme'"
```


**End example.**



[Declaration](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/strings.nix#L260)


## `lib.strings.concatMapStringsSep`

<a id="function-library-lib.strings.concatMapStringsSep"></a>

Maps a function over a list of strings and then concatenates the
result with the specified separator interspersed between
elements.

# Inputs

`sep`
Definition: Separator to add between elements

`f`
Definition: Function to map over the list

`list`
Definition: List of input strings

# Type

```
concatMapStringsSep :: String -> (a -> String) -> [a] -> String
```

# Examples
**Example**

## `lib.strings.concatMapStringsSep` usage example

```nix
concatMapStringsSep "-" (x: toUpper x)  ["foo" "bar" "baz"]
=> "FOO-BAR-BAZ"
```


**End example.**



[Declaration](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/customisation.nix#L267)


## `lib.customisation.callPackageWith`

<a id="function-library-lib.customisation.callPackageWith"></a>

Call the package function in the file `fn` with the required
arguments automatically.  The function is called with the
arguments `args`, but any missing arguments are obtained from
`autoArgs`.  This function is intended to be partially
parameterised, e.g.,

  ```nix
  callPackage = callPackageWith pkgs;
  pkgs = {
    libfoo = callPackage ./foo.nix { };
    libbar = callPackage ./bar.nix { };
  };
  ```

If the `libbar` function expects an argument named `libfoo`, it is
automatically passed as an argument.  Overrides or missing
arguments can be supplied in `args`, e.g.

  ```nix
  libbar = callPackage ./bar.nix {
    libfoo = null;
    enableX11 = true;
  };
  ```



# Inputs

`autoArgs`

Definition: 1\. Function argument

`fn`

Definition: 2\. Function argument

`args`

Definition: 3\. Function argument

# Type

```
callPackageWith :: AttrSet -> ((AttrSet -> a) | Path) -> AttrSet -> a
```


[Declaration](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/fixed-points.nix#L340)


## `lib.fixedPoints.composeExtensions`

<a id="function-library-lib.fixedPoints.composeExtensions"></a>

Compose two overlay functions and return a single overlay function that combines them.
For more details see: [`composeManyExtensions`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/fixed-points.nix) (source section: lib.fixedPoints.composeManyExtensions).


[Declaration](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/fileset/default.nix#L418)


## `lib.fileset.toSource`

<a id="function-library-lib.fileset.toSource"></a>

Add the local files contained in `fileset` to the store as a single [store path](https://nixos.org/manual/nix/stable/glossary#gloss-store-path) rooted at `root`.

The result is the store path as a string-like value, making it usable e.g. as the `src` of a derivation, or in string interpolation:
```nix
stdenv.mkDerivation {
  src = lib.fileset.toSource { ... };
  # ...
}
```

The name of the store path is always `source`.

# Inputs

Takes an attribute set with the following attributes

`root` (Path; _required_)

Definition: The local directory [path](https://nixos.org/manual/nix/stable/language/values.html#type-path) that will correspond to the root of the resulting store path.
  Paths in [strings](https://nixos.org/manual/nix/stable/language/values.html#type-string), including Nix store paths, cannot be passed as `root`.
  `root` has to be a directory.

**Note**

  Changing `root` only affects the directory structure of the resulting store path, it does not change which files are added to the store.
  The only way to change which files get added to the store is by changing the `fileset` attribute.

**End note.**


`fileset` (FileSet; _required_)

Definition: The file set whose files to import into the store.
  File sets can be created using other functions in this library.
  This argument can also be a path,
  which gets [implicitly coerced to a file set](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/fileset/default.nix) (source section: Implicit coercion from paths to file sets).

**Note**

  If a directory does not recursively contain any file, it is omitted from the store path contents.

**End note.**


# Type

```
toSource :: {
  root :: Path,
  fileset :: FileSet,
} -> SourceLike
```

# Examples
**Example**

## `lib.fileset.toSource` usage example

```nix
# Import the current directory into the store
# but only include files under ./src
toSource {
  root = ./.;
  fileset = ./src;
}
=> "/nix/store/...-source"

# Import the current directory into the store
# but only include ./Makefile and all files under ./src
toSource {
  root = ./.;
  fileset = union
    ./Makefile
    ./src;
}
=> "/nix/store/...-source"

# Trying to include a file outside the root will fail
toSource {
  root = ./.;
  fileset = unions [
    ./Makefile
    ./src
    ../LICENSE
  ];
}
=> <error>

# The root needs to point to a directory that contains all the files
toSource {
  root = ../.;
  fileset = unions [
    ./Makefile
    ./src
    ../LICENSE
  ];
}
=> "/nix/store/...-source"

# The root has to be a local filesystem path
toSource {
  root = "/nix/store/...-source";
  fileset = ./.;
}
=> <error>
```


**End example.**
